import Foundation

@MainActor
extension TabRouter {
    func openVisualizer(appState: AppState, route: AppRoute? = nil) {
        let visualizerRouter = router(for: .visualize)
        visualizerRouter.reset()
        if let route {
            visualizerRouter.navigate(to: route)
        }
        appState.selectedTab = .visualize
    }

    func openResultsGallery(appState: AppState) {
        openVisualizer(appState: appState, route: .resultsGallery)
    }

    func openReport(reportId: String, appState: AppState) {
        let reportsRouter = router(for: .reports)
        reportsRouter.reset()
        reportsRouter.navigate(to: .masterReport(reportId: reportId))
        appState.selectedTab = .reports
    }

    func handle(url: URL, appState: AppState) {
        guard url.scheme?.localizedCaseInsensitiveCompare("crainpaint") == .orderedSame else {
            return
        }

        appState.onboardingComplete = true

        let host = url.host?.lowercased()
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch host {
        case "report":
            if let reportId = pathComponents.first, !reportId.isEmpty {
                openReport(reportId: reportId, appState: appState)
            }
        case "visualize":
            openVisualizer(appState: appState)
        case "gallery":
            openResultsGallery(appState: appState)
        default:
            break
        }
    }
}
