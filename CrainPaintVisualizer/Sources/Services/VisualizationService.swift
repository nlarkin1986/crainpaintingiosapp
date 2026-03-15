import Foundation
import SwiftUI
import UIKit

private enum VisualizationRemoteStatus: String, Decodable {
    case queued
    case processing
    case completed
    case failed
    case expired
}

private struct VisualizationStartResponse: Decodable {
    let visualizationId: String
    let shareId: String?
    let status: VisualizationRemoteStatus
    let message: String?
    let retryAfterSeconds: Int?
    let createdAt: Date?
}

private struct VisualizationStatusResponse: Decodable {
    let visualizationId: String
    let shareId: String?
    let status: VisualizationRemoteStatus
    let message: String?
    let retryAfterSeconds: Int?
    let error: String?
    let code: String?
    let mimeType: String?
    let originalJobUrl: String?
    let resultJobUrl: String?
    let originalCardUrl: String?
    let resultCardUrl: String?
    let originalFullUrl: String?
    let resultFullUrl: String?
    let createdAt: Date?
    let completedAt: Date?
}

enum VisualizationServiceError: LocalizedError {
    case notConfigured
    case invalidPhoto
    case invalidResponse
    case rateLimited(message: String, retryAfterSeconds: Int?)
    case serverMessage(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Preview generation is unavailable until the API base URL is configured."
        case .invalidPhoto:
            return "We couldn't prepare that photo for upload. Please try another image."
        case .invalidResponse:
            return "The preview service returned an unexpected response."
        case .rateLimited(let message, _):
            return message
        case .serverMessage(let message):
            return message
        }
    }
}

protocol VisualizationService {
    func generatePreview(
        color: PaintColor,
        photo: UIImage,
        surface: SurfaceType,
        customSurfaceText: String,
        roomName: String
    ) async throws -> VisualizationResult
}

struct RemoteVisualizationService: VisualizationService {
    private let client: APIClient?
    private let session: URLSession
    private let assetsDirectory: URL
    private let installationStore: InstallationIdentityStore
    private let photoProcessor: PhotoProcessingService
    private let maxPollAttempts = 45

    init(
        baseURL: URL? = APIEnvironment.baseURL,
        session: URLSession = .shared,
        installationStore: InstallationIdentityStore = InstallationIdentityStore(),
        photoProcessor: PhotoProcessingService = .shared
    ) {
        if let baseURL {
            client = APIClient(baseURL: baseURL, session: session)
        } else {
            client = nil
        }
        self.session = session
        self.installationStore = installationStore
        self.photoProcessor = photoProcessor
        assetsDirectory = AppStorage.fileURL(for: "visualization-assets")
        if !FileManager.default.fileExists(atPath: assetsDirectory.path) {
            try? FileManager.default.createDirectory(at: assetsDirectory, withIntermediateDirectories: true)
        }
    }

