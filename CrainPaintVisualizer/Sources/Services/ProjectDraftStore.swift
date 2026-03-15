import Foundation

protocol ProjectDraftStore {
    func loadDraft() async throws -> ProjectDraft?
    func loadLegacyDraftPhotoData(fileName: String?) async throws -> Data?
    func saveDraft(_ draft: ProjectDraft) async throws -> ProjectDraft
    func clearDraft() async throws
}

actor FileProjectDraftStore: ProjectDraftStore {
    private let draftURL: URL
    private let photosDirectory: URL

    init(
        draftFilename: String = "project-draft.json",
        photosDirectoryName: String = "project-draft-assets"
    ) {
        draftURL = AppStorage.fileURL(for: draftFilename)
        photosDirectory = AppStorage.fileURL(for: photosDirectoryName)

        if !FileManager.default.fileExists(atPath: photosDirectory.path) {
            try? FileManager.default.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
        }
    }

    func loadDraft() async throws -> ProjectDraft? {
        guard FileManager.default.fileExists(atPath: draftURL.path) else { return nil }
        let data = try Data(contentsOf: draftURL)
        return try JSONDecoder().decode(ProjectDraft.self, from: data)
    }

    func loadLegacyDraftPhotoData(fileName: String?) async throws -> Data? {
        guard let fileName else { return nil }
        let url = photosDirectory.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try Data(contentsOf: url)
    }

    func saveDraft(_ draft: ProjectDraft) async throws -> ProjectDraft {
        var updatedDraft = draft
        updatedDraft.updatedAt = .now
        let data = try JSONEncoder().encode(updatedDraft)
        try data.write(to: draftURL, options: .atomic)
        return updatedDraft
    }

    func clearDraft() async throws {
        if FileManager.default.fileExists(atPath: draftURL.path) {
            try? FileManager.default.removeItem(at: draftURL)
        }
        if FileManager.default.fileExists(atPath: photosDirectory.path) {
            let contents = try? FileManager.default.contentsOfDirectory(at: photosDirectory, includingPropertiesForKeys: nil)
            contents?.forEach { try? FileManager.default.removeItem(at: $0) }
        }
    }
}
