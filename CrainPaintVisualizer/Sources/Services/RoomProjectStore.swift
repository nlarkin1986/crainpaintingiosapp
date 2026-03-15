import Foundation

protocol RoomProjectStore {
    func loadLibrary() async throws -> RoomProjectLibrary
    func loadLegacyProjectPhotoData(fileName: String?) async throws -> Data?
    func saveLibrary(_ library: RoomProjectLibrary) async throws -> RoomProjectLibrary
    func clearLibrary() async throws
}

actor FileRoomProjectStore: RoomProjectStore {
    private let libraryURL: URL
    private let photosDirectory: URL

    init(
        libraryFilename: String = "room-projects.json",
        photosDirectoryName: String = "room-project-assets"
    ) {
        libraryURL = AppStorage.fileURL(for: libraryFilename)
        photosDirectory = AppStorage.fileURL(for: photosDirectoryName)

        if !FileManager.default.fileExists(atPath: photosDirectory.path) {
            try? FileManager.default.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
        }
    }

    func loadLibrary() async throws -> RoomProjectLibrary {
        guard FileManager.default.fileExists(atPath: libraryURL.path) else {
            return RoomProjectLibrary()
        }

        let data = try Data(contentsOf: libraryURL)
        return try JSONDecoder().decode(RoomProjectLibrary.self, from: data)
    }

    func loadLegacyProjectPhotoData(fileName: String?) async throws -> Data? {
        guard let fileName else { return nil }
        let photoURL = photosDirectory.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: photoURL.path) else { return nil }
        return try Data(contentsOf: photoURL)
    }

    func saveLibrary(_ library: RoomProjectLibrary) async throws -> RoomProjectLibrary {
        let data = try JSONEncoder().encode(library)
        try data.write(to: libraryURL, options: .atomic)
        return library
    }

    func clearLibrary() async throws {
        if FileManager.default.fileExists(atPath: libraryURL.path) {
            try? FileManager.default.removeItem(at: libraryURL)
        }

        if FileManager.default.fileExists(atPath: photosDirectory.path) {
            let contents = try? FileManager.default.contentsOfDirectory(at: photosDirectory, includingPropertiesForKeys: nil)
            contents?.forEach { try? FileManager.default.removeItem(at: $0) }
        }
    }
}
