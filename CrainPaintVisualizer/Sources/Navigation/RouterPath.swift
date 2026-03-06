import SwiftUI

@MainActor
@Observable
final class RouterPath {
    var path: [AppRoute] = []
    var presentedSheet: SheetDestination?

    func navigate(to route: AppRoute) {
        path.append(route)
    }

    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    func reset() {
        path = []
    }
}

enum SheetDestination: Identifiable {
    case colorMatcher
    case saveProposal

    var id: String { String(describing: self) }
}
