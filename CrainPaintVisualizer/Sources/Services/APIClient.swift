import Foundation
import Security
import UIKit

enum APIClientError: LocalizedError {
    case notConfigured
    case invalidResponse
    case httpError(Int)
    case decodingError
    case imageEncodingFailed
    case freeLimitExceeded(VisualizationUsage)
    case offline

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "API base URL is not configured. Set UserDefaults key 'apiBaseURL' or environment variable CRAIN_API_BASE_URL."
        case .invalidResponse:
            return "Received an invalid response from server."
        case .httpError(let status):
            return "Server returned HTTP \(status)."
        case .decodingError:
            return "Unable to decode server response."
        case .imageEncodingFailed:
            return "Unable to prepare this photo. Try a different image."
        case .freeLimitExceeded:
            return "You have used your free AI paint visualizations."
        case .offline:
            return "You appear to be offline. Reconnect and try again."
        }
    }
}

struct VisualizationUsage: Codable, Hashable, Sendable {
    let completedCount: Int
    let freeLimit: Int
    let remainingFree: Int
    let hasEntitlement: Bool

    static let initial = VisualizationUsage(completedCount: 0, freeLimit: 5, remainingFree: 5, hasEntitlement: false)
}

struct VisualizeResponse: Codable, Sendable {
    let originalUrl: URL
    let resultUrl: URL
    let shareId: String
    let usage: VisualizationUsage?
}

struct StoreKitVerifyRequest: Codable, Sendable {
    let deviceId: String
    let signedTransactionJWS: String
}

struct StoreKitVerifyResponse: Codable, Sendable {
    let ok: Bool
    let usage: VisualizationUsage?
}

enum APIEnvironment {
    static var baseURL: URL? {
        if let value = UserDefaults.standard.string(forKey: "apiBaseURL"),
           let url = URL(string: value),
           !value.isEmpty {
            return url
        }

        if let value = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           let url = URL(string: value),
           !value.isEmpty {
            return url
        }

        if let value = ProcessInfo.processInfo.environment["CRAIN_API_BASE_URL"],
           let url = URL(string: value),
           !value.isEmpty {
            return url
        }

        return nil
    }
}

struct APIClient {
    let baseURL: URL
    let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func postJSON<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw APIClientError.httpError(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw APIClientError.decodingError
        }
    }

    func visualize(
        image: UIImage,
        color: PaintColor,
        surface: String,
        customInstruction: String?,
        deviceId: String,
        signedTransactionJWS: String?
    ) async throws -> VisualizeResponse {
        guard let jpegData = image.jpegData(compressionQuality: 0.82) else {
            throw APIClientError.imageEncodingFailed
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: baseURL.appending(path: "/api/visualize"))
        request.httpMethod = "POST"
        request.timeoutInterval = 70
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func appendField(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }

        appendField("colorName", color.name)
        appendField("colorHex", color.hex)
        appendField("colorNumber", color.number)
        appendField("surface", surface)
        appendField("brand", color.brand.rawValue)
        appendField("deviceId", deviceId)

        if let customInstruction, !customInstruction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            appendField("customInstruction", customInstruction)
        }

        if let signedTransactionJWS {
            appendField("signedTransactionJWS", signedTransactionJWS)
        }

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"room.jpg\"\r\n")
        body.append("Content-Type: image/jpeg\r\n\r\n")
        body.append(jpegData)
        body.append("\r\n--\(boundary)--\r\n")
        request.httpBody = body

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw APIClientError.invalidResponse
            }

            if http.statusCode == 402,
               let limitResponse = try? JSONDecoder().decode(FreeLimitResponse.self, from: data),
               let usage = limitResponse.usage {
                throw APIClientError.freeLimitExceeded(usage)
            }

            guard (200...299).contains(http.statusCode) else {
                throw APIClientError.httpError(http.statusCode)
            }

            do {
                return try JSONDecoder().decode(VisualizeResponse.self, from: data)
            } catch {
                throw APIClientError.decodingError
            }
        } catch let error as URLError where error.code == .notConnectedToInternet || error.code == .networkConnectionLost {
            throw APIClientError.offline
        }
    }

    func verifyStoreKitEntitlement(deviceId: String, signedTransactionJWS: String) async throws -> StoreKitVerifyResponse {
        try await postJSON(
            "/api/storekit/verify",
            body: StoreKitVerifyRequest(deviceId: deviceId, signedTransactionJWS: signedTransactionJWS)
        )
    }
}

private struct FreeLimitResponse: Codable {
    let code: String?
    let usage: VisualizationUsage?
}

private extension Data {
    mutating func append(_ string: String) {
        append(Data(string.utf8))
    }
}

enum DeviceIdentifier {
    private static let account = "crain-paint-visualizer-device-id"

    static func current() -> String {
        if let existing = readKeychainValue() {
            return existing
        }

        let newValue = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        saveKeychainValue(newValue)
        return newValue
    }

    private static func readKeychainValue() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private static func saveKeychainValue(_ value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }
}
