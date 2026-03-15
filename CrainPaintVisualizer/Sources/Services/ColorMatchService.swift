import Foundation
import UIKit

enum ColorMatchQuality: String, Decodable, Sendable {
    case good
    case mixed
    case poor
}

enum ColorMatchMethod: String, Decodable, Sendable {
    case ocrExact = "ocr_exact"
    case geminiShortlist = "gemini_shortlist"
    case deterministicCV = "deterministic_cv"
    case deterministicFallback = "deterministic_fallback"
    case learnedAwbDeterministic = "learned_awb_deterministic"
    case learnedAwbVlmRerank = "learned_awb_vlm_rerank"
}

struct ColorMatchFocusRect: Codable, Equatable, Sendable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

struct ColorMatchCaptureContext: Codable, Equatable, Sendable {
    let flashUsed: Bool?
    let exposureBias: Double?
    let whiteBalanceMode: String?
    let whiteBalanceTemperature: Double?
    let whiteBalanceTint: Double?
    let whiteBalanceRedGain: Double?
    let whiteBalanceGreenGain: Double?
    let whiteBalanceBlueGain: Double?
    let iso: Double?
    let exposureDurationSeconds: Double?
    let deviceModel: String?
    let capturedAt: Date?
    let latitude: Double?
    let longitude: Double?
    let source: String?

    init(
        flashUsed: Bool? = nil,
        exposureBias: Double? = nil,
        whiteBalanceMode: String? = nil,
        whiteBalanceTemperature: Double? = nil,
        whiteBalanceTint: Double? = nil,
        whiteBalanceRedGain: Double? = nil,
        whiteBalanceGreenGain: Double? = nil,
        whiteBalanceBlueGain: Double? = nil,
        iso: Double? = nil,
        exposureDurationSeconds: Double? = nil,
        deviceModel: String? = nil,
        capturedAt: Date? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        source: String? = nil
    ) {
        self.flashUsed = flashUsed
        self.exposureBias = exposureBias
        self.whiteBalanceMode = whiteBalanceMode
        self.whiteBalanceTemperature = whiteBalanceTemperature
        self.whiteBalanceTint = whiteBalanceTint
        self.whiteBalanceRedGain = whiteBalanceRedGain
        self.whiteBalanceGreenGain = whiteBalanceGreenGain
        self.whiteBalanceBlueGain = whiteBalanceBlueGain
        self.iso = iso
        self.exposureDurationSeconds = exposureDurationSeconds
        self.deviceModel = deviceModel
        self.capturedAt = capturedAt
        self.latitude = latitude
        self.longitude = longitude
        self.source = source
    }
}

struct ColorMatchDiagnostics: Decodable, Equatable, Sendable {
    let coveragePct: Double
    let glarePct: Double
    let variance: Double
    let ocrTextFound: Bool
    let preCorrectionHex: String?
    let postCorrectionHex: String?
    let awbModel: String?
    let deltaETop1: Double?
    let deltaEGapTop2: Double?

    static let empty = ColorMatchDiagnostics(
        coveragePct: 0,
        glarePct: 0,
        variance: 0,
        ocrTextFound: false,
        preCorrectionHex: nil,
        postCorrectionHex: nil,
        awbModel: nil,
        deltaETop1: nil,
        deltaEGapTop2: nil
    )
}

struct ColorMatchResponseData: Sendable {
    let sampleHex: String
    let quality: ColorMatchQuality
    let warnings: [String]
    let diagnostics: ColorMatchDiagnostics
    let matchMethod: ColorMatchMethod
    let matches: [ColorMatchResult]
}

private struct ColorMatchResponseItem: Decodable {
    let name: String
    let number: String
    let family: String
    let hex: String
    let brand: String
    let confidence: Int
    let rationale: String
}

private struct ColorMatchResponse: Decodable {
    let sampleHex: String
    let quality: ColorMatchQuality
    let warnings: [String]
    let diagnostics: ColorMatchDiagnostics?
    let matchMethod: ColorMatchMethod
    let matches: [ColorMatchResponseItem]
}

