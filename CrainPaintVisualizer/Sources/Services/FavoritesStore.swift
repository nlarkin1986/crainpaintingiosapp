import Foundation

protocol FavoritesStore {
    func loadFavorites() async throws -> [PaintColor]
    func saveFavorites(_ favorites: [PaintColor]) async throws
}

actor FileFavoritesStore: FavoritesStore {
    private let fileURL: URL

    init(filename: String = "favorites.json") {
        self.fileURL = AppStorage.fileURL(for: filename)
    }

    func loadFavorites() async throws -> [PaintColor] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([PaintColor].self, from: data)
    }

    func saveFavorites(_ favorites: [PaintColor]) async throws {
        let data = try JSONEncoder().encode(favorites)
        try data.write(to: fileURL, options: .atomic)
    }
}

enum AppStorage {
    private static func folderURL(using manager: FileManager = .default) -> URL {
        let base = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return base.appendingPathComponent("CrainPaintVisualizer", isDirectory: true)
    }

    static func fileURL(for filename: String) -> URL {
        let manager = FileManager.default
        let folder = folderURL(using: manager)

        if !manager.fileExists(atPath: folder.path) {
            try? manager.createDirectory(at: folder, withIntermediateDirectories: true)
        }

        return folder.appendingPathComponent(filename)
    }

    static func resetAllFiles(using manager: FileManager = .default) {
        let folder = folderURL(using: manager)
        if manager.fileExists(atPath: folder.path) {
            try? manager.removeItem(at: folder)
        }
        try? manager.createDirectory(at: folder, withIntermediateDirectories: true)
    }
}
