import SwiftUI

enum HomeProjectState: Equatable {
    case empty
    case chooseColors
    case addPhoto
    case chooseSurface
    case reviewDraft
    case resultsReady
    case processing
}

@MainActor
@Observable
final class VisualizerViewModel {
    var selectedBrand: PaintBrand = .benjaminMoore
    var selectedColors: [PaintColor] = []
    var photoAsset: PhotoAssetReference?
    var photo: UIImage?
    var selectedSurface: SurfaceType?
    var customSurfaceText = ""
    var isCompressing = false
    var currentJob: VisualizationJob?
    var savedResults: [VisualizationResult] = []
    var projects: [RoomProject] = []
    var activeProjectID: String?
    var lastGenerationMessage: String?
    var isLoadingLibrary = false
    var isLoadingDraft = false
    var isLoadingProjects = false

    private let projectStore: RoomProjectStore
    private let draftStore: ProjectDraftStore
    private let libraryStore: VisualizationLibraryStore
    private let visualizationService: VisualizationService
    private let photoIntakeCoordinator: any PhotoIntakeCoordinating
    private var persistTask: Task<Void, Never>?
    private var libraryPersistTask: Task<Void, Never>?
    private var projectPersistTask: Task<Void, Never>?
    private var compressionTask: Task<Void, Never>?
    private var compressionRequestID = UUID()
    private let processInfo: ProcessInfo
    private var photoFingerprint: String?

    var activeProject: RoomProject? {
        guard let activeProjectID else { return nil }
        return projects.first(where: { $0.id == activeProjectID })
    }

    var activeProjectResults: [VisualizationResult] {
        guard let activeProjectID else { return [] }
        return results(for: activeProjectID)
    }

    private var currentPhotoFingerprint: String? {
        photoAsset?.fingerprint ?? photoFingerprint
    }

    var canAddColor: Bool { selectedColors.count < 5 }
    var hasPhoto: Bool { photoAsset != nil || photo != nil }
    var hasSavedVisualizations: Bool { !savedResults.isEmpty }
    var hasProjects: Bool { !projects.isEmpty }
    var hasDraft: Bool { activeDraft.hasSelections || activeProjectHasResults }
    var hasResumeProgress: Bool { homeProjectState != .empty }

    var activeDraft: ProjectDraft {
        ProjectDraft(
            id: activeProjectID ?? "active-project",
            selectedBrand: selectedBrand,
            selectedColors: selectedColors,
            selectedSurface: selectedSurface,
            customSurfaceText: customSurfaceText,
            photoAsset: hasPhoto ? photoAsset : nil,
            photoFileName: nil,
            photoFingerprint: hasPhoto ? currentPhotoFingerprint : nil
        )
    }

    var savedVisualizations: [Visualization] {
        savedResults.map(\.visualization)
    }

    var activeProjectHasResults: Bool {
        !activeProjectResults.isEmpty || !(activeProject?.visualizationIDs.isEmpty ?? true)
    }

    func visualization(id: String, projectID: String? = nil) -> Visualization? {
        if let currentJobVisualization = currentJobCompletedVisualizations.first(where: { visualization in
            visualization.id == id && (projectID == nil || visualization.projectID == projectID)
        }) {
            return currentJobVisualization
        }

        return savedVisualizations.first(where: { visualization in
            visualization.id == id && (projectID == nil || visualization.projectID == projectID)
        })
    }

    var currentJobTotalCount: Int {
        currentJob?.items.count ?? 0
    }

    var currentJobCompletedCount: Int {
        currentJob?.items.filter(\.state.isCompleted).count ?? 0
    }

    var currentJobFailedCount: Int {
        currentJob?.items.filter(\.state.isFailed).count ?? 0
    }

    var currentJobProcessingCount: Int {
        currentJob?.items.filter(\.state.isProcessing).count ?? 0
    }

    var isCurrentJobProcessing: Bool {
        currentJob?.items.contains(where: { $0.state.isProcessing }) ?? false
    }

    var isCurrentJobFinished: Bool {
        currentJob != nil && !isCurrentJobProcessing
    }

    var latestVisualization: Visualization? {
        if let currentJobVisualization = currentJobCompletedVisualizations.first {
            return currentJobVisualization
        }

        if let activeProjectVisualization = activeProjectResults.first?.visualization {
            return activeProjectVisualization
        }

        return savedVisualizations.first
    }

    var currentJobCompletedVisualizations: [Visualization] {
        currentJob?.items.compactMap { item in
            guard case .completed(let result) = item.state else { return nil }
            return result.visualization
        } ?? []
    }

    var currentJobFailedItems: [VisualizationJobItem] {
        currentJob?.items.filter {
            if case .failed = $0.state { return true }
            return false
        } ?? []
    }

    var surfaceDescription: String {
        selectedSurface?.userFacingDescription(customSurfaceText: customSurfaceText) ?? ""
    }

    var currentRoomName: String {
        switch selectedSurface {
        case .cabinets:
            return "Kitchen Cabinets"
        case .doors:
            return "Front Entry"
        case .ceiling:
            return "Ceiling Plan"
        case .trimBase:
            return "Trim Refresh"
        case .accentWall:
            return "Accent Wall"
        case .walls:
            return "Current Room"
        case .custom:
            let trimmed = customSurfaceText.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "Custom Surface" : trimmed
        case nil:
            return hasPhoto ? "Current Project" : "Room Preview"
        }
    }

