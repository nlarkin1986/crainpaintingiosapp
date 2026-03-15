import CryptoKit
import Foundation
import UIKit

enum VisualizationJobItemState: Hashable, Sendable {
    case queued
    case generating
    case completed(VisualizationResult)
    case failed(String)
}

extension VisualizationJobItemState {
    var isQueued: Bool {
        if case .queued = self {
            return true
        }
        return false
    }

    var isGenerating: Bool {
        if case .generating = self {
            return true
        }
        return false
    }

    var isCompleted: Bool {
        if case .completed = self {
            return true
        }
        return false
    }

    var isFailed: Bool {
        if case .failed = self {
            return true
        }
        return false
    }

    var isProcessing: Bool {
        isQueued || isGenerating
    }

    var isTerminal: Bool {
        isCompleted || isFailed
    }
}

struct VisualizationJobItem: Identifiable, Hashable, Sendable {
    let id: String
    let color: PaintColor
    var state: VisualizationJobItemState

    init(color: PaintColor, state: VisualizationJobItemState = .queued) {
        self.id = color.id
        self.color = color
        self.state = state
    }
}

struct VisualizationJob: Identifiable, Hashable, Sendable {
    let id: String
    let createdAt: Date
    let surfaceDescription: String
    let roomName: String
    var items: [VisualizationJobItem]
    var notice: String?

    init(
        id: String = "job-\(UUID().uuidString)",
        createdAt: Date = .now,
        surfaceDescription: String,
        roomName: String,
        items: [VisualizationJobItem],
        notice: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.surfaceDescription = surfaceDescription
        self.roomName = roomName
        self.items = items
        self.notice = notice
    }
}

struct VisualizationResult: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var projectID: String?
    let remoteVisualizationID: String?
    let color: PaintColor
    let surface: String
    let roomName: String
    let originalRemoteURL: String
    let resultRemoteURL: String
    let originalFullRemoteURL: String?
    let resultFullRemoteURL: String?
    let shareID: String
    let originalImagePath: String
    let resultImagePath: String
    let originalFullImagePath: String?
    let resultFullImagePath: String?
    let createdAt: Date
    let requestFingerprint: String?

    init(
        id: String,
        projectID: String? = nil,
        remoteVisualizationID: String?,
        color: PaintColor,
        surface: String,
        roomName: String,
        originalRemoteURL: String,
        resultRemoteURL: String,
        originalFullRemoteURL: String?,
        resultFullRemoteURL: String?,
        shareID: String,
        originalImagePath: String,
        resultImagePath: String,
        originalFullImagePath: String?,
        resultFullImagePath: String?,
        createdAt: Date,
        requestFingerprint: String? = nil
    ) {
        self.id = id
        self.projectID = projectID
        self.remoteVisualizationID = remoteVisualizationID
        self.color = color
        self.surface = surface
        self.roomName = roomName
        self.originalRemoteURL = originalRemoteURL
        self.resultRemoteURL = resultRemoteURL
        self.originalFullRemoteURL = originalFullRemoteURL
        self.resultFullRemoteURL = resultFullRemoteURL
        self.shareID = shareID
        self.originalImagePath = originalImagePath
        self.resultImagePath = resultImagePath
        self.originalFullImagePath = originalFullImagePath
        self.resultFullImagePath = resultFullImagePath
        self.createdAt = createdAt
        self.requestFingerprint = requestFingerprint
    }

    var visualization: Visualization {
        Visualization(
            id: id,
            projectID: projectID,
            remoteVisualizationID: remoteVisualizationID,
            colorName: color.name,
            colorHex: color.hex,
            colorCode: color.number,
            roomName: roomName,
            beforeImageName: nil,
            afterImageName: nil,
            beforeImagePath: originalImagePath,
            afterImagePath: resultImagePath,
            beforeFullImagePath: originalFullImagePath,
            afterFullImagePath: resultFullImagePath,
            originalURL: originalRemoteURL,
            resultURL: resultRemoteURL,
            shareID: shareID,
            surface: surface,
            brand: color.brand,
            createdAt: createdAt
        )
    }

    var hasRequiredLocalAssets: Bool {
        FileManager.default.fileExists(atPath: originalImagePath)
            && FileManager.default.fileExists(atPath: resultImagePath)
    }

    func withRequestFingerprint(_ requestFingerprint: String?) -> VisualizationResult {
        VisualizationResult(
            id: id,
            projectID: projectID,
            remoteVisualizationID: remoteVisualizationID,
            color: color,
            surface: surface,
            roomName: roomName,
            originalRemoteURL: originalRemoteURL,
            resultRemoteURL: resultRemoteURL,
            originalFullRemoteURL: originalFullRemoteURL,
            resultFullRemoteURL: resultFullRemoteURL,
            shareID: shareID,
            originalImagePath: originalImagePath,
            resultImagePath: resultImagePath,
            originalFullImagePath: originalFullImagePath,
            resultFullImagePath: resultFullImagePath,
            createdAt: createdAt,
            requestFingerprint: requestFingerprint
        )
    }

    func withProjectID(_ projectID: String?) -> VisualizationResult {
        VisualizationResult(
            id: id,
            projectID: projectID,
            remoteVisualizationID: remoteVisualizationID,
            color: color,
            surface: surface,
            roomName: roomName,
            originalRemoteURL: originalRemoteURL,
            resultRemoteURL: resultRemoteURL,
            originalFullRemoteURL: originalFullRemoteURL,
            resultFullRemoteURL: resultFullRemoteURL,
            shareID: shareID,
            originalImagePath: originalImagePath,
            resultImagePath: resultImagePath,
            originalFullImagePath: originalFullImagePath,
            resultFullImagePath: resultFullImagePath,
            createdAt: createdAt,
            requestFingerprint: requestFingerprint
        )
    }
}

enum VisualizationRequestFingerprint {
    static let cacheVersion = "ios-active-project-cache-v1"
    private static let normalizedPhotoDimension: CGFloat = 512
    private static let maxCustomInstructionLength = 80

    static func photoFingerprint(for image: UIImage) -> String? {
        let normalizedImage = normalizePhoto(image)
        guard let data = normalizedImage.pngData() else { return nil }
        return sha256Hex(for: data)
    }

    static func make(
        photoFingerprint: String,
        color: PaintColor,
        surface: SurfaceType,
        customSurfaceText: String
    ) -> String {
        let payload = [
            cacheVersion,
            photoFingerprint,
            color.id,
            surface.apiSurfaceValue(customSurfaceText: customSurfaceText),
            normalizedCustomInstruction(
                surface.apiCustomInstruction(customSurfaceText: customSurfaceText)
            ),
        ].joined(separator: "|")

        return sha256Hex(for: Data(payload.utf8))
    }

    static func normalizedCustomInstruction(_ customInstruction: String?) -> String {
        guard let customInstruction else { return "" }

        let sanitized = customInstruction
            .replacingOccurrences(of: #"[<>`{}\[\]]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"[\r\n\t]+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !sanitized.isEmpty else { return "" }
        return String(sanitized.prefix(maxCustomInstructionLength))
    }

    private static func normalizePhoto(_ image: UIImage) -> UIImage {
        let size = image.size
        let largestSide = max(size.width, size.height)
        let scale = min(normalizedPhotoDimension / max(largestSide, 1), 1)
        let normalizedSize = CGSize(
            width: max(1, floor(size.width * scale)),
            height: max(1, floor(size.height * scale))
        )
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: normalizedSize, format: format)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: normalizedSize))
            image.draw(in: CGRect(origin: .zero, size: normalizedSize))
        }
    }

    private static func sha256Hex(for data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
