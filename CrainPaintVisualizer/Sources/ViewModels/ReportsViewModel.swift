import Foundation

@MainActor
@Observable
final class ReportsViewModel {
    var reports: [MasterReport] = []
    var isLoading = false

    private let store: ReportStore
    private var persistTask: Task<Void, Never>?

    var readyReports: [MasterReport] {
        reports.filter { $0.status.isReady }
    }

    init(store: ReportStore = FileReportStore()) {
        self.store = store
        Task { await loadReports() }
    }

    func report(for id: String) -> MasterReport? {
        reports.first(where: { $0.id == id })
    }

    @discardableResult
    func createReport(from visualization: Visualization?) -> MasterReport {
        let baseColor = visualization?.asPaintColor ?? PaintColor(
            number: "HC-114",
            name: "Saybrook Sage",
            family: "Green",
            hex: "A4AE9F",
            brand: .benjaminMoore
        )

        let id = "report_\(UUID().uuidString.prefix(8))"
        let recommendation1 = RoomRecommendation(
            id: "\(id)_room1",
            roomName: visualization?.roomName ?? "Living Room",
            beforeTitle: "Before",
            afterTitle: "After",
            suggestedColor: baseColor,
            rationale: "The soft undertones in this shade balance changing daylight while still keeping the room warm and inviting."
        )
        let recommendation2 = RoomRecommendation(
            id: "\(id)_room2",
            roomName: "Primary Bedroom",
            beforeTitle: "Before",
            afterTitle: "After",
            suggestedColor: PaintColor(number: "OC-45", name: "Swiss Coffee", family: "White", hex: "E9E1D1", brand: .benjaminMoore),
            rationale: "Use this lighter neutral in adjacent spaces to make transitions feel intentional and cohesive."
        )

        let report = MasterReport(
            id: id,
            title: "Master Report",
            curatorName: "Curt Crain",
            curatorSubtitle: "Curated by Curt Crain",
            videoTitle: "Watch Curt's Analysis",
            videoDuration: 12 * 60 + 40,
            createdAt: .now,
            status: .ready,
            recommendations: [recommendation1, recommendation2]
        )

        reports.insert(report, at: 0)
        schedulePersist()
        return report
    }

    private func loadReports() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let saved = try await store.loadReports()
            integrateLoadedReports(saved)
        } catch {
            integrateLoadedReports([])
        }
    }

    private func integrateLoadedReports(_ loaded: [MasterReport]) {
        let baseline = loaded.isEmpty ? makeSeedReports() : loaded.sorted(by: { $0.createdAt > $1.createdAt })

        if reports.isEmpty {
            reports = baseline
        } else {
            reports = mergeReports(current: reports, loaded: baseline)
        }
        schedulePersist()
    }

    private func makeSeedReports() -> [MasterReport] {
        let fallbackColor = PaintColor(number: "HC-114", name: "Saybrook Sage", family: "Green", hex: "A4AE9F", brand: .benjaminMoore)
        let report = MasterReport(
            id: "report_demo_1",
            title: "Master Report",
            curatorName: "Curt Crain",
            curatorSubtitle: "Curated by Curt Crain",
            videoTitle: "Watch Curt's Analysis",
            videoDuration: 12 * 60 + 40,
            createdAt: .now.addingTimeInterval(-86_400),
            status: .ready,
            recommendations: [
                RoomRecommendation(
                    id: "report_demo_1_room1",
                    roomName: "Living Room",
                    beforeTitle: "Before",
                    afterTitle: "After",
                    suggestedColor: fallbackColor,
                    rationale: "This balanced sage offsets warm afternoon light and tones down high-contrast furniture finishes."
                )
            ]
        )

        return [report]
    }

    private func schedulePersist() {
        persistTask?.cancel()
        let snapshot = reports
        persistTask = Task {
            try? await Task.sleep(for: .milliseconds(150))
            try? await store.saveReports(snapshot)
        }
    }

    private func mergeReports(current: [MasterReport], loaded: [MasterReport]) -> [MasterReport] {
        var mergedByID = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
        for report in current {
            mergedByID[report.id] = report
        }
        return mergedByID.values.sorted(by: { $0.createdAt > $1.createdAt })
    }
}