    var homeProjectState: HomeProjectState {
        if isCurrentJobProcessing {
            return .processing
        }
        if currentJob != nil || activeProjectHasResults {
            return .resultsReady
        }
        if !hasDraft {
            return .empty
        }
        if !hasPhoto {
            return .addPhoto
        }
        if !isSurfaceSelectionValid {
            return .chooseSurface
        }
        if selectedColors.isEmpty {
            return .chooseColors
        }
        return .reviewDraft
    }

    var homeScreenSubtitle: String {
        switch homeProjectState {
        case .processing:
            return "Your preview set is processing now. Stay close while the room study finishes."
        case .empty:
            return "Start a room preview and keep your strongest color ideas close."
        default:
            return "Continue your current draft or start a new preview."
        }
    }

    var homeProjectEyebrow: String {
        switch homeProjectState {
        case .processing:
            return "Preview Processing"
        case .empty:
            return "Start Preview"
        case .resultsReady:
            return "Current Results"
        default:
            return "Current Draft"
        }
    }

    var homeProjectTitle: String {
        switch homeProjectState {
        case .processing:
            return "Resume your active project"
        case .empty:
            return "Start with my room"
        case .reviewDraft:
            return "Resume your active project"
        case .resultsReady:
            return "Resume your active project"
        default:
            return "Continue your current draft"
        }
    }

    var homeProjectBadgeText: String? {
        switch homeProjectState {
        case .processing:
            return "Processing"
        case .resultsReady:
            return "Results ready"
        case .empty:
            return nil
        default:
            return "Draft saved"
        }
    }

    var showsHomeStartNewAction: Bool {
        switch homeProjectState {
        case .empty, .processing:
            return false
        default:
            return true
        }
    }

    var resumeRoute: AppRoute {
        switch homeProjectState {
        case .empty, .addPhoto:
            return .photoUpload
        case .chooseColors:
            return .itemPicker
        case .chooseSurface:
            return .surfacePicker
        case .reviewDraft:
            return .projectReview
        case .resultsReady, .processing:
            if let activeProjectID {
                return .results(projectID: activeProjectID)
            }
            return .resultsGallery
        }
    }

    var activeProjectResultsRoute: AppRoute {
        return resumeRoute
    }

    var homePrimaryCTAButtonTitle: String {
        switch homeProjectState {
        case .empty:
            return "Start with my room"
        case .addPhoto:
            return "Add Room Photo"
        case .chooseColors:
            return "Choose Colors"
        case .chooseSurface:
            return "Choose Surface"
        case .reviewDraft, .resultsReady, .processing:
            return "Resume project"
        }
    }

    var projectProgressLabel: String {
        if currentJob != nil {
            if isCurrentJobProcessing {
                let readyCount = currentJobCompletedCount
                let totalCount = currentJobTotalCount
                return readyCount > 0
                    ? "\(readyCount) of \(totalCount) previews ready"
                    : "Processing preview set"
            }

            let readyCount = currentJobCompletedCount
            let failedCount = currentJobFailedCount
            if failedCount > 0 {
                return readyCount > 0
                    ? "\(readyCount) ready, \(failedCount) need review"
                    : "Preview set needs review"
            }
            return readyCount == 1 ? "Preview ready" : "\(readyCount) previews ready"
        }
        if activeProjectHasResults {
            let readyCount = activeProjectResults.count
            if readyCount > 0 {
                return readyCount == 1 ? "Preview ready" : "\(readyCount) previews ready"
            }
        }
        if selectedColors.isEmpty {
            if hasPhoto {
                return "Photo ready"
            }
            if isSurfaceSelectionValid {
                return surfaceDescription
            }
            if hasDraft {
                return "Draft in progress"
            }
        }
        if selectedSurface != nil, isSurfaceSelectionValid {
            return "Ready to review"
        }
        if hasPhoto {
            return "Photo ready"
        }
        if !selectedColors.isEmpty {
            return "\(selectedColors.count) colors selected"
        }
        return "Start a new preview"
    }

