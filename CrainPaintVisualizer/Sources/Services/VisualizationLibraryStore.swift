import Foundation

protocol VisualizationLibraryStore {
    func loadResults() async throws -> [VisualizationResult]
    func saveResults(_ results: [VisualizationResult]) async throws
}

actor FileVisualizationLibraryStore: VisualizationLibraryStore {
    private let fileURL: URL

    init(filename: String = "visualization-results.json") {
        fileURL = AppStorage.fileURL(for: filename)
    }

    func loadResults() async throws -> [VisualizationResult] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        let results = try JSONDecoder().decode([VisualizationResult].self, from: data)
        return results.sorted(by: { $0.createdAt > $1.createdAt })
    }

    func saveResults(_ results: [VisualizationResult]) async throws {
        let data = try JSONEncoder().encode(results)
        try data.write(to: fileURL, options: .atomic)
    }
}

