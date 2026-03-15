import SwiftUI

enum AppTab: Int, Identifiable, Hashable, CaseIterable {
    case preview
    case library
    case more

    var id: Int { rawValue }

    static var home: Self { .preview }
    static var saved: Self { .library }
    static var expert: Self { .more }

    var title: String {
        switch self {
        case .preview: "Preview"
        case .library: "Library"
        case .more: "More"
        }
    }

    var iconOutlined: String {
        switch self {
        case .preview: "sparkles.rectangle.stack"
        case .library: "square.stack.3d.up"
        case .more: "ellipsis.circle"
        }
    }

    var iconFilled: String {
        switch self {
        case .preview: "sparkles.rectangle.stack.fill"
        case .library: "square.stack.3d.up.fill"
        case .more: "ellipsis.circle.fill"
        }
    }

    @ViewBuilder
    func makeContentView() -> some View {
        switch self {
        case .preview: PreviewHomeView()
        case .library: LibraryHomeView()
        case .more: MoreHomeView()
        }
    }

    @ViewBuilder
    var label: some View {
        Label(title, systemImage: iconFilled)
    }
}
