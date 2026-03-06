import SwiftUI

@MainActor
enum AppTab: Int, Identifiable, Hashable, CaseIterable {
    case visualize
    case gallery
    case favorites

    var id: Int { rawValue }

    @ViewBuilder
    func makeContentView() -> some View {
        switch self {
        case .visualize: BrandSelectorView()
        case .gallery: ResultsGalleryView()
        case .favorites: FavoritesView()
        }
    }

    @ViewBuilder
    var label: some View {
        switch self {
        case .visualize: Label("Visualize", systemImage: "paintbrush")
        case .gallery: Label("Gallery", systemImage: "photo.on.rectangle.angled")
        case .favorites: Label("Favorites", systemImage: "heart")
        }
    }
}
