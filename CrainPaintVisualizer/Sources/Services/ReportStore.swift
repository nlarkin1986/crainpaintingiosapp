import Foundation

protocol ReportStore {
    func loadReports() async throws -> [MasterReport]
    func saveReports(_ reports: [MasterReport]) async throws
}

actor FileReportStore: ReportStore {
    private let fileURL: URL

    init(filename: String = "reports.json") {
        self.fileURL = AppStorage.fileURL(for: filename)
    }

    func loadReports() async throws -> [MasterReport] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([MasterReport].self, from: data)
    }

    func saveReports(_ reports: [MasterReport]) async throws {
        let data = try JSONEncoder().encode(reports)
        try data.write(to: fileURL, options: .atomic)
    }
}
