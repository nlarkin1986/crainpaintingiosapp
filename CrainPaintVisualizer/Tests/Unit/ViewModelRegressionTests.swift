import XCTest
import UIKit
@testable import CrainPaintVisualizer

actor DelayedFavoritesStore: FavoritesStore {
    let loadDelay: Duration
    let initialFavorites: [PaintColor]
    private(set) var savedSnapshots: [[PaintColor]] = []

    init(initialFavorites: [PaintColor], loadDelay: Duration = .milliseconds(50)) {
        self.initialFavorites = initialFavorites
        self.loadDelay = loadDelay
    }

    func loadFavorites() async throws -> [PaintColor] {
        try? await Task.sleep(for: loadDelay)
        return initialFavorites
    }

    func saveFavorites(_ favorites: [PaintColor]) async throws {
        savedSnapshots.append(favorites)
    }
}

actor DelayedReportStore: ReportStore {
    let loadDelay: Duration
    let initialReports: [MasterReport]
    private(set) var savedSnapshots: [[MasterReport]] = []

    init(initialReports: [MasterReport], loadDelay: Duration = .milliseconds(50)) {
        self.initialReports = initialReports
        self.loadDelay = loadDelay
    }

    func loadReports() async throws -> [MasterReport] {
        try? await Task.sleep(for: loadDelay)
        return initialReports
    }

    func saveReports(_ reports: [MasterReport]) async throws {
        savedSnapshots.append(reports)
    }
}

private struct StubColorMatchService: ColorMatchService {
    let result: [ColorMatchResult]

    func match(sampleHex: String) async throws -> [ColorMatchResult] {
        result
    }
}

@MainActor
final class ViewModelRegressionTests: XCTestCase {
    func testFavoritesAddedBeforeLoadCompletesAreMergedWithLoadedFavorites() async {
        let persistedFavorite = PaintColor(
            number: "HC-172",
            name: "Revere Pewter",
            family: "Neutral",
            hex: "CCC1AE",
            brand: .benjaminMoore
        )
        let newlyAddedFavorite = PaintColor(
            number: "SW 6244",
            name: "Naval",
            family: "Blue",
            hex: "2E384D",
            brand: .sherwinWilliams
        )
        let store = DelayedFavoritesStore(initialFavorites: [persistedFavorite])
        let viewModel = FavoritesViewModel(store: store)

        XCTAssertTrue(viewModel.addFavorite(newlyAddedFavorite))

        let merged = await waitForCondition {
            viewModel.favorites.first == newlyAddedFavorite &&
            viewModel.favorites.contains(persistedFavorite)
        }

        XCTAssertTrue(merged)
    }

    func testReportCreatedBeforeLoadCompletesSurvivesLoadedReports() async {
        let persistedReport = makeReport(id: "report_saved", createdAt: .now.addingTimeInterval(-300))
        let store = DelayedReportStore(initialReports: [persistedReport])
        let viewModel = ReportsViewModel(store: store)

        let createdReport = viewModel.createReport(from: nil)

        let merged = await waitForCondition {
            viewModel.report(for: createdReport.id) != nil &&
            viewModel.report(for: persistedReport.id) != nil
        }

        XCTAssertTrue(merged)
    }

    func testInvalidColorSampleDoesNotBecomeAnalyzable() {
        let fallbackMatch = ColorMatchResult(
            id: "benjamin_moore-HC-114",
            color: PaintColor(
                number: "HC-114",
                name: "Saybrook Sage",
                family: "Green",
                hex: "A4AE9F",
                brand: .benjaminMoore
            ),
            confidence: 98
        )
        let viewModel = ColorMatcherViewModel(service: StubColorMatchService(result: [fallbackMatch]))

        let accepted = viewModel.setSample(image: UIImage())

        XCTAssertFalse(accepted)
        XCTAssertFalse(viewModel.hasSample)
        XCTAssertEqual(viewModel.matches, [])
        XCTAssertEqual(viewModel.state, .error("Couldn’t read a clear color from that photo. Try centering the sample and using even light."))
    }

    private func makeReport(id: String, createdAt: Date) -> MasterReport {
        MasterReport(
            id: id,
            title: "Master Report",
            curatorName: "Curt Crain",
            curatorSubtitle: "Curated by Curt Crain",
            videoTitle: "Watch Curt's Analysis",
            videoDuration: 760,
            createdAt: createdAt,
            status: .ready,
            recommendations: [
                RoomRecommendation(
                    id: "\(id)_room_1",
                    roomName: "Living Room",
                    beforeTitle: "Before",
                    afterTitle: "After",
                    suggestedColor: PaintColor(
                        number: "HC-114",
                        name: "Saybrook Sage",
                        family: "Green",
                        hex: "A4AE9F",
                        brand: .benjaminMoore
                    ),
                    rationale: "Balanced undertones make this a reliable whole-room choice."
                )
            ]
        )
    }

    private func waitForCondition(
        timeout: Duration = .seconds(1),
        interval: Duration = .milliseconds(20),
        condition: @escaping () -> Bool
    ) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)

        while clock.now < deadline {
            if condition() {
                return true
            }
            try? await Task.sleep(for: interval)
        }

        return condition()
    }
}
