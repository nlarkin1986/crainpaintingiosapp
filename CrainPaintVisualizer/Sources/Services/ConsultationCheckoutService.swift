import Foundation

enum ConsultationPackageType: String, CaseIterable, Codable, Hashable, Sendable {
    case quickReview = "quick_review"
    case videoConsultation = "video_consultation"
    case wholeHome = "whole_home"
}

enum ConsultationCheckoutPlatform: String, Codable, Hashable, Sendable {
    case web
    case iosNative = "ios_native"
}

enum ConsultationDisplayPackage: String, Codable, Hashable, Sendable {
    case masterPackage = "master_package"
}

struct ConsultationCheckoutSession: Decodable {
    let orderId: String
    let paymentIntentClientSecret: String
    let publishableKey: String
    let merchantCountryCode: String
    let customerId: String?
    let ephemeralKeySecret: String?
}

private struct ConsultationSessionRequest: Encodable {
    let packageType: String
    let email: String
    let orderId: String
    let platform: String
    let displayPackage: String?
}

protocol ConsultationCheckoutService {
    func createSession(
        packageType: ConsultationPackageType,
        email: String,
        orderId: String,
        platform: ConsultationCheckoutPlatform,
        displayPackage: ConsultationDisplayPackage?
    ) async throws -> ConsultationCheckoutSession
}

extension ConsultationCheckoutService {
    func createSession(
        packageType: ConsultationPackageType,
        email: String,
        orderId: String
    ) async throws -> ConsultationCheckoutSession {
        try await createSession(
            packageType: packageType,
            email: email,
            orderId: orderId,
            platform: .iosNative,
            displayPackage: nil
        )
    }
}

struct RemoteConsultationCheckoutService: ConsultationCheckoutService {
    private let client: APIClient?

    init(baseURL: URL? = APIEnvironment.baseURL) {
        if let baseURL {
            self.client = APIClient(baseURL: baseURL)
        } else {
            self.client = nil
        }
    }

    func createSession(
        packageType: ConsultationPackageType,
        email: String,
        orderId: String,
        platform: ConsultationCheckoutPlatform,
        displayPackage: ConsultationDisplayPackage?
    ) async throws -> ConsultationCheckoutSession {
        guard let client else { throw APIClientError.notConfigured }

        let payload = ConsultationSessionRequest(
            packageType: packageType.rawValue,
            email: email,
            orderId: orderId,
            platform: platform.rawValue,
            displayPackage: displayPackage?.rawValue
        )
        return try await client.postJSON("/api/consultation/create-session", body: payload)
    }
}
