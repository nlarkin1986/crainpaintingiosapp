import Foundation

enum APIClientError: LocalizedError {
    case notConfigured
    case invalidResponse
    case httpError(Int)
    case decodingError

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
}
