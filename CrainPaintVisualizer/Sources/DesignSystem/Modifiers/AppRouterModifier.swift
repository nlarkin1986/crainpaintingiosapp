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
            case .visualizationDetail(let id): VisualizationDetailView(visualizationId: id)
            }
        }
    }
}
