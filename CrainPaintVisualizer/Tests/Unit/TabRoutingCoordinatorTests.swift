import XCTest
@testable import CrainPaintVisualizer

@MainActor
final class TabRoutingCoordinatorTests: XCTestCase {
    func testOpenVisualizerResetsPathAndSelectsVisualizeTab() {
        let router = TabRouter()
        let appState = AppState()
        let visualizerRouter = router.router(for: .visualize)

        visualizerRouter.navigate(to: .photoUpload)

        router.openVisualizer(appState: appState, route: .itemPicker)

        XCTAssertEqual(appState.selectedTab, .visualize)
        XCTAssertEqual(visualizerRouter.path, [.itemPicker])
    }

    func testOpenReportResetsReportsPathAndSelectsReportsTab() {
        let router = TabRouter()
        let appState = AppState()
        let reportsRouter = router.router(for: .reports)

        reportsRouter.navigate(to: .resultsGallery)

        router.openReport(reportId: "report_123", appState: appState)

        XCTAssertEqual(appState.selectedTab, .reports)
        XCTAssertEqual(reportsRouter.path, [.masterReport(reportId: "report_123")])
    }
}