enum ColorMatchServiceError: LocalizedError {
    case notConfigured
    case invalidSample
    case missingFocusRect
    case invalidResponse
    case encodingError
    case serverMessage(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Color matching is unavailable until the API base URL is configured."
        case .invalidSample:
            return "We couldn't prepare that sample for matching. Try another photo."
        case .missingFocusRect:
            return "We couldn't align the sample area. Try retaking the photo."
        case .invalidResponse:
            return "The color matching service returned an unexpected response."
        case .encodingError:
            return "We couldn't prepare the sample details for upload."
        case .serverMessage(let message):
            return message
        }
    }
}

protocol ColorMatchService {
    func match(
        image: UIImage,
        focusRect: ColorMatchFocusRect?,
        captureContext: ColorMatchCaptureContext?
    ) async throws -> ColorMatchResponseData
}

struct RemoteColorMatchService: ColorMatchService {
    private let client: APIClient?
    private let photoProcessor: PhotoProcessingService

    init(
        baseURL: URL? = APIEnvironment.baseURL,
        session: URLSession = .shared,
        photoProcessor: PhotoProcessingService = .shared
    ) {
        if let baseURL {
            self.client = APIClient(baseURL: baseURL, session: session)
        } else {
            self.client = nil
        }
        self.photoProcessor = photoProcessor
    }

    func match(
        image: UIImage,
        focusRect: ColorMatchFocusRect?,
        captureContext: ColorMatchCaptureContext?
    ) async throws -> ColorMatchResponseData {
        guard let client else {
            throw ColorMatchServiceError.notConfigured
        }

        guard let focusRect else {
            throw ColorMatchServiceError.missingFocusRect
        }

        let imageData: Data
        do {
            imageData = try await photoProcessor.prepareUploadData(from: image, recipe: .colorMatch)
        } catch {
            throw ColorMatchServiceError.invalidSample
        }

        let payload = APIClient.MultipartPayload(
            path: "/api/color-match",
            fields: try buildMultipartFields(focusRect: focusRect, captureContext: captureContext),
            file: .init(
                fieldName: "image",
                fileName: "color-sample.jpg",
                mimeType: "image/jpeg",
                data: imageData
            )
        )

        do {
            let response: ColorMatchResponse = try await client.postMultipartFormData(payload)
            let mapped = response.matches.compactMap { item -> ColorMatchResult? in
                guard let brand = PaintBrand(rawValue: item.brand) else { return nil }
                let color = PaintColor(number: item.number, name: item.name, family: item.family, hex: item.hex, brand: brand)
                return ColorMatchResult(
                    id: "\(brand.rawValue)-\(item.number)",
                    color: color,
                    confidence: item.confidence,
                    rationale: item.rationale
                )
            }

            guard !mapped.isEmpty else {
                throw ColorMatchServiceError.invalidResponse
            }

            return ColorMatchResponseData(
                sampleHex: response.sampleHex,
                quality: response.quality,
                warnings: response.warnings,
                diagnostics: response.diagnostics ?? .empty,
                matchMethod: response.matchMethod,
                matches: mapped
            )
        } catch APIClientError.httpError(_, let message, _) {
            if let message, !message.isEmpty {
                throw ColorMatchServiceError.serverMessage(message)
            }
            throw ColorMatchServiceError.invalidResponse
        } catch APIClientError.notConfigured {
            throw ColorMatchServiceError.notConfigured
        } catch let error as ColorMatchServiceError {
            throw error
        } catch {
            if let localized = error as? LocalizedError, let description = localized.errorDescription {
                throw ColorMatchServiceError.serverMessage(description)
            }
            throw ColorMatchServiceError.invalidResponse
        }
    }

    private func buildMultipartFields(
        focusRect: ColorMatchFocusRect,
        captureContext: ColorMatchCaptureContext?
    ) throws -> [APIClient.MultipartField] {
        var fields: [APIClient.MultipartField] = [
            .init(name: "focusRect", value: try encodeJSONString(focusRect)),
        ]

        if let captureContext {
            fields.append(.init(name: "captureContext", value: try encodeJSONString(captureContext)))
        }

        return fields
    }

    private func encodeJSONString<T: Encodable>(_ value: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let string = String(data: try encoder.encode(value), encoding: .utf8) else {
            throw ColorMatchServiceError.encodingError
        }
        return string
    }
}