    var isSurfaceSelectionValid: Bool {
        guard let selectedSurface else { return false }
        if selectedSurface == .custom {
            return !customSurfaceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }

    var canReviewProject: Bool {
        !selectedColors.isEmpty && hasPhoto && isSurfaceSelectionValid
    }

    init(
        projectStore: RoomProjectStore = FileRoomProjectStore(),
        draftStore: ProjectDraftStore = FileProjectDraftStore(),
        libraryStore: VisualizationLibraryStore = FileVisualizationLibraryStore(),
        visualizationService: VisualizationService? = nil,
        photoIntakeCoordinator: (any PhotoIntakeCoordinating)? = nil,
        processInfo: ProcessInfo = .processInfo
    ) {
        self.projectStore = projectStore
        self.draftStore = draftStore
        self.libraryStore = libraryStore
        self.photoIntakeCoordinator = photoIntakeCoordinator ?? PhotoIntakeCoordinator.shared
        self.processInfo = processInfo

        if let visualizationService {
            self.visualizationService = visualizationService
        } else if processInfo.arguments.contains("UITEST_ALLOW_LOCAL_PREVIEW") {
            self.visualizationService = MockVisualizationService(
                generationDelay: Self.mockPreviewDelay(from: processInfo),
                generationDelayByColorID: Self.mockPreviewDelayOverrides(from: processInfo),
                failingColorIDs: Self.mockPreviewFailureColorIDs(from: processInfo)
            )
        } else {
            self.visualizationService = RemoteVisualizationService(photoProcessor: .shared)
        }

        Task { await bootstrap() }
    }

    private static func mockPreviewDelay(from processInfo: ProcessInfo) -> Duration {
        guard
            let rawMilliseconds = processInfo.environment["UITEST_LOCAL_PREVIEW_DELAY_MS"],
            let milliseconds = Int(rawMilliseconds),
            milliseconds > 0
        else {
            return .milliseconds(450)
        }
        return .milliseconds(milliseconds)
    }

    private static func mockPreviewFailureColorIDs(from processInfo: ProcessInfo) -> Set<String> {
        guard let rawIDs = processInfo.environment["UITEST_LOCAL_PREVIEW_FAIL_COLOR_IDS"] else {
            return []
        }

        return Set(
            rawIDs
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        )
    }

    private static func mockPreviewDelayOverrides(from processInfo: ProcessInfo) -> [String: Duration] {
        guard let rawOverrides = processInfo.environment["UITEST_LOCAL_PREVIEW_DELAY_OVERRIDES_MS"] else {
            return [:]
        }

        return rawOverrides
            .split(separator: ",")
            .reduce(into: [String: Duration]()) { overrides, entry in
                let parts = entry.split(separator: "=", maxSplits: 1).map {
                    $0.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                guard
                    parts.count == 2,
                    !parts[0].isEmpty,
                    let milliseconds = Int(parts[1]),
                    milliseconds > 0
                else {
                    return
                }

                overrides[parts[0]] = .milliseconds(milliseconds)
            }
    }

    func toggleColor(_ color: PaintColor) {
        if let index = selectedColors.firstIndex(of: color) {
            selectedColors.remove(at: index)
        } else if canAddColor {
            selectedColors.append(color)
        }
        scheduleDraftPersist()
    }

    @discardableResult
    func addColor(_ color: PaintColor) -> Bool {
        guard !selectedColors.contains(color), canAddColor else { return false }
        if selectedColors.isEmpty {
            selectedBrand = color.brand
        }
        selectedColors.append(color)
        scheduleDraftPersist()
        return true
    }

    func setSelectedBrand(_ brand: PaintBrand) {
        selectedBrand = brand
        scheduleDraftPersist()
    }

    func setSelectedSurface(_ surface: SurfaceType?) {
        selectedSurface = surface
        if surface != .custom {
            customSurfaceText = ""
        }
        scheduleDraftPersist()
    }

    func setCustomSurfaceText(_ text: String) {
        customSurfaceText = text
        scheduleDraftPersist()
    }

    func clearPhoto() {
        let assetToRemove = photoAsset
        photoAsset = nil
        photo = nil
        photoFingerprint = nil
        scheduleDraftPersist()
        Task {
            await photoIntakeCoordinator.removeAsset(assetToRemove)
        }
    }

    func startFlow(with color: PaintColor) {
        compressionTask?.cancel()
        activeProjectID = nil
        currentJob = nil
        lastGenerationMessage = nil
        selectedBrand = color.brand
        selectedColors = [color]
        let assetToRemove = photoAsset
        photoAsset = nil
        photo = nil
        photoFingerprint = nil
        selectedSurface = nil
        customSurfaceText = ""
        isCompressing = false
        scheduleDraftPersist()
        Task {
            await photoIntakeCoordinator.removeAsset(assetToRemove)
        }
    }

    func isSelected(_ color: PaintColor) -> Bool {
        selectedColors.contains(color)
    }

    func setPhoto(from data: Data) {
        setPhoto(from: data, originalFileExtension: "jpg")
    }

    func setPhoto(from data: Data, originalFileExtension: String) {
        compressionTask?.cancel()
        let requestID = UUID()
        compressionRequestID = requestID
        isCompressing = true
        let assetToRemove = photoAsset
        photoAsset = nil
        photo = nil
        photoFingerprint = nil

        compressionTask = replacePhoto(
            requestID: requestID,
            previousAsset: assetToRemove
        ) {
            try await self.photoIntakeCoordinator.importPhotoData(
                data,
                originalFileExtension: originalFileExtension,
                displayMaxPixelSize: 1_600,
                fingerprintOverride: nil
            )
        }
    }

    func setPhoto(from importedPhoto: ImportedPhoto) async {
        let fileURL = importedPhoto.fileURL
        let fileExtension = fileURL.pathExtension.isEmpty ? "jpg" : fileURL.pathExtension

        do {
            let data = try await Self.loadImportedPhotoData(from: fileURL)
            setPhoto(from: data, originalFileExtension: fileExtension)
        } catch {
            if isCompressing {
                isCompressing = false
            }
        }
    }

    func prepareFreshProject() {
        currentJob = nil
        lastGenerationMessage = nil
        activeProjectID = nil
        selectedBrand = .benjaminMoore
        selectedColors = []
        let assetToRemove = photoAsset
        photoAsset = nil
        photo = nil
        photoFingerprint = nil
        selectedSurface = nil
        customSurfaceText = ""
        isCompressing = false
        scheduleDraftPersist()
        Task {
            await photoIntakeCoordinator.removeAsset(assetToRemove)
        }
    }

    func restoreDraft(from visualization: Visualization) async {
        compressionTask?.cancel()
        activeProjectID = nil
        currentJob = nil
        lastGenerationMessage = nil

        let restoredColor = visualization.asPaintColor
        let restoredSurfaceSelection = SurfaceType.restoredSelection(from: visualization.surface)

        selectedBrand = restoredColor.brand
        selectedColors = [restoredColor]
        selectedSurface = restoredSurfaceSelection.surface
        customSurfaceText = restoredSurfaceSelection.customSurfaceText
        isCompressing = false

        let restoredPhoto = await VisualizationImageRepository.shared.loadImage(
            for: visualization,
            role: .before,
            preset: .detail
        )
        if let restoredPhoto {
            let prepared = try? await photoIntakeCoordinator.importImage(
                restoredPhoto,
                originalFileExtension: "jpg",
                displayMaxPixelSize: 1_600,
                fingerprintOverride: nil
            )
            photoAsset = prepared?.asset
            photo = prepared?.displayImage ?? restoredPhoto
            photoFingerprint = prepared?.asset.fingerprint
        } else {
            photoAsset = nil
            photo = nil
            photoFingerprint = nil
        }

        scheduleDraftPersist()
    }

    func startGeneration() async {
        guard canReviewProject, let surface = selectedSurface else { return }
        guard let photo = await resolveCurrentPhotoForGeneration() else { return }
        let projectID = ensureActiveProject()

        let roomName = currentRoomName
        let surfaceDescription = surface.userFacingDescription(customSurfaceText: customSurfaceText)

        currentJob = VisualizationJob(
            surfaceDescription: surfaceDescription,
            roomName: roomName,
            items: selectedColors.map { VisualizationJobItem(color: $0) }
        )
        lastGenerationMessage = nil
        syncActiveProjectFromWorkingState(stateOverride: .rendering)

        let resolvedPhotoFingerprint = await resolvePhotoFingerprint(for: photo)
        let requestFingerprintsByColor: [String: String] = Dictionary(
            uniqueKeysWithValues: selectedColors.compactMap { color -> (String, String)? in
                guard let resolvedPhotoFingerprint else { return nil }
                return (
                    color.id,
                    VisualizationRequestFingerprint.make(
                        photoFingerprint: resolvedPhotoFingerprint,
                        color: color,
                        surface: surface,
                        customSurfaceText: customSurfaceText
                    )
                )
            }
        )

        for color in selectedColors {
            guard
                let requestFingerprint = requestFingerprintsByColor[color.id],
                let cachedResult = cachedResult(for: requestFingerprint)
            else {
                continue
            }
            let resolvedCachedResult = cachedResult.projectID == nil
                ? cachedResult.withProjectID(projectID)
                : cachedResult
            updateJobItem(colorID: color.id, state: .completed(resolvedCachedResult))
            associateVisualization(
                id: resolvedCachedResult.id,
                with: projectID,
                selectedIfNeeded: true
            )
        }

        let missingColors = selectedColors.filter { color in
            currentJob?.items.first(where: { $0.id == color.id }).flatMap {
                if case .completed = $0.state { return false }
                return true
            } ?? true
        }

        guard !missingColors.isEmpty else {
            scheduleLibraryPersist()
            return
        }

        for color in missingColors {
            updateJobItem(colorID: color.id, state: .generating)

            do {
                let generatedResult = try await visualizationService.generatePreview(
                    color: color,
                    photo: photo,
                    surface: surface,
                    customSurfaceText: customSurfaceText,
                    roomName: roomName
                )
                let result = generatedResult
                    .withProjectID(projectID)
                    .withRequestFingerprint(requestFingerprintsByColor[color.id])
                updateJobItem(colorID: color.id, state: .completed(result))
                insertSavedResult(result)
            } catch let error as VisualizationServiceError {
                handleGenerationError(error, for: color)
                if case .rateLimited = error {
                    break
                }
            } catch {
                updateJobItem(
                    colorID: color.id,
                    state: .failed("We couldn't generate that preview. Please try again.")
                )
            }
        }

        scheduleLibraryPersist()
    }

    func retryGeneration(for color: PaintColor) async {
        guard let surface = selectedSurface else { return }
        guard let photo = await resolveCurrentPhotoForGeneration() else { return }
        let projectID = ensureActiveProject()
        let requestFingerprint = await resolvePhotoFingerprint(for: photo).map {
            VisualizationRequestFingerprint.make(
                photoFingerprint: $0,
                color: color,
                surface: surface,
                customSurfaceText: customSurfaceText
            )
        }

        updateJobItem(colorID: color.id, state: .generating)

        do {
            let generatedResult = try await visualizationService.generatePreview(
                color: color,
                photo: photo,
                surface: surface,
                customSurfaceText: customSurfaceText,
                roomName: currentRoomName
            )
            let result = generatedResult
                .withProjectID(projectID)
                .withRequestFingerprint(requestFingerprint)
            updateJobItem(colorID: color.id, state: .completed(result))
            insertSavedResult(result)
            scheduleLibraryPersist()
        } catch let error as VisualizationServiceError {
            handleGenerationError(error, for: color)
        } catch {
            updateJobItem(
                colorID: color.id,
                state: .failed("We couldn't generate that preview. Please try again.")
            )
        }
    }

    func removeSavedVisualization(_ visualization: Visualization) {
        savedResults.removeAll(where: { $0.id == visualization.id })
        dissociateVisualization(id: visualization.id, projectID: visualization.projectID)
        scheduleLibraryPersist()
    }

    func project(id: String) -> RoomProject? {
        projects.first(where: { $0.id == id })
    }

    func results(for projectID: String) -> [VisualizationResult] {
        let orderedIDs = project(id: projectID)?.visualizationIDs ?? []
        let orderedIndex = Dictionary(uniqueKeysWithValues: orderedIDs.enumerated().map { ($0.element, $0.offset) })

        return savedResults
            .filter { $0.projectID == projectID }
            .sorted { lhs, rhs in
                switch (orderedIndex[lhs.id], orderedIndex[rhs.id]) {
                case let (lhsIndex?, rhsIndex?):
                    return lhsIndex < rhsIndex
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                default:
                    return lhs.createdAt > rhs.createdAt
                }
            }
    }

    func activateProject(_ projectID: String) async {
        guard let project = project(id: projectID) else { return }
        activeProjectID = projectID
        let loadedPhoto = await resolvedDisplayImage(
            for: project.photoAsset,
            legacyFileName: project.photoFileName
        )
        await applyProjectState(project, photo: loadedPhoto)
        scheduleDraftPersist()
    }

    func selectVisualization(_ visualizationID: String, projectID: String? = nil) {
        let targetProjectID = projectID ?? activeProjectID
        guard let targetProjectID else { return }

        updateProject(id: targetProjectID) { project in
            project.selectedVisualizationID = visualizationID
            project.updatedAt = .now
        }
        scheduleProjectPersist()
    }

    func toggleShortlist(visualizationID: String, projectID: String? = nil) {
        let targetProjectID = projectID ?? activeProjectID
        guard let targetProjectID else { return }

        updateProject(id: targetProjectID) { project in
            if let index = project.shortlistedVisualizationIDs.firstIndex(of: visualizationID) {
                project.shortlistedVisualizationIDs.remove(at: index)
            } else {
                project.shortlistedVisualizationIDs.append(visualizationID)
            }
            project.updatedAt = .now
            project.state = currentSessionState(for: project)
        }
        scheduleProjectPersist()
    }

    func reset() {
        compressionTask?.cancel()
        persistTask?.cancel()
        libraryPersistTask?.cancel()
        projectPersistTask?.cancel()
        if let activeProjectID {
            discardProjectIfUnsaved(activeProjectID)
        }
        currentJob = nil
        lastGenerationMessage = nil
        selectedBrand = .benjaminMoore
        selectedColors = []
        let assetToRemove = photoAsset
        photoAsset = nil
        photo = nil
        photoFingerprint = nil
        selectedSurface = nil
        customSurfaceText = ""
        isCompressing = false
        activeProjectID = nil

        Task {
            await photoIntakeCoordinator.removeAsset(assetToRemove)
            try? await draftStore.clearDraft()
            await persistProjectLibraryNow()
        }
    }

    func makeConsultationFlowState(from visualization: Visualization?) -> ConsultationFlowState {
        ConsultationFlowState(
            sourceProjectID: visualization?.projectID ?? activeProjectID,
            sourceVisualizationID: visualization?.id,
            sourceColor: visualization?.asPaintColor ?? selectedColors.first,
            sourceRoomName: visualization?.roomName ?? currentRoomName
        )
    }

    private func bootstrap() async {
        if processInfo.arguments.contains("UITEST_SEED_PHOTO") {
            let seeded = try? await photoIntakeCoordinator.importImage(
                Self.makeUITestImage(),
                originalFileExtension: "jpg",
                displayMaxPixelSize: 1_600,
                fingerprintOverride: nil
            )
            photoAsset = seeded?.asset
            photo = seeded?.displayImage
            photoFingerprint = seeded?.asset.fingerprint
        }

        await loadSavedResults()
        let legacyDraftSnapshot = await loadLegacyDraftSnapshot()
        await loadProjects(legacyDraft: legacyDraftSnapshot.draft, legacyPhoto: legacyDraftSnapshot.photo)

        if processInfo.arguments.contains("UITEST_SEED_PHOTO"), photoAsset == nil, photo == nil {
            let seeded = try? await photoIntakeCoordinator.importImage(
                Self.makeUITestImage(),
                originalFileExtension: "jpg",
                displayMaxPixelSize: 1_600,
                fingerprintOverride: nil
            )
            photoAsset = seeded?.asset
            photo = seeded?.displayImage
            photoFingerprint = seeded?.asset.fingerprint
        }
        scheduleDraftPersist()
    }

    private func loadLegacyDraftSnapshot() async -> (draft: ProjectDraft?, photo: UIImage?) {
        isLoadingDraft = true
        defer { isLoadingDraft = false }

        do {
            guard var draft = try await draftStore.loadDraft() else { return (nil, nil) }
            if let photoAsset = draft.photoAsset {
                let loadedPhoto = await photoIntakeCoordinator.loadDisplayImage(
                    for: photoAsset,
                    maxPixelSize: 1_600
                )
                if draft.photoFingerprint == nil {
                    draft.photoFingerprint = photoAsset.fingerprint
                }
                return (draft, loadedPhoto)
            }

            guard
                let legacyData = try await draftStore.loadLegacyDraftPhotoData(fileName: draft.photoFileName)
            else {
                return (draft, nil)
            }

            let migrated = try await photoIntakeCoordinator.migrateLegacyPhotoData(
                legacyData,
                fileName: draft.photoFileName,
                fingerprint: draft.photoFingerprint
            )
            draft.photoAsset = migrated.asset
            draft.photoFileName = nil
            draft.photoFingerprint = migrated.asset.fingerprint
            _ = try? await draftStore.saveDraft(draft)
            return (draft, migrated.displayImage)
        } catch {
            // Keep app usable with in-memory state if draft loading fails.
            return (nil, nil)
        }
    }

    private func loadSavedResults() async {
        isLoadingLibrary = true
        defer { isLoadingLibrary = false }

        do {
            savedResults = try await libraryStore.loadResults()
        } catch {
            savedResults = []
        }
    }

    private func loadProjects(legacyDraft: ProjectDraft?, legacyPhoto: UIImage?) async {
        isLoadingProjects = true
        defer { isLoadingProjects = false }

        var migratedStoredProjects = false
        do {
            let storedLibrary = try await projectStore.loadLibrary()
            let migratedProjects = await migrateLegacyProjectAssets(in: storedLibrary.projects)
            projects = migratedProjects.projects
            activeProjectID = storedLibrary.activeProjectID
            migratedStoredProjects = migratedProjects.didMigrate
        } catch {
            projects = []
            activeProjectID = nil
        }

        if projects.isEmpty {
            let hadLegacyDraft = legacyDraft?.hasSelections == true
            let existingSavedResults = savedResults
            let migrated = RoomProjectMigration.migrate(
                legacyDraft: legacyDraft,
                savedResults: savedResults
            )
            projects = migrated.library.projects
            activeProjectID = migrated.library.activeProjectID
            savedResults = migrated.savedResults.sorted(by: { $0.createdAt > $1.createdAt })

            if hadLegacyDraft || migrated.savedResults != existingSavedResults {
                await persistSavedResultsNow()
                await persistProjectLibraryNow()
            }
        } else if migratedStoredProjects {
            await persistProjectLibraryNow()
        }

        if let activeProject {
            let loadedPhoto = await resolvedDisplayImage(
                for: activeProject.photoAsset,
                legacyFileName: activeProject.photoFileName
            )
            await applyProjectState(activeProject, photo: loadedPhoto ?? legacyPhoto)
        } else if let legacyDraft, legacyDraft.hasSelections {
            await applyLegacyDraftState(legacyDraft, photo: legacyPhoto)
        }
    }

    private func scheduleDraftPersist() {
        syncActiveProjectFromWorkingState()

        let draft = activeDraft

        persistTask?.cancel()
        persistTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(180))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            if draft.hasSelections {
                _ = try? await draftStore.saveDraft(draft)
            } else {
                try? await draftStore.clearDraft()
            }
        }

        scheduleProjectPersist()
    }

