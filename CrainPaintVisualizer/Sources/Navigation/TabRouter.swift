import SwiftUI

@MainActor
@Observable
final class TabRouter {
    private let previewRouter = RouterPath()
    private let libraryRouter = RouterPath()
    private let moreRouter = RouterPath()

    func router(for tab: AppTab) -> RouterPath {
        switch tab {
        case .preview:
            previewRouter
        case .library:
            libraryRouter
        case .more:
            moreRouter
        }
    }

    func binding(for tab: AppTab) -> Binding<[AppRoute]> {
        let routePath = router(for: tab)
        return Binding(get: { routePath.path }, set: { routePath.path = $0 })
    }
}
