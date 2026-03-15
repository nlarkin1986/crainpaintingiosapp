import Foundation

enum AppRoute: Hashable {
    case brandSelector
    case itemPicker
    case directionPicker
    case photoUpload
    case surfacePicker
    case projectReview
    case colorMatcher
    case resultsGallery
    case results(projectID: String)
    case visualizationDetail(projectID: String?, visualizationID: String)
    case savedPreviewDetail(visualization: Visualization)
    case masterReport(reportId: String)
    case sampleOutput(reportId: String, chapterId: String?)
    case consultationCheckout(flowState: ConsultationFlowState)
}

extension AppRoute {
    static func visualizationDetail(visualization: Visualization) -> Self {
        .visualizationDetail(projectID: visualization.projectID, visualizationID: visualization.id)
    }

    var showsPersistentTabBar: Bool { false }
}
