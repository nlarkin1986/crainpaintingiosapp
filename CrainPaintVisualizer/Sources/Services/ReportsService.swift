import Foundation

private struct ReportStatusResponse: Decodable {
    let orderId: String
    let packageType: String?
    let status: String
    let title: String
    let subtitle: String
    let message: String
    let createdAt: Date
    let updatedAt: Date
    let retryAfterSeconds: Int?
    let report: ReportPayload?
}

private struct ReportPayload: Decodable {
    let reportId: String
    let accessToken: String
    let title: String
    let subtitle: String
    let videoTitle: String?
    let videoDuration: TimeInterval?
    let createdAt: Date
    let reportUrl: String?
    let pdfUrl: String?
    let recommendations: [ReportRecommendationPayload]
}

private struct ReportRecommendationPayload: Decodable {
    let roomName: String
    let rationale: String
    let colorName: String
    let colorNumber: String
    let hex: String
    let originalUrl: String?
    let visualizationUrl: String?
}

protocol ReportsService {
    func fetchReport(orderID: String) async throws -> MasterReport?
}

struct RemoteReportsService: ReportsService {
    private let client: APIClient?

    init(baseURL: URL? = APIEnvironment.baseURL) {
        if let baseURL {
            client = APIClient(baseURL: baseURL)
        } else {
            client = nil
        }
    }

    func fetchReport(orderID: String) async throws -> MasterReport? {
        guard let client else { return nil }
        let response: ReportStatusResponse = try await client.getJSON("/api/consultation/orders/\(orderID)")

        let packageType = response.packageType.flatMap(ConsultationPackageType.init(rawValue:))
        let status: ReportStatus

        switch response.status {
        case "ready", "complete":
            status = .ready
        case "failed":
            status = .failed
        default:
            status = .generating
        }

        if let report = response.report {
            return MasterReport(
                id: orderID,
                orderID: orderID,
                remoteReportID: report.reportId,
                title: report.title,
                curatorName: "Curt Crain",
                curatorSubtitle: report.subtitle,
                videoThumbnailName: "HowItWorksHero",
                videoTitle: report.videoTitle ?? "Curt's Video Walkthrough",
                videoDuration: report.videoDuration ?? 0,
                createdAt: response.createdAt,
                updatedAt: response.updatedAt,
                status: status,
                statusMessage: response.message,
                accessToken: report.accessToken,
                reportURL: report.reportUrl,
                pdfURL: report.pdfUrl,
                packageType: packageType,
                recommendations: report.recommendations.enumerated().map { index, recommendation in
                    RoomRecommendation(
                        id: "\(orderID)-recommendation-\(index)",
                        roomName: recommendation.roomName,
                        beforeTitle: "Before",
                        afterTitle: "After",
                        beforeImageURL: recommendation.originalUrl,
                        afterImageURL: recommendation.visualizationUrl,
                        suggestedColor: PaintColor(
                            number: recommendation.colorNumber,
                            name: recommendation.colorName,
                            family: "Curated",
                            hex: recommendation.hex,
                            brand: recommendation.colorNumber.uppercased().contains("SW") ? .sherwinWilliams : .benjaminMoore
                        ),
                        rationale: recommendation.rationale
                    )
                }
            )
        }

        return MasterReport(
            id: orderID,
            orderID: orderID,
            title: response.title,
            curatorName: "Curt Crain",
            curatorSubtitle: response.subtitle,
            videoTitle: "Curt's Video Walkthrough",
            videoDuration: 0,
            createdAt: response.createdAt,
            updatedAt: response.updatedAt,
            status: status,
            statusMessage: response.message,
            packageType: packageType,
            recommendations: []
        )
    }
}
