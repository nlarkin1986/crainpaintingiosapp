import XCTest
@testable import CrainPaintVisualizer

@MainActor
final class TabRoutingCoordinatorTests: XCTestCase {
    func testLibrarySectionUsesProjectsAsDefaultLanding() {
        XCTAssertEqual(LibrarySection.projects.rawValue, "Projects")
        XCTAssertEqual(AppState().selectedLibrarySection, .projects)
    }

    func testEveryPushedRouteHidesPersistentTabBar() {
        XCTAssertFalse(AppRoute.photoUpload.showsPersistentTabBar)
        XCTAssertFalse(AppRoute.itemPicker.showsPersistentTabBar)
        XCTAssertFalse(AppRoute.results(projectID: "room-123").showsPersistentTabBar)
        XCTAssertFalse(AppRoute.visualizationDetail(projectID: "room-123", visualizationID: "viz-123").showsPersistentTabBar)
    }

    func testPreviewLibraryMoreTabsExposeExpectedLabels() {
        XCTAssertEqual(AppTab.allCases, [.preview, .library, .more])
        XCTAssertEqual(AppTab.preview.title, "Preview")
        XCTAssertEqual(AppTab.library.title, "Library")
        XCTAssertEqual(AppTab.more.title, "More")
    }

    func testOpenPreviewResetsPathAndSelectsPreviewTab() {
        let router = TabRouter()
        let appState = AppState()
        let previewRouter = router.router(for: .preview)

        previewRouter.navigate(to: .surfacePicker)

        router.openPreview(appState: appState, route: .photoUpload)

        XCTAssertEqual(appState.selectedTab, .preview)
        XCTAssertEqual(previewRouter.path, [.photoUpload])
    }

    func testOpenReportTargetsLibraryReportsSection() {
        let router = TabRouter()
        let appState = AppState()
        let libraryRouter = router.router(for: .library)

        libraryRouter.navigate(to: .photoUpload)
        appState.selectedLibrarySection = .colors

        router.openReport(reportId: "report_123", appState: appState)

        XCTAssertEqual(appState.selectedTab, .library)
        XCTAssertEqual(appState.selectedLibrarySection, .reports)
        XCTAssertEqual(libraryRouter.path, [.masterReport(reportId: "report_123")])
    }

    func testVisualizeDeepLinkStartsAtPreviewPhotoUpload() {
        let router = TabRouter()
        let appState = AppState()

        router.handle(
            url: URL(string: "crainpaint://visualize")!,
            appState: appState,
            activeProjectID: nil
        )

        XCTAssertEqual(appState.selectedTab, .preview)
        XCTAssertEqual(router.router(for: .preview).path, [.photoUpload])
    }

    func testGalleryDeepLinkFallsBackToLibraryProjectsWithoutActiveProject() {
        let router = TabRouter()
        let appState = AppState()

        router.handle(
            url: URL(string: "crainpaint://gallery")!,
            appState: appState,
            activeProjectID: nil
        )

        XCTAssertEqual(appState.selectedTab, .library)
        XCTAssertEqual(appState.selectedLibrarySection, .projects)
        XCTAssertEqual(router.router(for: .library).path, [])
    }

    func testGalleryDeepLinkOpensActiveProjectResultsWhenProjectExists() {
        let router = TabRouter()
        let appState = AppState()

        router.handle(
            url: URL(string: "crainpaint://gallery")!,
            appState: appState,
            activeProjectID: "room-123"
        )

        XCTAssertEqual(appState.selectedTab, .preview)
        XCTAssertEqual(router.router(for: .preview).path, [.results(projectID: "room-123")])
    }
}
