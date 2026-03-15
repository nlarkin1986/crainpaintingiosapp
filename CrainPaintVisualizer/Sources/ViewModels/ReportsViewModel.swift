import Foundation

@MainActor
@Observable
final class ReportsViewModel {
    var reports: [MasterReport] = []
    var isLoading = false

    private let store: ReportStore
    private let reportsService: ReportsService
    private var persistTask: Task<Void, Never>?
    private var pollingTasks: [String: Task<Void, Never>] = [:]
    private var lastRefreshAt: Date?
    private let refreshThrottleInterval: TimeInterval

    var readyReports: [MasterReport] {
        reports.filter { $0.status.isReady }
    }

    init(
        store: ReportStore = FileReportStore(),
        reportsService: ReportsService = RemoteReportsService(),
        refreshThrottleInterval: TimeInterval = 20
    ) {
        self.store = store
        self.reportsService = reportsService
        self.refreshThrottleInterval = refreshThrottleInterval
        Task { await bootstrap() }
    }

    func report(for id: String) -> MasterReport? {
        reports.first(where: { $0.id == id })
    }

    @discardableResult
    func trackPendingReport(
        orderID: String,
        consultationFlow: ConsultationFlowState,
        sourceVisualization: Visualization? = nil,
        packageType: ConsultationPackageType? = nil
    ) -> MasterReport {
        let resolvedPackageType = packageType ?? consultationFlow.packageType
        let roomName = consultationFlow.sourceRoomName ?? sourceVisualization?.roomName
        let title = roomName.map { "\($0) Consultation" } ?? "Consultation in Progress"

        let draft = MasterReport(
            id: orderID,
            projectID: consultationFlow.sourceProjectID ?? sourceVisualization?.projectID,
            orderID: orderID,
            title: title,
            curatorName: "Curt Crain",
            curatorSubtitle: "Expert review in progress",
            videoThumbnailName: sourceVisualization?.afterImageName ?? "HowItWorksHero",
            videoTitle: "Curt's Video Walkthrough",
            videoDuration: 0,
            createdAt: .now,
            updatedAt: .now,
            status: .generating,
            statusMessage: "Your consultation is confirmed. We'll keep the report status updated here.",
            packageType: resolvedPackageType,
            recommendations: []
        )

        upsertReport(draft)
        schedulePersist()
        startPolling(orderID: orderID)
        return draft
    }

    func refreshReports(force: Bool = false) async {
        guard shouldRefreshReports(force: force) else { return }

        isLoading = true
        defer {
            isLoading = false
            lastRefreshAt = .now
        }

        let pendingOrderIDs = reports.compactMap(pendingOrderID(for:))
        guard !pendingOrderIDs.isEmpty else { return }

        for orderID in pendingOrderIDs {
            await refreshReport(orderID: orderID)
        }
    }

    func refreshReport(orderID: String) async {
        do {
            guard let remote = try await reportsService.fetchReport(orderID: orderID) else { return }
            upsertReport(remote)
            schedulePersist()

            if remote.status.isReady || remote.status == .failed {
                pollingTasks[orderID]?.cancel()
                pollingTasks.removeValue(forKey: orderID)
            }
        } catch {
            guard var existing = report(for: orderID) else { return }
            existing.statusMessage = "We couldn't refresh the report right now. Pull to retry or check again shortly."
            upsertReport(existing)
            schedulePersist()
        }
    }

    private func bootstrap() async {
        await loadReports()
        await refreshReports(force: true)

        for report in reports where report.status.isGenerating {
            if let orderID = pendingOrderID(for: report) {
                startPolling(orderID: orderID)
            }
        }
    }

    private func loadReports() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let loadedReports = try await store.loadReports()

            if reports.isEmpty {
                reports = loadedReports.sorted(by: { self.sortReports($0, $1) })
            } else {
                for report in loadedReports {
                    upsertReport(report)
                }
            }
        } catch {
            reports = []
        }
    }

    private func startPolling(orderID: String) {
        pollingTasks[orderID]?.cancel()
        pollingTasks[orderID] = Task {
            for _ in 0..<24 {
                guard !Task.isCancelled else { return }
                await refreshReport(orderID: orderID)

                if let report = report(for: orderID), report.status.isReady || report.status == .failed {
                    return
                }

                try? await Task.sleep(for: .seconds(5))
            }
        }
    }

    private func upsertReport(_ report: MasterReport) {
        if let index = reports.firstIndex(where: { $0.id == report.id }) {
            reports[index] = report
        } else if let orderID = report.orderID, let index = reports.firstIndex(where: { $0.orderID == orderID || $0.id == orderID }) {
            reports[index] = report
        } else {
            reports.insert(report, at: 0)
        }

        reports.sort(by: { self.sortReports($0, $1) })
    }

    private func schedulePersist() {
        persistTask?.cancel()
        let snapshot = reports
        persistTask = Task {
            try? await Task.sleep(for: .milliseconds(150))
            try? await store.saveReports(snapshot)
        }
    }

    private func sortReports(_ lhs: MasterReport, _ rhs: MasterReport) -> Bool {
        let lhsDate = lhs.updatedAt ?? lhs.createdAt
        let rhsDate = rhs.updatedAt ?? rhs.createdAt
        return lhsDate > rhsDate
    }

    private func pendingOrderID(for report: MasterReport) -> String? {
        guard report.status.isGenerating else { return nil }
        if let orderID = report.orderID, !orderID.isEmpty {
            return orderID
        }
        return report.id.isEmpty ? nil : report.id
    }

    private func shouldRefreshReports(force: Bool) -> Bool {
        guard !force else { return !isLoading }
        guard !isLoading else { return false }
        guard !reports.isEmpty else { return false }

        if let lastRefreshAt, Date().timeIntervalSince(lastRefreshAt) < refreshThrottleInterval {
            return false
        }

        return reports.contains(where: \.status.isGenerating)
    }
}
