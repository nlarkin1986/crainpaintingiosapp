import Foundation

struct ReportSummary: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let createdAt: Date
    let status: ReportStatus
}

struct ReportDetail: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let summary: ReportSummary
    let videoTitle: String?
    let recommendations: [RoomRecommendation]
}

struct ConsultationFlowState: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var sourceProjectID: String?
    var sourceVisualizationID: String?
    var sourceColor: PaintColor?
    var sourceRoomName: String?
    var packageType: ConsultationPackageType
    var createdAt: Date

    init(
        id: String = "consult-\(UUID().uuidString.prefix(8))",
        sourceProjectID: String? = nil,
        sourceVisualizationID: String? = nil,
        sourceColor: PaintColor? = nil,
        sourceRoomName: String? = nil,
        packageType: ConsultationPackageType = .videoConsultation,
        createdAt: Date = .now
    ) {
        self.id = id
        self.sourceProjectID = sourceProjectID
        self.sourceVisualizationID = sourceVisualizationID
        self.sourceColor = sourceColor
        self.sourceRoomName = sourceRoomName
        self.packageType = packageType
        self.createdAt = createdAt
    }
}
