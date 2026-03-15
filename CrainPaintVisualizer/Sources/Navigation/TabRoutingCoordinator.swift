import Foundation

@MainActor
extension TabRouter {
    func openPreview(appState: AppState, route: AppRoute? = nil) {
        let previewRouter = router(for: .preview)
        previewRouter.reset()
        if let route {
            previewRouter.navigate(to: route)
        }
        appState.selectedTab = .preview
    }

    func openLibrary(
        appState: AppState,
        section: LibrarySection = .projects,
        route: AppRoute? = nil
    ) {
        let libraryRouter = router(for: .library)
        libraryRouter.reset()
        appState.selectedLibrarySection = section
        if let route {
            libraryRouter.navigate(to: route)
        }
        appState.selectedTab = .library
    }

    func openMore(appState: AppState, route: AppRoute? = nil) {
        let moreRouter = router(for: .more)
        moreRouter.reset()
        if let route {
            moreRouter.navigate(to: route)
        }
        appState.selectedTab = .more
    }

    func openVisualizer(appState: AppState, route: AppRoute? = nil) {
        openPreview(appState: appState, route: route)
    }

    func openHome(appState: AppState, route: AppRoute? = nil) {
        openPreview(appState: appState, route: route)
    }

    func openSaved(
        appState: AppState,
        section: SavedLandingSection = .previews,
        route: AppRoute? = nil
    ) {
        openLibrary(appState: appState, section: section.librarySection, route: route)
    }

    func openResultsGallery(appState: AppState) {
        openPreview(appState: appState, route: .resultsGallery)
    }

    func openReport(reportId: String, appState: AppState) {
        openLibrary(appState: appState, section: .reports, route: .masterReport(reportId: reportId))
    }

    func handle(url: URL, appState: AppState, activeProjectID: String? = nil) {
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
            openPreview(appState: appState, route: .photoUpload)
        case "gallery":
            if let activeProjectID, !activeProjectID.isEmpty {
                openPreview(appState: appState, route: .results(projectID: activeProjectID))
            } else {
                openLibrary(appState: appState, section: .projects)
            }
        default:
            break
        }
    }
}
