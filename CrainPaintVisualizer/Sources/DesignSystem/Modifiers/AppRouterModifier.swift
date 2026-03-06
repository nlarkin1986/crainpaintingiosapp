import SwiftUI

extension View {
    func withAppRouter() -> some View {
        navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .brandSelector: BrandSelectorView()
            case .itemPicker: ItemPickerView()
            case .photoUpload: PhotoUploadView()
            case .surfacePicker: SurfacePickerView()
            case .colorMatcher: ColorMatcherView()
            case .resultsGallery: ResultsGalleryView()
            case .visualizationDetail(let visualization): VisualizationDetailView(visualization: visualization)
            case .reportsHome: ReportsHomeView()
            case .masterReport(let reportId): MasterReportView(reportId: reportId)
            case .sampleOutput(let reportId, let chapterId): SampleOutputView(reportId: reportId, chapterId: chapterId)
            case .consultationCheckout(let reportId): ConsultationCheckoutView(reportId: reportId)
            }
        }
    }
}