    func generatePreview(
        color: PaintColor,
        photo: UIImage,
        surface: SurfaceType,
        customSurfaceText: String,
        roomName: String
    ) async throws -> VisualizationResult {
        guard let client else { throw VisualizationServiceError.notConfigured }
        let photoData: Data
        do {
            photoData = try await photoProcessor.prepareUploadData(from: photo, recipe: .visualization)
        } catch {
            throw VisualizationServiceError.invalidPhoto
        }

        let headers = try requestHeaders()
        let clientRequestID = UUID().uuidString.lowercased()

        let payload = APIClient.MultipartPayload(
            path: "/api/visualize",
            fields: [
                .init(name: "colorName", value: color.name),
                .init(name: "colorHex", value: color.hex),
                .init(name: "colorNumber", value: color.number),
                .init(name: "surface", value: surface.apiSurfaceValue(customSurfaceText: customSurfaceText)),
                .init(name: "brand", value: color.brand.rawValue),
                .init(name: "customInstruction", value: surface.apiCustomInstruction(customSurfaceText: customSurfaceText) ?? ""),
                .init(name: "clientRequestId", value: clientRequestID)
            ],
            file: .init(
                fieldName: "image",
                fileName: "room-preview.jpg",
                mimeType: "image/jpeg",
                data: photoData
            )
        )

        do {
            let startResponse: VisualizationStartResponse = try await client.postMultipartFormData(
                payload,
                headers: headers
            )
            let finalStatus = try await pollUntilFinished(
                visualizationID: startResponse.visualizationId,
                initialStatus: startResponse.status,
                headers: headers
            )

            return try await makeResult(
                from: finalStatus,
                color: color,
                surface: surface.userFacingDescription(customSurfaceText: customSurfaceText),
                roomName: roomName
            )
        } catch APIClientError.httpError(let status, let message, let retryAfterSeconds) {
            if status == 429 {
                throw VisualizationServiceError.rateLimited(
                    message: message ?? "You've reached the preview limit for now. Please try again shortly.",
                    retryAfterSeconds: retryAfterSeconds
                )
            }
            if let message, !message.isEmpty {
                throw VisualizationServiceError.serverMessage(message)
            }
            throw VisualizationServiceError.invalidResponse
        } catch APIClientError.notConfigured {
            throw VisualizationServiceError.notConfigured
        } catch let error as InstallationIdentityError {
            throw VisualizationServiceError.serverMessage(
                error.errorDescription ?? "We couldn't access the device identity used for previews."
            )
        } catch let error as VisualizationServiceError {
            throw error
        } catch {
            if let localized = error as? LocalizedError, let description = localized.errorDescription {
                throw VisualizationServiceError.serverMessage(description)
            }
            throw VisualizationServiceError.invalidResponse
        }
    }

    private func requestHeaders() throws -> APIClient.Headers {
        [
            "X-Installation-ID": try installationStore.installationID(),
            "X-App-Version": AppRuntimeInfo.versionHeader
        ]
    }

    private func pollUntilFinished(
        visualizationID: String,
        initialStatus: VisualizationRemoteStatus,
        headers: APIClient.Headers
    ) async throws -> VisualizationStatusResponse {
        if initialStatus == .failed {
            throw VisualizationServiceError.serverMessage("We couldn't generate this preview. Please try again.")
        }

        for attempt in 0..<maxPollAttempts {
            let status: VisualizationStatusResponse = try await client!.getJSON(
                "/api/visualizations/\(visualizationID)",
                headers: headers
            )

            switch status.status {
            case .completed:
                return status
            case .failed:
                throw VisualizationServiceError.serverMessage(
                    status.error ?? "We couldn't generate this preview. Please try again."
                )
            case .expired:
                throw VisualizationServiceError.serverMessage(
                    "This preview expired before it finished downloading."
                )
            case .queued, .processing:
                let delaySeconds = max(1, status.retryAfterSeconds ?? 2)
                if attempt == maxPollAttempts - 1 { break }
                try await Task.sleep(for: .seconds(delaySeconds))
            }
        }

        throw VisualizationServiceError.serverMessage(
            "Preview generation is taking longer than expected. Please try again."
        )
    }

    private func makeResult(
        from response: VisualizationStatusResponse,
        color: PaintColor,
        surface: String,
        roomName: String
    ) async throws -> VisualizationResult {
        guard
            let originalCardURL = response.originalCardUrl,
            let resultCardURL = response.resultCardUrl
        else {
            throw VisualizationServiceError.invalidResponse
        }

        let id = response.visualizationId

        async let originalCardPath = downloadImage(
            from: originalCardURL,
            preferredName: "\(id)-before-card.jpg"
        )
        async let resultCardPath = downloadImage(
            from: resultCardURL,
            preferredName: "\(id)-after-card.jpg"
        )

        let resolvedOriginalCardPath = try await originalCardPath
        let resolvedResultCardPath = try await resultCardPath

        async let originalFullPath = downloadOptionalImage(
            from: response.originalFullUrl,
            preferredName: "\(id)-before-full.jpg"
        )
        async let resultFullPath = downloadOptionalImage(
            from: response.resultFullUrl,
            preferredName: "\(id)-after-full.jpg"
        )

        let resolvedOriginalFullPath = try? await originalFullPath
        let resolvedResultFullPath = try? await resultFullPath

        return VisualizationResult(
            id: id,
            remoteVisualizationID: response.visualizationId,
            color: color,
            surface: surface,
            roomName: roomName,
            originalRemoteURL: originalCardURL,
            resultRemoteURL: resultCardURL,
            originalFullRemoteURL: response.originalFullUrl,
            resultFullRemoteURL: response.resultFullUrl,
            shareID: response.shareId ?? response.visualizationId,
            originalImagePath: resolvedOriginalCardPath,
            resultImagePath: resolvedResultCardPath,
            originalFullImagePath: resolvedOriginalFullPath,
            resultFullImagePath: resolvedResultFullPath,
            createdAt: response.createdAt ?? response.completedAt ?? .now
        )
    }

