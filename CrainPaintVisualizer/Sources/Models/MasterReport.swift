import Foundation

struct MasterReport: Identifiable, Hashable, Codable {
    let id: String
    var projectID: String? = nil
    var orderID: String? = nil
    var remoteReportID: String? = nil
    let title: String
    let curatorName: String
    let curatorSubtitle: String
    var curatorPhotoName: String? = nil
    var videoThumbnailName: String? = nil
    let videoTitle: String
    let videoDuration: TimeInterval
    let createdAt: Date
    var updatedAt: Date? = nil
    var status: ReportStatus
    var statusMessage: String? = nil
    var accessToken: String? = nil
    var reportURL: String? = nil
    var pdfURL: String? = nil
    var packageType: ConsultationPackageType? = nil
    var recommendations: [RoomRecommendation]
}

enum ReportStatus: String, Hashable, Codable {
    case generating
    case ready
    case failed

    var isReady: Bool { self == .ready }
    var isGenerating: Bool { self == .generating }
}

struct RoomRecommendation: Identifiable, Hashable, Codable {
    let id: String
    let roomName: String
    let beforeTitle: String
    let afterTitle: String
    var beforeImageName: String? = nil
    var afterImageName: String? = nil
    var beforeImageURL: String? = nil
    var afterImageURL: String? = nil
    let suggestedColor: PaintColor
    let rationale: String
}

struct ConsultationPackage: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let price: Decimal
    let headline: String
    let includesRecording: Bool
    let description: String
}
