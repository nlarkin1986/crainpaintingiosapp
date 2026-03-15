import Foundation

enum RoomProjectState: String, Codable, Hashable, Sendable {
    case idle
    case photoAdded
    case surfaceSelected
    case directionSelected
    case rendering
    case resultsReady
    case resultsPartial
    case resultsFailed
    case shortlisted
    case optionalConsultation
}

enum RoomProjectSource: String, Codable, Hashable, Sendable {
    case new
    case legacyImport
}

enum PreviewEntryPoint: String, Codable, Hashable, Sendable {
    case startWithRoom
    case colorMatcher
    case browseBrand
}

enum LibrarySection: String, CaseIterable, Identifiable {
    case projects = "Projects"
    case colors = "Colors"
    case reports = "Reports"

    var id: String { rawValue }
}

extension LibrarySection {
    static var previews: LibrarySection { .projects }
}

struct RoomProjectLibrary: Codable, Hashable, Sendable {
    var activeProjectID: String?
    var projects: [RoomProject]

    init(activeProjectID: String? = nil, projects: [RoomProject] = []) {
        self.activeProjectID = activeProjectID
        self.projects = projects
    }
}

struct RoomProject: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var title: String
    let createdAt: Date
    var updatedAt: Date
    var photoAsset: PhotoAssetReference?
    var photoFileName: String?
    var photoFingerprint: String?
    var selectedSurface: SurfaceType?
    var customSurfaceText: String
    var preferredBrand: PaintBrand
    var candidateColors: [PaintColor]
    var selectedVisualizationID: String?
    var shortlistedVisualizationIDs: [String]
    var visualizationIDs: [String]
    var reportIDs: [String]
    var state: RoomProjectState
    var source: RoomProjectSource

    init(
        id: String = "project-\(UUID().uuidString)",
        title: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        photoAsset: PhotoAssetReference? = nil,
        photoFileName: String? = nil,
        photoFingerprint: String? = nil,
        selectedSurface: SurfaceType? = nil,
        customSurfaceText: String = "",
        preferredBrand: PaintBrand = .benjaminMoore,
        candidateColors: [PaintColor] = [],
        selectedVisualizationID: String? = nil,
        shortlistedVisualizationIDs: [String] = [],
        visualizationIDs: [String] = [],
        reportIDs: [String] = [],
        state: RoomProjectState = .idle,
        source: RoomProjectSource = .new
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.photoAsset = photoAsset
        self.photoFileName = photoFileName
        self.photoFingerprint = photoFingerprint
        self.selectedSurface = selectedSurface
        self.customSurfaceText = customSurfaceText
        self.preferredBrand = preferredBrand
        self.candidateColors = candidateColors
        self.selectedVisualizationID = selectedVisualizationID
        self.shortlistedVisualizationIDs = shortlistedVisualizationIDs
        self.visualizationIDs = visualizationIDs
        self.reportIDs = reportIDs
        self.state = state
        self.source = source
    }

    var hasPhoto: Bool { photoAsset != nil || photoFileName != nil }
    var hasCandidateColors: Bool { !candidateColors.isEmpty }
}

struct RoomProjectMigrationResult: Sendable {
    let library: RoomProjectLibrary
    let savedResults: [VisualizationResult]
}

enum RoomProjectMigration {
    static func migrate(
        legacyDraft: ProjectDraft?,
        savedResults: [VisualizationResult]
    ) -> RoomProjectMigrationResult {
        var migratedResults = savedResults
        var projects: [RoomProject] = []
        var activeProjectID: String?

        if let legacyDraft, legacyDraft.hasSelections {
            let activeProject = migrateLegacyDraft(legacyDraft)
            projects.append(activeProject)
            activeProjectID = activeProject.id
        }

        let groupedResults = Dictionary(grouping: migratedResults.enumerated(), by: {
            migrationGroupKey(for: $0.element)
        })

        for (index, entry) in groupedResults
            .sorted(by: { $0.value.first?.offset ?? 0 < $1.value.first?.offset ?? 0 })
            .enumerated()
        {
            let results = entry.value
                .sorted(by: { $0.offset < $1.offset })
                .map(\.element)
            guard let firstResult = results.first else { continue }

            let restoredSurface = SurfaceType.restoredSelection(from: firstResult.surface)
            let projectID = "legacy-project-\(index + 1)"
            let project = RoomProject(
                id: projectID,
                title: firstResult.roomName,
                createdAt: results.map(\.createdAt).min() ?? firstResult.createdAt,
                updatedAt: results.map(\.createdAt).max() ?? firstResult.createdAt,
                selectedSurface: restoredSurface.surface,
                customSurfaceText: restoredSurface.customSurfaceText,
                preferredBrand: firstResult.color.brand,
                candidateColors: uniqueColors(from: results.map(\.color)),
                selectedVisualizationID: firstResult.id,
                visualizationIDs: results.map(\.id),
                state: .resultsReady,
                source: .legacyImport
            )
            projects.append(project)

            for result in results {
                if let migratedIndex = migratedResults.firstIndex(where: { $0.id == result.id }) {
                    migratedResults[migratedIndex].projectID = projectID
                }
            }
        }

        return RoomProjectMigrationResult(
            library: RoomProjectLibrary(activeProjectID: activeProjectID, projects: projects),
            savedResults: migratedResults
        )
    }

    private static func migrateLegacyDraft(_ draft: ProjectDraft) -> RoomProject {
        RoomProject(
            id: draft.id,
            title: draft.surfaceDescription.isEmpty ? "Current Project" : draft.surfaceDescription,
            createdAt: draft.updatedAt,
            updatedAt: draft.updatedAt,
            photoAsset: draft.photoAsset,
            photoFileName: draft.photoFileName,
            photoFingerprint: draft.photoFingerprint,
            selectedSurface: draft.selectedSurface,
            customSurfaceText: draft.customSurfaceText,
            preferredBrand: draft.selectedBrand,
            candidateColors: draft.selectedColors,
            state: projectState(for: draft),
            source: .legacyImport
        )
    }

    private static func projectState(for draft: ProjectDraft) -> RoomProjectState {
        if !draft.hasPhoto {
            return draft.selectedColors.isEmpty ? .idle : .directionSelected
        }
        if draft.selectedSurface == nil {
            return .photoAdded
        }
        if draft.selectedColors.isEmpty {
            return .surfaceSelected
        }
        return .directionSelected
    }

    private static func migrationGroupKey(for result: VisualizationResult) -> String {
        if !result.originalImagePath.isEmpty {
            return result.originalImagePath
        }
        if !result.originalRemoteURL.isEmpty {
            return result.originalRemoteURL
        }
        return result.id
    }

    private static func uniqueColors(from colors: [PaintColor]) -> [PaintColor] {
        var seen = Set<String>()
        return colors.filter { color in
            seen.insert(color.id).inserted
        }
    }
}
