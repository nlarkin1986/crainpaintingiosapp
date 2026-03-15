import Foundation

enum APIClientError: LocalizedError {
    case notConfigured
    case invalidResponse
    case httpError(Int, message: String?, retryAfterSeconds: Int?)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "API base URL is not configured. Set UserDefaults key 'apiBaseURL' or environment variable CRAIN_API_BASE_URL."
        case .invalidResponse:
            return "Received an invalid response from server."
        case .httpError(let status, let message, _):
            return message ?? "Server returned HTTP \(status)."
        case .decodingError:
            return "Unable to decode server response."
        }
    }
}

enum APIEnvironment {
    static var baseURL: URL? {
        if let value = UserDefaults.standard.string(forKey: "apiBaseURL"),
           let url = URL(string: value),
           !value.isEmpty {
            return url
        }

        if let value = ProcessInfo.processInfo.environment["CRAIN_API_BASE_URL"],
           let url = URL(string: value),
           !value.isEmpty {
            return url
        }

        if let value = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
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

    typealias Headers = [String: String]

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func postJSON<Body: Encodable, Response: Decodable>(
        _ path: String,
        body: Body,
        headers: Headers = [:]
    ) async throws -> Response {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        apply(headers: headers, to: &request)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)
        return try await send(request)
    }

    func getJSON<Response: Decodable>(_ path: String, headers: Headers = [:]) async throws -> Response {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "GET"
        apply(headers: headers, to: &request)
        return try await send(request)
    }

    struct MultipartField {
        let name: String
        let value: String
    }

    struct MultipartFile {
        let fieldName: String
        let fileName: String
        let mimeType: String
        let data: Data
    }

    struct MultipartPayload {
        let path: String
        let fields: [MultipartField]
        let file: MultipartFile
    }

    func postMultipartFormData<Response: Decodable>(
        _ payload: MultipartPayload,
        headers: Headers = [:]
    ) async throws -> Response {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: baseURL.appending(path: payload.path))
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        apply(headers: headers, to: &request)
        request.httpBody = buildMultipartBody(boundary: boundary, fields: payload.fields, file: payload.file)
        return try await send(request)
    }

    private func apply(headers: Headers, to request: inout URLRequest) {
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }

    private func send<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw APIClientError.httpError(
                http.statusCode,
                message: parseErrorMessage(from: data),
                retryAfterSeconds: Int(http.value(forHTTPHeaderField: "Retry-After") ?? "")
            )
        }

        do {
            let decoder = JSONDecoder.apiResponseDecoder()
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIClientError.decodingError
        }
    }

    private func buildMultipartBody(boundary: String, fields: [MultipartField], file: MultipartFile) -> Data {
        var body = Data()
        let lineBreak = "\r\n"

        for field in fields where !field.value.isEmpty {
            body.append("--\(boundary)\(lineBreak)")
            body.append("Content-Disposition: form-data; name=\"\(field.name)\"\(lineBreak)\(lineBreak)")
            body.append("\(field.value)\(lineBreak)")
        }

        body.append("--\(boundary)\(lineBreak)")
        body.append("Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.fileName)\"\(lineBreak)")
        body.append("Content-Type: \(file.mimeType)\(lineBreak)\(lineBreak)")
        body.append(file.data)
        body.append(lineBreak)
        body.append("--\(boundary)--\(lineBreak)")

        return body
    }

    private func parseErrorMessage(from data: Data) -> String? {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let message = json["error"] as? String
        else {
            return nil
        }
        return message
    }
}

private extension JSONDecoder {
    static func apiResponseDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            if let date = APIDateDecoding.fractionalSecondsFormatter.date(from: value) {
                return date
            }

            if let date = APIDateDecoding.standardFormatter.date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported ISO-8601 date: \(value)"
            )
        }
        return decoder
    }
}

private enum APIDateDecoding {
    static let fractionalSecondsFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let standardFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