    private func downloadOptionalImage(from urlString: String?, preferredName: String) async throws -> String? {
        guard let urlString else { return nil }
        return try await downloadImage(from: urlString, preferredName: preferredName)
    }

    private func downloadImage(from urlString: String, preferredName: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw VisualizationServiceError.invalidResponse
        }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw VisualizationServiceError.invalidResponse
        }

        let fileURL = assetsDirectory.appendingPathComponent(preferredName)
        try data.write(to: fileURL, options: .atomic)
        return fileURL.path
    }
}

struct MockVisualizationService: VisualizationService {
    private let generationDelay: Duration
    private let generationDelayByColorID: [String: Duration]
    private let failingColorIDs: Set<String>

    init(
        generationDelay: Duration = .milliseconds(450),
        generationDelayByColorID: [String: Duration] = [:],
        failingColorIDs: Set<String> = []
    ) {
        self.generationDelay = generationDelay
        self.generationDelayByColorID = generationDelayByColorID
        self.failingColorIDs = failingColorIDs
    }

    func generatePreview(
        color: PaintColor,
        photo: UIImage,
        surface: SurfaceType,
        customSurfaceText: String,
        roomName: String
    ) async throws -> VisualizationResult {
        try await Task.sleep(for: generationDelayByColorID[color.id] ?? generationDelay)

        if failingColorIDs.contains(color.id) {
            throw VisualizationServiceError.serverMessage(
                "We couldn't generate that preview. Please try again."
            )
        }

        let id = "mock-\(UUID().uuidString.prefix(8))-\(color.id)"
        let originalPath = try saveImage(photo, named: "\(id)-before-card.jpg")
        let resultPath = try saveImage(tintedPreviewImage(from: photo, hex: color.hex), named: "\(id)-after-card.jpg")

        return VisualizationResult(
            id: id,
            remoteVisualizationID: id,
            color: color,
            surface: surface.userFacingDescription(customSurfaceText: customSurfaceText),
            roomName: roomName,
            originalRemoteURL: "local://\(id)-before-card",
            resultRemoteURL: "local://\(id)-after-card",
            originalFullRemoteURL: nil,
            resultFullRemoteURL: nil,
            shareID: id,
            originalImagePath: originalPath,
            resultImagePath: resultPath,
            originalFullImagePath: nil,
            resultFullImagePath: nil,
            createdAt: .now
        )
    }

    private func saveImage(_ image: UIImage, named fileName: String) throws -> String {
        let directory = AppStorage.fileURL(for: "visualization-assets")
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        let fileURL = directory.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw VisualizationServiceError.invalidPhoto
        }
        try data.write(to: fileURL, options: .atomic)
        return fileURL.path
    }

    private func tintedPreviewImage(from image: UIImage, hex: String) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        let overlayColor = UIColor(Color(hex: hex))

        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: image.size)
            image.draw(in: rect)
            context.cgContext.setBlendMode(.sourceAtop)
            context.cgContext.setFillColor(overlayColor.withAlphaComponent(0.28).cgColor)
            context.cgContext.fill(rect)
        }
    }
}
