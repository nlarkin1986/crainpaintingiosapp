import SwiftUI

extension View {
    func withAppRouter() -> some View {
        navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .brandSelector:
                BrandSelectorView()
            case .itemPicker:
                ItemPickerView()
            case .directionPicker:
                DirectionPickerView()
            case .photoUpload:
                PhotoUploadView()
            case .surfacePicker:
                SurfacePickerView()
            case .projectReview:
                ProjectReviewView()
            case .colorMatcher:
                ColorMatcherView()
            case .resultsGallery:
                ResultsGalleryView()
            case .results(let projectID):
                ProjectResultsRouteView(projectID: projectID)
            case .visualizationDetail(let projectID, let visualizationID):
                VisualizationDetailRouteView(projectID: projectID, visualizationID: visualizationID)
            case .savedPreviewDetail(let visualization):
                SavedPreviewDetailView(visualization: visualization)
            case .masterReport(let reportId):
                MasterReportView(reportId: reportId)
            case .sampleOutput(let reportId, let chapterId):
                SampleOutputView(reportId: reportId, chapterId: chapterId)
            case .consultationCheckout(let flowState):
                ConsultationCheckoutView(flowState: flowState)
            }
        }
    }
}

private struct ProjectResultsRouteView: View {
    @Environment(VisualizerViewModel.self) private var visualizerVM

    let projectID: String

    var body: some View {
        ResultsGalleryView()
            .task(id: projectID) {
                await visualizerVM.activateProject(projectID)
            }
    }
}

private struct VisualizationDetailRouteView: View {
    @Environment(Theme.self) private var theme
    @Environment(VisualizerViewModel.self) private var visualizerVM

    let projectID: String?
    let visualizationID: String

    var body: some View {
        if let visualization = visualizerVM.visualization(id: visualizationID, projectID: projectID) {
            VisualizationDetailView(visualization: visualization)
        } else {
            ContentUnavailableView(
                "Preview Unavailable",
                systemImage: "photo",
                description: Text("We couldn't find that preview right now.")
            )
            .foregroundStyle(theme.foreground)
        }
    }
}
