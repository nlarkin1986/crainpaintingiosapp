import SwiftUI

enum AppTab: Int, Identifiable, Hashable, CaseIterable {
    case visualize
    case favorites
    case reports
    case expert

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .visualize: "Visualize"
        case .favorites: "Favorites"
        case .reports: "Reports"
        case .expert: "Expert"
        }
    }

    var iconOutlined: String {
        switch self {
        case .visualize: "wand.and.stars"
        case .favorites: "heart"
        case .reports: "doc.text"
        case .expert: "person.crop.circle"
        }
    }

    var iconFilled: String {
        switch self {
        case .visualize: "wand.and.stars"
        case .favorites: "heart.fill"
        case .reports: "doc.text.fill"
        case .expert: "person.crop.circle.fill"
        }
    }

    @ViewBuilder
    func makeContentView() -> some View {
        switch self {
        case .visualize: BrandSelectorView()
        case .favorites: FavoritesView()
        case .reports: ReportsHomeView()
        case .expert: ExpertHomeView()
        }
    }

    @ViewBuilder
    var label: some View {
        Label(title, systemImage: iconFilled)
    }
}