    private func scheduleLibraryPersist() {
        let snapshot = savedResults.sorted(by: { $0.createdAt > $1.createdAt })
        libraryPersistTask?.cancel()
        libraryPersistTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(150))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            try? await libraryStore.saveResults(snapshot)
        }

        scheduleProjectPersist()
    }

    private func scheduleProjectPersist() {
        let snapshot = RoomProjectLibrary(activeProjectID: activeProjectID, projects: projects)

        projectPersistTask?.cancel()
        projectPersistTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(150))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            await persistProjectLibrary(snapshot)
        }
    }

    private func persistSavedResultsNow() async {
        let snapshot = savedResults.sorted(by: { $0.createdAt > $1.createdAt })
        try? await libraryStore.saveResults(snapshot)
        savedResults = snapshot
    }

    private func persistProjectLibraryNow() async {
        let snapshot = RoomProjectLibrary(activeProjectID: activeProjectID, projects: projects)
        await persistProjectLibrary(snapshot)
    }

    private func persistProjectLibrary(_ library: RoomProjectLibrary) async {
        do {
            let persistedLibrary = try await projectStore.saveLibrary(library)
            projects = persistedLibrary.projects
            activeProjectID = persistedLibrary.activeProjectID
        } catch {
            // Keep the in-memory session alive if persistence fails.
        }
    }

    private func insertSavedResult(_ result: VisualizationResult) {
        let normalizedResult = result.projectID == nil ? result.withProjectID(activeProjectID) : result

        savedResults.removeAll { existing in
            if existing.id == result.id {
                return true
            }
            guard let resultFingerprint = normalizedResult.requestFingerprint else {
                return false
            }
            return existing.requestFingerprint == resultFingerprint
        }
        savedResults.insert(normalizedResult, at: 0)

        if let projectID = normalizedResult.projectID ?? activeProjectID {
            associateVisualization(id: normalizedResult.id, with: projectID, selectedIfNeeded: true)
        }
    }

    private func cachedResult(for requestFingerprint: String) -> VisualizationResult? {
        savedResults.first { result in
            result.requestFingerprint == requestFingerprint && result.hasRequiredLocalAssets
        }
    }

    private func updateJobItem(colorID: String, state: VisualizationJobItemState) {
        guard var job = currentJob, let index = job.items.firstIndex(where: { $0.id == colorID }) else { return }
        job.items[index].state = state
        currentJob = job
        refreshActiveProjectState()
    }

    private func handleGenerationError(_ error: VisualizationServiceError, for color: PaintColor) {
        switch error {
        case .rateLimited(let message, let retryAfterSeconds):
            let detail = if let retryAfterSeconds {
                "\(message) Try again in about \(retryAfterSeconds / 60 + 1) minutes."
            } else {
                message
            }
            updateJobItem(colorID: color.id, state: .failed(detail))
            markQueuedItemsAsSkipped(after: color)
            lastGenerationMessage = detail
            currentJob?.notice = detail
        default:
            updateJobItem(
                colorID: color.id,
                state: .failed(error.errorDescription ?? "We couldn't generate that preview.")
            )
        }
    }

    private func markQueuedItemsAsSkipped(after color: PaintColor) {
        guard var job = currentJob else { return }
        var didPassCurrent = false
        for index in job.items.indices {
            if job.items[index].id == color.id {
                didPassCurrent = true
                continue
            }

            guard didPassCurrent else { continue }
            if case .queued = job.items[index].state {
                job.items[index].state = .failed("Skipped because preview generation is temporarily rate limited.")
            }
        }
        currentJob = job
        refreshActiveProjectState()
    }

    private func resolvePhotoFingerprint(for image: UIImage) async -> String? {
        if let photoAsset {
            photoFingerprint = photoAsset.fingerprint
            return photoAsset.fingerprint
        }
        if let photoFingerprint {
            return photoFingerprint
        }

        let computedFingerprint = await PhotoProcessingService.shared.fingerprint(for: image)
        if let computedFingerprint {
            photoFingerprint = computedFingerprint
            scheduleDraftPersist()
        }
        return computedFingerprint
    }

    private func applyLegacyDraftState(_ draft: ProjectDraft, photo: UIImage?) async {
        selectedBrand = draft.selectedBrand
        selectedColors = draft.selectedColors
        selectedSurface = draft.selectedSurface
        customSurfaceText = draft.customSurfaceText
        photoAsset = draft.photoAsset
        self.photo = photo
        photoFingerprint = draft.photoAsset?.fingerprint ?? draft.photoFingerprint

        if photoFingerprint == nil, let photo {
            photoFingerprint = await PhotoProcessingService.shared.fingerprint(for: photo)
        }
    }

    private func applyProjectState(_ project: RoomProject, photo: UIImage?) async {
        selectedBrand = project.preferredBrand
        selectedColors = project.candidateColors
        selectedSurface = project.selectedSurface
        customSurfaceText = project.customSurfaceText
        photoAsset = project.photoAsset
        self.photo = photo
        photoFingerprint = project.photoAsset?.fingerprint ?? project.photoFingerprint
        currentJob = nil
        lastGenerationMessage = nil

        if photoFingerprint == nil, let photo {
            photoFingerprint = await PhotoProcessingService.shared.fingerprint(for: photo)
        }
    }

    @discardableResult
    private func ensureActiveProject(source: RoomProjectSource = .new) -> String {
        if let activeProjectID, project(id: activeProjectID) != nil {
            return activeProjectID
        }

        let project = RoomProject(
            title: currentRoomName,
            photoAsset: photoAsset,
            photoFingerprint: currentPhotoFingerprint,
            selectedSurface: selectedSurface,
            customSurfaceText: customSurfaceText,
            preferredBrand: selectedBrand,
            candidateColors: selectedColors,
            state: currentSessionState(shortlistedCount: 0),
            source: source
        )
        projects.insert(project, at: 0)
        activeProjectID = project.id
        return project.id
    }

    private func updateProject(id: String, _ mutate: (inout RoomProject) -> Void) {
        guard let index = projects.firstIndex(where: { $0.id == id }) else { return }
        mutate(&projects[index])
    }

    private func syncActiveProjectFromWorkingState(stateOverride: RoomProjectState? = nil) {
        guard activeDraft.hasSelections || activeProjectHasResults || currentJob != nil else { return }

        let projectID = ensureActiveProject()
        updateProject(id: projectID) { project in
            project.title = currentRoomName
            project.photoAsset = photoAsset
            project.photoFingerprint = currentPhotoFingerprint
            project.selectedSurface = selectedSurface
            project.customSurfaceText = customSurfaceText
            project.preferredBrand = selectedBrand
            project.candidateColors = selectedColors
            project.updatedAt = .now
            project.state = stateOverride ?? currentSessionState(for: project)

            if photoAsset == nil {
                project.photoFileName = nil
            }
        }
    }

    private func refreshActiveProjectState() {
        guard let activeProjectID else { return }
        updateProject(id: activeProjectID) { project in
            project.state = currentSessionState(for: project)
            project.updatedAt = .now
        }
    }

    private func currentSessionState(
        for project: RoomProject? = nil,
        shortlistedCount: Int? = nil
    ) -> RoomProjectState {
        let shortlistCount = shortlistedCount ?? project?.shortlistedVisualizationIDs.count ?? 0
        let readyCount: Int
        if let project {
            readyCount = max(
                project.visualizationIDs.count,
                savedResults.filter { $0.projectID == project.id }.count
            )
        } else if let activeProjectID {
            readyCount = savedResults.filter { $0.projectID == activeProjectID }.count
        } else {
            readyCount = 0
        }

        if shortlistCount > 0 {
            return .shortlisted
        }

        if let currentJob {
            let completedCount = currentJob.items.filter(\.state.isCompleted).count
            let failedCount = currentJob.items.filter(\.state.isFailed).count
            let processingCount = currentJob.items.filter(\.state.isProcessing).count

            if processingCount > 0 {
                return .rendering
            }
            if completedCount > 0 && failedCount > 0 {
                return .resultsPartial
            }
            if completedCount > 0 {
                return .resultsReady
            }
            if failedCount > 0 {
                return .resultsFailed
            }
        }

        if readyCount > 0 {
            return .resultsReady
        }
        if !selectedColors.isEmpty {
            return .directionSelected
        }
        if selectedSurface != nil && isSurfaceSelectionValid {
            return .surfaceSelected
        }
        if hasPhoto {
            return .photoAdded
        }
        return .idle
    }

    private func associateVisualization(
        id visualizationID: String,
        with projectID: String,
        selectedIfNeeded: Bool
    ) {
        updateProject(id: projectID) { project in
            if !project.visualizationIDs.contains(visualizationID) {
                project.visualizationIDs.append(visualizationID)
            }
            if selectedIfNeeded, project.selectedVisualizationID == nil {
                project.selectedVisualizationID = visualizationID
            }
            project.updatedAt = .now
            project.state = currentSessionState(for: project)
        }
    }

    private func dissociateVisualization(id visualizationID: String, projectID: String?) {
        if let projectID {
            updateProject(id: projectID) { project in
                project.visualizationIDs.removeAll(where: { $0 == visualizationID })
                project.shortlistedVisualizationIDs.removeAll(where: { $0 == visualizationID })
                if project.selectedVisualizationID == visualizationID {
                    project.selectedVisualizationID = project.visualizationIDs.first
                }
                project.updatedAt = .now
                project.state = currentSessionState(for: project)
            }
            return
        }

        for index in projects.indices {
            projects[index].visualizationIDs.removeAll(where: { $0 == visualizationID })
            projects[index].shortlistedVisualizationIDs.removeAll(where: { $0 == visualizationID })
            if projects[index].selectedVisualizationID == visualizationID {
                projects[index].selectedVisualizationID = projects[index].visualizationIDs.first
            }
            projects[index].state = currentSessionState(for: projects[index])
        }
    }

    private func discardProjectIfUnsaved(_ projectID: String) {
        guard let projectIndex = projects.firstIndex(where: { $0.id == projectID }) else { return }

        let project = projects[projectIndex]
        let hasPersistentArtifacts = !project.visualizationIDs.isEmpty
            || !project.reportIDs.isEmpty
            || !project.shortlistedVisualizationIDs.isEmpty

        guard !hasPersistentArtifacts, project.source == .new else { return }
        projects.remove(at: projectIndex)
    }

    private func resolveCurrentPhotoForGeneration() async -> UIImage? {
        if let photo {
            return photo
        }
        guard let photoAsset else { return nil }
        let resolved = await photoIntakeCoordinator.loadDisplayImage(
            for: photoAsset,
            maxPixelSize: 1_600
        )
        if self.photo == nil {
            self.photo = resolved
        }
        return resolved
    }

    private func resolvedDisplayImage(
        for asset: PhotoAssetReference?,
        legacyFileName: String?
    ) async -> UIImage? {
        if let asset {
            return await photoIntakeCoordinator.loadDisplayImage(for: asset, maxPixelSize: 1_600)
        }

        guard
            let legacyData = try? await projectStore.loadLegacyProjectPhotoData(fileName: legacyFileName)
        else {
            return nil
        }

        return UIImage(data: legacyData)
    }

    private func migrateLegacyProjectAssets(
        in storedProjects: [RoomProject]
    ) async -> (projects: [RoomProject], didMigrate: Bool) {
        var updatedProjects = storedProjects
        var didMigrate = false

        for index in updatedProjects.indices {
            guard
                updatedProjects[index].photoAsset == nil,
                let legacyData = try? await projectStore.loadLegacyProjectPhotoData(
                    fileName: updatedProjects[index].photoFileName
                )
            else {
                continue
            }

            let migrated = try? await photoIntakeCoordinator.migrateLegacyPhotoData(
                legacyData,
                fileName: updatedProjects[index].photoFileName,
                fingerprint: updatedProjects[index].photoFingerprint
            )
            guard let migrated else { continue }

            updatedProjects[index].photoAsset = migrated.asset
            updatedProjects[index].photoFileName = nil
            updatedProjects[index].photoFingerprint = migrated.asset.fingerprint
            didMigrate = true
        }

        return (updatedProjects, didMigrate)
    }

    private func replacePhoto(
        requestID: UUID,
        previousAsset: PhotoAssetReference?,
        importOperation: @escaping @Sendable () async throws -> PhotoIntakeResult
    ) -> Task<Void, Never> {
        Task(priority: .userInitiated) {
            do {
                let prepared = try await importOperation()

                guard !Task.isCancelled else {
                    await self.photoIntakeCoordinator.removeAsset(prepared.asset)
                    return
                }
                guard self.compressionRequestID == requestID else {
                    await self.photoIntakeCoordinator.removeAsset(prepared.asset)
                    return
                }

                self.photoAsset = prepared.asset
                self.photo = prepared.displayImage
                self.photoFingerprint = prepared.asset.fingerprint
                self.isCompressing = false
                self.scheduleDraftPersist()
                await self.photoIntakeCoordinator.removeAsset(previousAsset)
            } catch {
                guard !Task.isCancelled else { return }
                guard self.compressionRequestID == requestID else { return }
                self.isCompressing = false
            }
        }
    }

    private nonisolated static func makeUITestImage() -> UIImage {
        let size = CGSize(width: 1200, height: 900)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            UIColor(red: 0.95, green: 0.92, blue: 0.88, alpha: 1).setFill()
            context.fill(rect)

            UIColor(red: 0.82, green: 0.78, blue: 0.72, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: size.height * 0.62, width: size.width, height: size.height * 0.38))

            UIColor(red: 0.72, green: 0.68, blue: 0.62, alpha: 1).setFill()
            context.fill(CGRect(x: size.width * 0.14, y: size.height * 0.28, width: size.width * 0.72, height: size.height * 0.42))

            UIColor(red: 0.62, green: 0.58, blue: 0.52, alpha: 1).setFill()
            context.fill(CGRect(x: size.width * 0.22, y: size.height * 0.42, width: size.width * 0.18, height: size.height * 0.2))
        }
    }

    private nonisolated static func loadImportedPhotoData(from fileURL: URL) async throws -> Data {
        try await Task.detached(priority: .userInitiated) {
            try Data(contentsOf: fileURL)
        }.value
    }
}
