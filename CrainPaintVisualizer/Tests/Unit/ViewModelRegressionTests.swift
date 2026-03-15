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

actor StubReportsService: ReportsService {
    let reportsByOrderID: [String: MasterReport?]

    init(reportsByOrderID: [String: MasterReport?] = [:]) {
        self.reportsByOrderID = reportsByOrderID
    }

    func fetchReport(orderID: String) async throws -> MasterReport? {
        reportsByOrderID[orderID] ?? nil
    }
}

actor CountingColorCatalogProvider: ColorCatalogProviding {
    let brandIndices: [PaintBrand: ColorCatalogBrandIndex]
    let loadDelay: Duration
    let failingBrands: Set<PaintBrand>
    private(set) var requestedBrands: [PaintBrand] = []
    private(set) var loadCounts: [PaintBrand: Int] = [:]

    init(
        brandIndices: [PaintBrand: ColorCatalogBrandIndex],
        loadDelay: Duration = .milliseconds(40),
        failingBrands: Set<PaintBrand> = []
    ) {
        self.brandIndices = brandIndices
        self.loadDelay = loadDelay
        self.failingBrands = failingBrands
    }

    func loadBrandIndex(for brand: PaintBrand) async throws -> ColorCatalogBrandIndex {
        requestedBrands.append(brand)
        loadCounts[brand, default: 0] += 1
        try? await Task.sleep(for: loadDelay)

        if failingBrands.contains(brand) {
            throw NSError(domain: "ColorCatalogTests", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Synthetic brand load failure",
            ])
        }

        return brandIndices[brand] ?? .empty
    }

    func prewarm(brand: PaintBrand) async {
        _ = try? await loadBrandIndex(for: brand)
    }

    func recordedLoadCount(for brand: PaintBrand) -> Int {
        loadCounts[brand, default: 0]
    }

    func recordedRequestedBrands() -> [PaintBrand] {
        requestedBrands
    }
}

private struct StubColorMatchService: ColorMatchService {
    let result: Result<ColorMatchResponseData, Error>
    let delay: Duration

    init(
        result: Result<ColorMatchResponseData, Error> = .failure(ColorMatchServiceError.invalidSample),
        delay: Duration = .zero
    ) {
        self.result = result
        self.delay = delay
    }

    func match(
        image: UIImage,
        focusRect: ColorMatchFocusRect?,
        captureContext: ColorMatchCaptureContext?
    ) async throws -> ColorMatchResponseData {
        if delay > .zero {
            try? await Task.sleep(for: delay)
        }
        return try result.get()
    }
}

actor InMemoryProjectDraftStore: ProjectDraftStore {
    private var draft: ProjectDraft?
    private var legacyPhotoData: Data?

    init(draft: ProjectDraft? = nil, photo: UIImage? = nil, legacyPhotoData: Data? = nil) {
        self.draft = draft
        self.legacyPhotoData = legacyPhotoData ?? photo?.jpegData(compressionQuality: 0.9)
    }

    func loadDraft() async throws -> ProjectDraft? {
        draft
    }

    func loadLegacyDraftPhotoData(fileName: String?) async throws -> Data? {
        legacyPhotoData
    }

    func saveDraft(_ draft: ProjectDraft) async throws -> ProjectDraft {
        self.draft = draft
        return draft
    }

    func clearDraft() async throws {
        draft = nil
        legacyPhotoData = nil
    }

    func snapshotDraft() -> ProjectDraft? {
        draft
    }
}

actor InMemoryVisualizationLibraryStore: VisualizationLibraryStore {
    private var results: [VisualizationResult]

    init(results: [VisualizationResult] = []) {
        self.results = results
    }

    func loadResults() async throws -> [VisualizationResult] {
        results
    }

    func saveResults(_ results: [VisualizationResult]) async throws {
        self.results = results
    }

    func snapshotResults() -> [VisualizationResult] {
        results
    }
}

actor InMemoryRoomProjectStore: RoomProjectStore {
    private var library: RoomProjectLibrary
    private var legacyProjectPhotoData: Data?

    init(library: RoomProjectLibrary = RoomProjectLibrary(), activeProjectPhoto: UIImage? = nil) {
        self.library = library
        legacyProjectPhotoData = activeProjectPhoto?.jpegData(compressionQuality: 0.9)
    }

    func loadLibrary() async throws -> RoomProjectLibrary {
        library
    }

    func loadLegacyProjectPhotoData(fileName: String?) async throws -> Data? {
        legacyProjectPhotoData
    }

    func saveLibrary(_ library: RoomProjectLibrary) async throws -> RoomProjectLibrary {
        self.library = library
        return library
    }

    func clearLibrary() async throws {
        library = RoomProjectLibrary()
        legacyProjectPhotoData = nil
    }

    func snapshotLibrary() -> RoomProjectLibrary {
        library
    }
}

actor ControlledPhotoIntakeCoordinator: PhotoIntakeCoordinating {
    enum StubError: Error {
        case unsupported
    }

    private var pendingDataImports: [CheckedContinuation<PhotoIntakeResult, Error>] = []
    private var removedAssetIDs: [String] = []

    func importPhoto(
        _ importedPhoto: ImportedPhoto,
        displayMaxPixelSize: Int
    ) async throws -> PhotoIntakeResult {
        throw StubError.unsupported
    }

    func importPhotoData(
        _ data: Data,
        originalFileExtension: String,
        displayMaxPixelSize: Int,
        fingerprintOverride: String?
    ) async throws -> PhotoIntakeResult {
        try await withCheckedThrowingContinuation { continuation in
            pendingDataImports.append(continuation)
        }
    }

    func importImage(
        _ image: UIImage,
        originalFileExtension: String,
        displayMaxPixelSize: Int,
        fingerprintOverride: String?
    ) async throws -> PhotoIntakeResult {
        throw StubError.unsupported
    }

    func migrateLegacyPhotoData(
        _ data: Data,
        fileName: String?,
        fingerprint: String?
    ) async throws -> PhotoIntakeResult {
        throw StubError.unsupported
    }

    func loadDisplayImage(
        for reference: PhotoAssetReference?,
        maxPixelSize: Int
    ) async -> UIImage? {
        nil
    }

    func removeAsset(_ reference: PhotoAssetReference?) async {
        guard let reference else { return }
        removedAssetIDs.append(reference.id)
    }

    func completeMostRecentDataImport(with result: PhotoIntakeResult) {
        pendingDataImports.removeLast().resume(returning: result)
    }

    func completeOldestDataImport(with result: PhotoIntakeResult) {
        pendingDataImports.removeFirst().resume(returning: result)
    }

    func recordedRemovedAssetIDs() -> [String] {
        removedAssetIDs
    }

    func pendingDataImportCount() -> Int {
        pendingDataImports.count
    }
}

actor SnapshottingImportedPhotoCoordinator: PhotoIntakeCoordinating {
    enum StubError: Error {
        case unexpectedImportPhotoCall
    }

    private let result: PhotoIntakeResult
    private(set) var importedData: Data?
    private(set) var importedFileExtension: String?
    private(set) var importPhotoCallCount = 0

    init(result: PhotoIntakeResult) {
        self.result = result
    }

    func importPhoto(
        _ importedPhoto: ImportedPhoto,
        displayMaxPixelSize: Int
    ) async throws -> PhotoIntakeResult {
        importPhotoCallCount += 1
        throw StubError.unexpectedImportPhotoCall
    }

    func importPhotoData(
        _ data: Data,
        originalFileExtension: String,
        displayMaxPixelSize: Int,
        fingerprintOverride: String?
    ) async throws -> PhotoIntakeResult {
        importedData = data
        importedFileExtension = originalFileExtension
        return result
    }

    func importImage(
        _ image: UIImage,
        originalFileExtension: String,
        displayMaxPixelSize: Int,
        fingerprintOverride: String?
    ) async throws -> PhotoIntakeResult {
        throw StubError.unexpectedImportPhotoCall
    }

    func migrateLegacyPhotoData(
        _ data: Data,
        fileName: String?,
        fingerprint: String?
    ) async throws -> PhotoIntakeResult {
        throw StubError.unexpectedImportPhotoCall
    }

    func loadDisplayImage(
        for reference: PhotoAssetReference?,
        maxPixelSize: Int
    ) async -> UIImage? {
        result.displayImage
    }

    func removeAsset(_ reference: PhotoAssetReference?) async {}

    func recordedImportedData() -> Data? {
        importedData
    }

    func recordedImportedFileExtension() -> String? {
        importedFileExtension
    }

    func recordedImportPhotoCallCount() -> Int {
        importPhotoCallCount
    }
}

actor RecordingVisualizationService: VisualizationService {
    struct Call: Equatable {
        let colorID: String
        let surface: SurfaceType
        let customSurfaceText: String
        let roomName: String
    }

    private let assetsDirectory: URL
    private let generationDelay: Duration
    private var calls: [Call] = []

    init(assetsDirectory: URL, generationDelay: Duration = .zero) {
        self.assetsDirectory = assetsDirectory
        self.generationDelay = generationDelay
    }

    func generatePreview(
        color: PaintColor,
        photo: UIImage,
        surface: SurfaceType,
        customSurfaceText: String,
        roomName: String
    ) async throws -> VisualizationResult {
        calls.append(
            Call(
                colorID: color.id,
                surface: surface,
                customSurfaceText: customSurfaceText,
                roomName: roomName
            )
        )

        if generationDelay > .zero {
            try? await Task.sleep(for: generationDelay)
        }

        let id = "recorded-\(calls.count)-\(color.id)"
        let originalPath = try saveImage(photo, named: "\(id)-before-card.jpg")
        let afterPath = try saveImage(photo, named: "\(id)-after-card.jpg")

        return VisualizationResult(
            id: id,
            remoteVisualizationID: id,
            color: color,
            surface: surface.userFacingDescription(customSurfaceText: customSurfaceText),
            roomName: roomName,
            originalRemoteURL: "local://\(id)-before",
            resultRemoteURL: "local://\(id)-after",
            originalFullRemoteURL: nil,
            resultFullRemoteURL: nil,
            shareID: id,
            originalImagePath: originalPath,
            resultImagePath: afterPath,
            originalFullImagePath: nil,
            resultFullImagePath: nil,
            createdAt: .now
        )
    }

    func generatedColorIDs() -> [String] {
        calls.map(\.colorID)
    }

    private func saveImage(_ image: UIImage, named fileName: String) throws -> String {
        if !FileManager.default.fileExists(atPath: assetsDirectory.path) {
            try FileManager.default.createDirectory(at: assetsDirectory, withIntermediateDirectories: true)
        }

        let fileURL = assetsDirectory.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw VisualizationServiceError.invalidPhoto
        }
        try data.write(to: fileURL, options: .atomic)
        return fileURL.path
    }
}

@MainActor
final class ViewModelRegressionTests: XCTestCase {
    func testBootstrapMigratesLegacyDraftIntoRoomProjectLibrary() async throws {
        let assetDirectory = try makeTemporaryDirectory()
        let whiteDove = PaintColor(number: "OC-17", name: "White Dove", family: "White", hex: "F3EDE1", brand: .benjaminMoore)
        let legacyDraft = ProjectDraft(
            selectedBrand: .benjaminMoore,
            selectedColors: [whiteDove],
            selectedSurface: .walls,
            customSurfaceText: "",
            photoFileName: "legacy-room.jpg",
            photoFingerprint: "legacy-fingerprint"
        )
        let legacyPhoto = makeTestImage(fill: .systemTeal)
        let projectStore = InMemoryRoomProjectStore()
        let draftStore = InMemoryProjectDraftStore(draft: legacyDraft, photo: legacyPhoto)
        let libraryStore = InMemoryVisualizationLibraryStore()
        let service = RecordingVisualizationService(assetsDirectory: assetDirectory)

        let viewModel = await makeVisualizer(
            projectStore: projectStore,
            draftStore: draftStore,
            libraryStore: libraryStore,
            visualizationService: service
        )

        XCTAssertEqual(viewModel.projects.count, 1)
        XCTAssertEqual(viewModel.activeProjectID, "active-project")
        XCTAssertEqual(viewModel.selectedColors, [whiteDove])
        XCTAssertEqual(viewModel.selectedSurface, .walls)
        XCTAssertNotNil(viewModel.photo)

        let snapshot = await projectStore.snapshotLibrary()
        XCTAssertEqual(snapshot.activeProjectID, "active-project")
        XCTAssertEqual(snapshot.projects.first?.state, .directionSelected)
    }

    func testStartGenerationAssignsSavedResultToActiveRoomProject() async throws {
        let assetDirectory = try makeTemporaryDirectory()
        let whiteDove = PaintColor(number: "OC-17", name: "White Dove", family: "White", hex: "F3EDE1", brand: .benjaminMoore)
        let project = RoomProject(
            id: "room-123",
            title: "Living Room",
            photoFileName: "room-photo.jpg",
            selectedSurface: .walls,
            preferredBrand: .benjaminMoore,
            candidateColors: [whiteDove],
            state: .directionSelected,
            source: .new
        )
        let projectStore = InMemoryRoomProjectStore(
            library: RoomProjectLibrary(activeProjectID: "room-123", projects: [project]),
            activeProjectPhoto: makeTestImage(fill: .systemMint)
        )
        let draftStore = InMemoryProjectDraftStore()
        let libraryStore = InMemoryVisualizationLibraryStore()
        let service = RecordingVisualizationService(assetsDirectory: assetDirectory)
        let viewModel = await makeVisualizer(
            projectStore: projectStore,
            draftStore: draftStore,
            libraryStore: libraryStore,
            visualizationService: service
        )

        await viewModel.startGeneration()

        let renderedResult = try XCTUnwrap(viewModel.savedResults.first)
        XCTAssertEqual(renderedResult.projectID, "room-123")
        XCTAssertEqual(viewModel.projects.first?.visualizationIDs, [renderedResult.id])
        XCTAssertEqual(viewModel.projects.first?.selectedVisualizationID, renderedResult.id)
    }

    func testStartGenerationCreatesProcessingStateBeforeResultsReturn() async throws {
        let assetDirectory = try makeTemporaryDirectory()
        let service = RecordingVisualizationService(
            assetsDirectory: assetDirectory,
            generationDelay: .milliseconds(150)
        )
        let viewModel = await makeVisualizer(
            draftStore: InMemoryProjectDraftStore(),
            libraryStore: InMemoryVisualizationLibraryStore(),
            visualizationService: service
        )
        let whiteDove = PaintColor(number: "OC-17", name: "White Dove", family: "White", hex: "F3EDE1", brand: .benjaminMoore)
        let photoData = try XCTUnwrap(makeTestImage(fill: .systemTeal).jpegData(compressionQuality: 0.9))

        XCTAssertTrue(viewModel.addColor(whiteDove))
        viewModel.setSelectedSurface(.walls)
        viewModel.setPhoto(from: photoData)
        let photoReady = await waitForCondition {
            viewModel.photo != nil && !viewModel.isCompressing
        }
        XCTAssertTrue(photoReady)

        let generationTask = Task {
            await viewModel.startGeneration()
        }

        let processingStateAppeared = await waitForCondition {
            viewModel.currentJob != nil
                && viewModel.isCurrentJobProcessing
                && viewModel.currentJobTotalCount == 1
        }
        XCTAssertTrue(processingStateAppeared)
        XCTAssertEqual(viewModel.currentJobCompletedCount, 0)
        XCTAssertEqual(viewModel.projectProgressLabel, "Processing preview set")

        await generationTask.value

        XCTAssertFalse(viewModel.isCurrentJobProcessing)
        XCTAssertEqual(viewModel.currentJobCompletedCount, 1)
        XCTAssertEqual(viewModel.projectProgressLabel, "Preview ready")
    }

    func testHomeProjectStateTreatsPhotoOnlyDraftAsResumable() async throws {
        let assetDirectory = try makeTemporaryDirectory()
        let service = RecordingVisualizationService(assetsDirectory: assetDirectory)
        let photo = makeTestImage(fill: .systemTeal)
        let draft = ProjectDraft(photoFileName: "active-project-photo.jpg")
        let viewModel = await makeVisualizer(
            draftStore: InMemoryProjectDraftStore(draft: draft, photo: photo),
            libraryStore: InMemoryVisualizationLibraryStore(),
            visualizationService: service
        )

        XCTAssertEqual(viewModel.homeProjectState, .chooseSurface)
        XCTAssertEqual(viewModel.homePrimaryCTAButtonTitle, "Choose Surface")
        XCTAssertEqual(viewModel.resumeRoute, .surfacePicker)
        XCTAssertTrue(viewModel.showsHomeStartNewAction)
        XCTAssertEqual(
            viewModel.homeScreenSubtitle,
            "Continue your current draft or start a new preview."
        )
    }

    func testHomePrimaryCTAMatchesProjectStage() async throws {
        let assetDirectory = try makeTemporaryDirectory()
        let service = RecordingVisualizationService(assetsDirectory: assetDirectory)
        let viewModel = await makeVisualizer(
            draftStore: InMemoryProjectDraftStore(),
            libraryStore: InMemoryVisualizationLibraryStore(),
            visualizationService: service
        )
        let whiteDove = PaintColor(
            number: "OC-17",
            name: "White Dove",
            family: "White",
            hex: "F3EDE1",
            brand: .benjaminMoore
        )
        let readyResult = VisualizationResult(
            id: "home-ready-result",
            remoteVisualizationID: "remote-home-ready-result",
            color: whiteDove,
            surface: "Full Walls",
            roomName: "Current Room",
            originalRemoteURL: "local://before",
            resultRemoteURL: "local://after",
            originalFullRemoteURL: nil,
            resultFullRemoteURL: nil,
            shareID: "share-home-ready-result",
            originalImagePath: assetDirectory.appendingPathComponent("before.jpg").path,
            resultImagePath: assetDirectory.appendingPathComponent("after.jpg").path,
            originalFullImagePath: nil,
            resultFullImagePath: nil,
            createdAt: .now
        )

        XCTAssertEqual(viewModel.homeProjectState, .empty)
        XCTAssertEqual(viewModel.homePrimaryCTAButtonTitle, "Start with my room")
        XCTAssertEqual(viewModel.resumeRoute, .photoUpload)
        XCTAssertFalse(viewModel.showsHomeStartNewAction)

        let photoData = try XCTUnwrap(makeTestImage(fill: .systemBlue).jpegData(compressionQuality: 0.9))
        viewModel.setPhoto(from: photoData)
        let photoReady = await waitForCondition {
            viewModel.photo != nil && !viewModel.isCompressing
        }
        XCTAssertTrue(photoReady)
        XCTAssertEqual(viewModel.homeProjectState, .chooseSurface)
        XCTAssertEqual(viewModel.homePrimaryCTAButtonTitle, "Choose Surface")
        XCTAssertEqual(viewModel.resumeRoute, .surfacePicker)
        XCTAssertTrue(viewModel.showsHomeStartNewAction)

        viewModel.selectedSurface = .walls
        XCTAssertEqual(viewModel.homeProjectState, .chooseColors)
        XCTAssertEqual(viewModel.homePrimaryCTAButtonTitle, "Choose Colors")
        XCTAssertEqual(viewModel.resumeRoute, .itemPicker)

        viewModel.selectedColors = [whiteDove]
        XCTAssertEqual(viewModel.homeProjectState, .reviewDraft)
        XCTAssertEqual(viewModel.homePrimaryCTAButtonTitle, "Resume project")
        XCTAssertEqual(viewModel.resumeRoute, .projectReview)

        viewModel.currentJob = VisualizationJob(
            surfaceDescription: "Full Walls",
            roomName: "Current Room",
            items: [VisualizationJobItem(color: whiteDove, state: .completed(readyResult))]
        )
        let activeProjectID = try XCTUnwrap(viewModel.activeProjectID)
        XCTAssertEqual(viewModel.homeProjectState, .resultsReady)
        XCTAssertEqual(viewModel.homePrimaryCTAButtonTitle, "Resume project")
        XCTAssertEqual(viewModel.resumeRoute, .results(projectID: activeProjectID))
        XCTAssertTrue(viewModel.showsHomeStartNewAction)

        viewModel.currentJob = VisualizationJob(
            surfaceDescription: "Full Walls",
            roomName: "Current Room",
            items: [VisualizationJobItem(color: whiteDove, state: .generating)]
        )
        XCTAssertEqual(viewModel.homeProjectState, .processing)
        XCTAssertEqual(viewModel.homePrimaryCTAButtonTitle, "Resume project")
        XCTAssertEqual(viewModel.resumeRoute, .results(projectID: activeProjectID))
        XCTAssertFalse(viewModel.showsHomeStartNewAction)
    }

    func testResetClearsDraftButKeepsSavedVisualizations() async throws {
        let assetDirectory = try makeTemporaryDirectory()
        let service = RecordingVisualizationService(assetsDirectory: assetDirectory)
        let photo = makeTestImage(fill: .systemGreen)
        let whiteDove = PaintColor(
            number: "OC-17",
            name: "White Dove",
            family: "White",
            hex: "F3EDE1",
            brand: .benjaminMoore
        )
        let savedResult = VisualizationResult(
            id: "saved-home-reset",
            remoteVisualizationID: "remote-saved-home-reset",
            color: whiteDove,
            surface: "Full Walls",
            roomName: "Current Room",
            originalRemoteURL: "local://before",
            resultRemoteURL: "local://after",
            originalFullRemoteURL: nil,
            resultFullRemoteURL: nil,
            shareID: "share-saved-home-reset",
            originalImagePath: assetDirectory.appendingPathComponent("saved-before.jpg").path,
            resultImagePath: assetDirectory.appendingPathComponent("saved-after.jpg").path,
            originalFullImagePath: nil,
            resultFullImagePath: nil,
            createdAt: .now
        )
        let seededDraft = ProjectDraft(
            selectedBrand: .benjaminMoore,
            selectedColors: [whiteDove],
            selectedSurface: .walls,
            customSurfaceText: "",
            photoFileName: "active-project-photo.jpg"
        )
        let draftStore = InMemoryProjectDraftStore(draft: seededDraft, photo: photo)
        let libraryStore = InMemoryVisualizationLibraryStore(results: [savedResult])
        let viewModel = await makeVisualizer(
            draftStore: draftStore,
            libraryStore: libraryStore,
            visualizationService: service
        )

        viewModel.reset()

        let draftCleared = await waitForAsyncCondition(timeout: .seconds(1)) {
            await draftStore.snapshotDraft() == nil
        }

        XCTAssertTrue(draftCleared)
        let preservedResult = try XCTUnwrap(viewModel.savedResults.first)
        XCTAssertEqual(viewModel.savedResults.count, 1)
        XCTAssertEqual(preservedResult.id, savedResult.id)
        XCTAssertEqual(preservedResult.projectID, "legacy-project-1")
        XCTAssertTrue(viewModel.selectedColors.isEmpty)
        XCTAssertNil(viewModel.photo)
        XCTAssertNil(viewModel.selectedSurface)
        XCTAssertEqual(viewModel.homeProjectState, .empty)
    }

    func testAddingColorAfterRelaunchReusesCompletedResultAndOnlyGeneratesNewColor() async throws {
        let assetDirectory = try makeTemporaryDirectory()
        let service = RecordingVisualizationService(assetsDirectory: assetDirectory)
        let draftStore = InMemoryProjectDraftStore()
        let libraryStore = InMemoryVisualizationLibraryStore()
        let firstViewModel = await makeVisualizer(
            draftStore: draftStore,
            libraryStore: libraryStore,
            visualizationService: service
        )
        let whiteDove = PaintColor(number: "OC-17", name: "White Dove", family: "White", hex: "F3EDE1", brand: .benjaminMoore)
        let haleNavy = PaintColor(number: "2163-10", name: "Hale Navy", family: "Blue", hex: "3C4659", brand: .benjaminMoore)
        let photoData = try XCTUnwrap(makeTestImage(fill: .systemTeal).jpegData(compressionQuality: 0.9))

        XCTAssertTrue(firstViewModel.addColor(whiteDove))
        firstViewModel.setSelectedSurface(.walls)
        firstViewModel.setPhoto(from: photoData)
        let firstPhotoReady = await waitForCondition {
            firstViewModel.photo != nil && !firstViewModel.isCompressing
        }
        XCTAssertTrue(firstPhotoReady)

        await firstViewModel.startGeneration()
        let firstGeneratedColorIDs = await service.generatedColorIDs()
        XCTAssertEqual(firstGeneratedColorIDs, [whiteDove.id])

        let draftPersisted = await waitForAsyncCondition(timeout: .seconds(1)) {
            guard let draft = await draftStore.snapshotDraft() else { return false }
            return draft.photoFingerprint != nil
                && draft.selectedColors == [whiteDove]
                && draft.selectedSurface == .walls
        }
        XCTAssertTrue(draftPersisted)
        let libraryPersisted = await waitForAsyncCondition(timeout: .seconds(1)) {
            let results = await libraryStore.snapshotResults()
            return results.count == 1 && results.first?.requestFingerprint != nil
        }
        XCTAssertTrue(libraryPersisted)

        let relaunchedViewModel = await makeVisualizer(
            draftStore: draftStore,
            libraryStore: libraryStore,
            visualizationService: service
        )
        XCTAssertEqual(relaunchedViewModel.selectedColors, [whiteDove])
        XCTAssertEqual(relaunchedViewModel.selectedSurface, .walls)
        XCTAssertNotNil(relaunchedViewModel.photo)

        XCTAssertTrue(relaunchedViewModel.addColor(haleNavy))
        await relaunchedViewModel.startGeneration()

        let relaunchedGeneratedColorIDs = await service.generatedColorIDs()
        XCTAssertEqual(relaunchedGeneratedColorIDs, [whiteDove.id, haleNavy.id])
        XCTAssertEqual(relaunchedViewModel.currentJob?.items.count, 2)
        XCTAssertTrue(relaunchedViewModel.currentJob?.items.allSatisfy(\.isCompleted) ?? false)
    }

    func testRestoreDraftFromSavedVisualizationRecoversEditableProjectState() async throws {
        let assetDirectory = try makeTemporaryDirectory()
        let beforeImage = makeTestImage(fill: .systemIndigo)
        let beforeImageURL = assetDirectory.appendingPathComponent("restore-before.jpg")
        try XCTUnwrap(beforeImage.jpegData(compressionQuality: 0.9)).write(to: beforeImageURL)
        let draftStore = InMemoryProjectDraftStore()

        let viewModel = await makeVisualizer(
            draftStore: draftStore,
            libraryStore: InMemoryVisualizationLibraryStore(),
            visualizationService: RecordingVisualizationService(assetsDirectory: assetDirectory)
        )
        viewModel.currentJob = VisualizationJob(
            surfaceDescription: "Full Walls",
            roomName: "Current Room",
            items: [VisualizationJobItem(color: PaintColor(number: "OC-17", name: "White Dove", family: "White", hex: "F3EDE1", brand: .benjaminMoore))]
        )

        let visualization = Visualization(
            id: "saved-design-card",
            remoteVisualizationID: "saved-design-card",
            colorName: "White Dove",
            colorHex: "F3EDE1",
            colorCode: "OC-17",
            roomName: "Mudroom",
            beforeImagePath: beforeImageURL.path,
            afterImagePath: beforeImageURL.path,
            originalURL: "local://before",
            resultURL: "local://after",
            shareID: "saved-design-card",
            surface: "Mudroom Bench",
            createdAt: .now
        )

        await viewModel.restoreDraft(from: visualization)

        XCTAssertNil(viewModel.currentJob)
        XCTAssertEqual(viewModel.selectedBrand, .benjaminMoore)
        XCTAssertEqual(viewModel.selectedColors, [visualization.asPaintColor])
        XCTAssertEqual(viewModel.selectedSurface, .custom)
        XCTAssertEqual(viewModel.customSurfaceText, "Mudroom Bench")
        XCTAssertNotNil(viewModel.photo)
        XCTAssertEqual(viewModel.homeProjectState, .reviewDraft)

        let draftPersisted = await waitForAsyncCondition(timeout: .seconds(1)) {
            guard let draft = await draftStore.snapshotDraft() else { return false }
            return draft.selectedColors == [visualization.asPaintColor]
                && draft.selectedSurface == .custom
                && draft.customSurfaceText == "Mudroom Bench"
                && draft.photoFingerprint != nil
        }
        XCTAssertTrue(draftPersisted)
    }

    func testAllSelectedColorsReuseCachedResultsWithoutCallingService() async throws {
        let assetDirectory = try makeTemporaryDirectory()
        let service = RecordingVisualizationService(assetsDirectory: assetDirectory)
        let libraryStore = InMemoryVisualizationLibraryStore()
        let viewModel = await makeVisualizer(
            draftStore: InMemoryProjectDraftStore(),
            libraryStore: libraryStore,
            visualizationService: service
        )
        let photo = makeTestImage(fill: .systemOrange)
        let whiteDove = PaintColor(number: "OC-17", name: "White Dove", family: "White", hex: "F3EDE1", brand: .benjaminMoore)
        let haleNavy = PaintColor(number: "2163-10", name: "Hale Navy", family: "Blue", hex: "3C4659", brand: .benjaminMoore)

        viewModel.photo = photo
        viewModel.selectedSurface = .walls
        viewModel.selectedColors = [whiteDove, haleNavy]

        let cachedResults = try [
            makeCachedResult(
                in: assetDirectory,
                id: "cached-\(whiteDove.id)",
                photo: photo,
                color: whiteDove,
                surface: .walls,
                customSurfaceText: "",
                roomName: viewModel.currentRoomName,
                requestFingerprint: makeRequestFingerprint(photo: photo, color: whiteDove, surface: .walls, customSurfaceText: "")
            ),
            makeCachedResult(
                in: assetDirectory,
                id: "cached-\(haleNavy.id)",
                photo: photo,
                color: haleNavy,
                surface: .walls,
                customSurfaceText: "",
                roomName: viewModel.currentRoomName,
                requestFingerprint: makeRequestFingerprint(photo: photo, color: haleNavy, surface: .walls, customSurfaceText: "")
            ),
        ]
        viewModel.savedResults = cachedResults

        await viewModel.startGeneration()

        let reusedGeneratedColorIDs = await service.generatedColorIDs()
        XCTAssertEqual(reusedGeneratedColorIDs, [])
        XCTAssertEqual(viewModel.currentJob?.items.count, 2)
        XCTAssertTrue(viewModel.currentJob?.items.allSatisfy(\.isCompleted) ?? false)
    }

    func testChangingPhotoInvalidatesCachedResult() async throws {
        let assetDirectory = try makeTemporaryDirectory()
        let service = RecordingVisualizationService(assetsDirectory: assetDirectory)
        let viewModel = await makeVisualizer(
            draftStore: InMemoryProjectDraftStore(),
            libraryStore: InMemoryVisualizationLibraryStore(),
            visualizationService: service
        )
        let originalPhoto = makeTestImage(fill: .systemBlue)
        let changedPhoto = makeTestImage(fill: .systemGreen)
        let whiteDove = PaintColor(number: "OC-17", name: "White Dove", family: "White", hex: "F3EDE1", brand: .benjaminMoore)

        viewModel.savedResults = try [
            makeCachedResult(
                in: assetDirectory,
                id: "cached-photo-miss",
                photo: originalPhoto,
                color: whiteDove,
                surface: .walls,
                customSurfaceText: "",
                roomName: "Current Room",
                requestFingerprint: makeRequestFingerprint(photo: originalPhoto, color: whiteDove, surface: .walls, customSurfaceText: "")
            ),
        ]
        viewModel.photo = changedPhoto
        viewModel.selectedSurface = .walls
        viewModel.selectedColors = [whiteDove]

        await viewModel.startGeneration()

        let photoMissGeneratedColorIDs = await service.generatedColorIDs()
        XCTAssertEqual(photoMissGeneratedColorIDs, [whiteDove.id])
    }

    func testChangingSurfaceInvalidatesCachedResult() async throws {
        let assetDirectory = try makeTemporaryDirectory()
        let service = RecordingVisualizationService(assetsDirectory: assetDirectory)
        let viewModel = await makeVisualizer(
            draftStore: InMemoryProjectDraftStore(),
            libraryStore: InMemoryVisualizationLibraryStore(),
            visualizationService: service
        )
        let photo = makeTestImage(fill: .systemPurple)
        let whiteDove = PaintColor(number: "OC-17", name: "White Dove", family: "White", hex: "F3EDE1", brand: .benjaminMoore)

        viewModel.savedResults = try [
            makeCachedResult(
                in: assetDirectory,
                id: "cached-surface-miss",
                photo: photo,
                color: whiteDove,
                surface: .walls,
                customSurfaceText: "",
                roomName: "Current Room",
                requestFingerprint: makeRequestFingerprint(photo: photo, color: whiteDove, surface: .walls, customSurfaceText: "")
            ),
        ]
        viewModel.photo = photo
        viewModel.selectedSurface = .cabinets
        viewModel.selectedColors = [whiteDove]

        await viewModel.startGeneration()

        let surfaceMissGeneratedColorIDs = await service.generatedColorIDs()
        XCTAssertEqual(surfaceMissGeneratedColorIDs, [whiteDove.id])
    }

    func testEquivalentNormalizedCustomInstructionReusesCachedResult() async throws {
        let assetDirectory = try makeTemporaryDirectory()
        let service = RecordingVisualizationService(assetsDirectory: assetDirectory)
        let viewModel = await makeVisualizer(
            draftStore: InMemoryProjectDraftStore(),
            libraryStore: InMemoryVisualizationLibraryStore(),
            visualizationService: service
        )
        let photo = makeTestImage(fill: .systemYellow)
        let whiteDove = PaintColor(number: "OC-17", name: "White Dove", family: "White", hex: "F3EDE1", brand: .benjaminMoore)
        let cachedText = "  accent wall behind {TV}\n"
        let activeText = "accent wall behind TV"

        viewModel.savedResults = try [
            makeCachedResult(
                in: assetDirectory,
                id: "cached-custom-hit",
                photo: photo,
                color: whiteDove,
                surface: .custom,
                customSurfaceText: cachedText,
                roomName: "Current Room",
                requestFingerprint: makeRequestFingerprint(photo: photo, color: whiteDove, surface: .custom, customSurfaceText: cachedText)
            ),
        ]
        viewModel.photo = photo
        viewModel.selectedSurface = .custom
        viewModel.customSurfaceText = activeText
        viewModel.selectedColors = [whiteDove]

        await viewModel.startGeneration()

        let normalizedCustomInstructionGeneratedColorIDs = await service.generatedColorIDs()
        XCTAssertEqual(normalizedCustomInstructionGeneratedColorIDs, [])
        XCTAssertTrue(viewModel.currentJob?.items.allSatisfy(\.isCompleted) ?? false)
    }

    func testChangingNormalizedCustomInstructionInvalidatesCachedResult() async throws {
        let assetDirectory = try makeTemporaryDirectory()
        let service = RecordingVisualizationService(assetsDirectory: assetDirectory)
        let viewModel = await makeVisualizer(
            draftStore: InMemoryProjectDraftStore(),
            libraryStore: InMemoryVisualizationLibraryStore(),
            visualizationService: service
        )
        let photo = makeTestImage(fill: .systemPink)
        let whiteDove = PaintColor(number: "OC-17", name: "White Dove", family: "White", hex: "F3EDE1", brand: .benjaminMoore)

        viewModel.savedResults = try [
            makeCachedResult(
                in: assetDirectory,
                id: "cached-custom-miss",
                photo: photo,
                color: whiteDove,
                surface: .custom,
                customSurfaceText: "accent wall behind TV",
                roomName: "Current Room",
                requestFingerprint: makeRequestFingerprint(photo: photo, color: whiteDove, surface: .custom, customSurfaceText: "accent wall behind TV")
            ),
        ]
        viewModel.photo = photo
        viewModel.selectedSurface = .custom
        viewModel.customSurfaceText = "kitchen island"
        viewModel.selectedColors = [whiteDove]

        await viewModel.startGeneration()

        let changedCustomInstructionGeneratedColorIDs = await service.generatedColorIDs()
        XCTAssertEqual(changedCustomInstructionGeneratedColorIDs, [whiteDove.id])
    }

    func testMissingLocalAssetFilesTriggerRegeneration() async throws {
        let assetDirectory = try makeTemporaryDirectory()
        let service = RecordingVisualizationService(assetsDirectory: assetDirectory)
        let viewModel = await makeVisualizer(
            draftStore: InMemoryProjectDraftStore(),
            libraryStore: InMemoryVisualizationLibraryStore(),
            visualizationService: service
        )
        let photo = makeTestImage(fill: .brown)
        let whiteDove = PaintColor(number: "OC-17", name: "White Dove", family: "White", hex: "F3EDE1", brand: .benjaminMoore)
        let cachedResult = try makeCachedResult(
            in: assetDirectory,
            id: "cached-missing-assets",
            photo: photo,
            color: whiteDove,
            surface: .walls,
            customSurfaceText: "",
            roomName: "Current Room",
            requestFingerprint: makeRequestFingerprint(photo: photo, color: whiteDove, surface: .walls, customSurfaceText: "")
        )
        try FileManager.default.removeItem(atPath: cachedResult.resultImagePath)

        viewModel.savedResults = [cachedResult]
        viewModel.photo = photo
        viewModel.selectedSurface = .walls
        viewModel.selectedColors = [whiteDove]

        await viewModel.startGeneration()

        let missingAssetGeneratedColorIDs = await service.generatedColorIDs()
        XCTAssertEqual(missingAssetGeneratedColorIDs, [whiteDove.id])
    }

    func testLegacySavedResultWithoutFingerprintDoesNotReuse() async throws {
        let assetDirectory = try makeTemporaryDirectory()
        let service = RecordingVisualizationService(assetsDirectory: assetDirectory)
        let viewModel = await makeVisualizer(
            draftStore: InMemoryProjectDraftStore(),
            libraryStore: InMemoryVisualizationLibraryStore(),
            visualizationService: service
        )
        let photo = makeTestImage(fill: .cyan)
        let whiteDove = PaintColor(number: "OC-17", name: "White Dove", family: "White", hex: "F3EDE1", brand: .benjaminMoore)

        viewModel.savedResults = try [
            makeCachedResult(
                in: assetDirectory,
                id: "cached-legacy",
                photo: photo,
                color: whiteDove,
                surface: .walls,
                customSurfaceText: "",
                roomName: "Current Room",
                requestFingerprint: nil
            ),
        ]
        viewModel.photo = photo
        viewModel.selectedSurface = .walls
        viewModel.selectedColors = [whiteDove]

        await viewModel.startGeneration()

        let legacyGeneratedColorIDs = await service.generatedColorIDs()
        XCTAssertEqual(legacyGeneratedColorIDs, [whiteDove.id])
    }

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

    func testTrackedPendingReportBeforeLoadCompletesSurvivesLoadedReports() async {
        let persistedReport = makeReport(id: "report_saved", createdAt: .now.addingTimeInterval(-300))
        let store = DelayedReportStore(initialReports: [persistedReport])
        let viewModel = ReportsViewModel(store: store)

        let createdReport = viewModel.trackPendingReport(
            orderID: "order_inflight",
            consultationFlow: ConsultationFlowState()
        )

        let merged = await waitForCondition {
            viewModel.report(for: createdReport.id) != nil &&
            viewModel.report(for: persistedReport.id) != nil
        }

        XCTAssertTrue(merged)
    }

    func testTrackedPendingReportCarriesConsultationFlowContext() {
        let selectedColor = PaintColor(
            number: "OC-17",
            name: "White Dove",
            family: "White",
            hex: "F3EDE1",
            brand: .benjaminMoore
        )
        let flowState = ConsultationFlowState(
            id: "consult-flow-123",
            sourceProjectID: "project-42",
            sourceVisualizationID: nil,
            sourceColor: selectedColor,
            sourceRoomName: "Dining Room",
            packageType: .videoConsultation
        )
        let viewModel = ReportsViewModel(
            store: DelayedReportStore(initialReports: []),
            reportsService: StubReportsService()
        )

        let report = viewModel.trackPendingReport(
            orderID: "order_987",
            consultationFlow: flowState
        )

        XCTAssertEqual(report.id, "order_987")
        XCTAssertEqual(report.orderID, "order_987")
        XCTAssertEqual(report.projectID, "project-42")
        XCTAssertEqual(report.title, "Dining Room Consultation")
        XCTAssertEqual(report.packageType, .videoConsultation)
        XCTAssertEqual(report.videoThumbnailName, "HowItWorksHero")
        XCTAssertEqual(report.recommendations, [])
        XCTAssertEqual(viewModel.report(for: "order_987")?.projectID, "project-42")
    }

    func testMakeConsultationFlowStateFallsBackToActiveProjectContextWhenVisualizationMissing() async throws {
        let assetDirectory = try makeTemporaryDirectory()
        let selectedColor = PaintColor(
            number: "OC-17",
            name: "White Dove",
            family: "White",
            hex: "F3EDE1",
            brand: .benjaminMoore
        )
        let project = RoomProject(
            id: "project-123",
            title: "Living Room",
            photoFileName: "living-room.jpg",
            selectedSurface: .walls,
            preferredBrand: .benjaminMoore,
            candidateColors: [selectedColor],
            state: .directionSelected
        )
        let viewModel = await makeVisualizer(
            projectStore: InMemoryRoomProjectStore(
                library: RoomProjectLibrary(activeProjectID: project.id, projects: [project])
            ),
            draftStore: InMemoryProjectDraftStore(),
            libraryStore: InMemoryVisualizationLibraryStore(),
            visualizationService: RecordingVisualizationService(assetsDirectory: assetDirectory)
        )
        viewModel.selectedSurface = .walls
        viewModel.selectedColors = [selectedColor]

        let flowState = viewModel.makeConsultationFlowState(from: nil)

        XCTAssertEqual(flowState.sourceProjectID, "project-123")
        XCTAssertNil(flowState.sourceVisualizationID)
        XCTAssertEqual(flowState.sourceRoomName, "Current Room")
        XCTAssertEqual(flowState.sourceColor, selectedColor)
        XCTAssertEqual(flowState.packageType, .videoConsultation)
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
            confidence: 98,
            rationale: "Closest shortlist match."
        )
        let response = ColorMatchResponseData(
            sampleHex: "A4AE9F",
            quality: .good,
            warnings: [],
            diagnostics: .empty,
            matchMethod: .deterministicFallback,
            matches: [fallbackMatch]
        )
        let viewModel = ColorMatcherViewModel(service: StubColorMatchService(result: .success(response)))

        let accepted = viewModel.setSample(image: UIImage())

        XCTAssertFalse(accepted)
        XCTAssertFalse(viewModel.hasSample)
        XCTAssertEqual(viewModel.matches, [])
        XCTAssertEqual(viewModel.state, .error("Couldn’t read a clear color from that photo. Try centering the sample and using even light."))
    }

    func testValidColorSampleEntersSampleLockedStateAndStoresCropPreview() {
        let viewModel = ColorMatcherViewModel(
            service: StubColorMatchService(),
            timing: .immediate
        )
        let image = makeSolidTestImage(fill: UIColor(red: 0.76, green: 0.07, blue: 0.46, alpha: 1))

        let accepted = viewModel.setSample(
            image: image,
            focusRect: ColorMatchFocusRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
        )

        XCTAssertTrue(accepted)
        XCTAssertTrue(viewModel.hasSample)
        XCTAssertEqual(viewModel.state, .sampleLocked)
        XCTAssertNotNil(viewModel.sampleCropImage)
    }

    func testColorAnalysisTransitionsThroughAnalyzingPhasesBeforeResults() async {
        let hotLips = ColorMatchResult(
            id: "benjamin_moore-2077-30",
            color: PaintColor(
                number: "2077-30",
                name: "Hot Lips",
                family: "Pink",
                hex: "BE4A8B",
                brand: .benjaminMoore
            ),
            confidence: 85,
            rationale: "Closest match."
        )
        let response = ColorMatchResponseData(
            sampleHex: "C11276",
            quality: .mixed,
            warnings: ["Visible variation in the sample may soften the match."],
            diagnostics: .empty,
            matchMethod: .deterministicFallback,
            matches: [hotLips]
        )
        let viewModel = ColorMatcherViewModel(
            service: StubColorMatchService(result: .success(response), delay: .milliseconds(220)),
            timing: ColorMatcherTiming(
                captureConfirmationDuration: .zero,
                analysisPhaseDuration: .milliseconds(70),
                resultRevealInterval: .zero
            )
        )
        let image = makeSolidTestImage(fill: UIColor(red: 0.76, green: 0.07, blue: 0.46, alpha: 1))

        XCTAssertTrue(viewModel.setSample(image: image))

        viewModel.analyzeColor()

        let enteredAnalyzing = await waitForCondition(timeout: .milliseconds(120)) {
            if case .analyzing = viewModel.state {
                return true
            }
            return false
        }
        XCTAssertTrue(enteredAnalyzing)

        let advancedPhase = await waitForCondition(timeout: .milliseconds(200)) {
            viewModel.analysisPhase == .comparingCatalogs || viewModel.analysisPhase == .rankingMatches
        }
        XCTAssertTrue(advancedPhase)

        let reachedResults = await waitForCondition(timeout: .milliseconds(600)) {
            viewModel.state == .results && viewModel.matches == [hotLips]
        }
        XCTAssertTrue(reachedResults)
    }

    func testColorAnalysisWithEmptyMatchesTransitionsToNeedsRetake() async {
        let response = ColorMatchResponseData(
            sampleHex: "C11276",
            quality: .mixed,
            warnings: [],
            diagnostics: .empty,
            matchMethod: .deterministicFallback,
            matches: []
        )
        let viewModel = ColorMatcherViewModel(
            service: StubColorMatchService(result: .success(response)),
            timing: .immediate
        )
        let image = makeSolidTestImage(fill: UIColor(red: 0.76, green: 0.07, blue: 0.46, alpha: 1))

        XCTAssertTrue(viewModel.setSample(image: image))

        viewModel.analyzeColor()

        let movedToNeedsRetake = await waitForCondition {
            viewModel.state == .needsRetake
        }
        XCTAssertTrue(movedToNeedsRetake)
    }

    func testColorAnalysisFailureTransitionsToError() async {
        let viewModel = ColorMatcherViewModel(
            service: StubColorMatchService(result: .failure(ColorMatchServiceError.serverMessage("Synthetic failure"))),
            timing: .immediate
        )
        let image = makeSolidTestImage(fill: UIColor(red: 0.76, green: 0.07, blue: 0.46, alpha: 1))

        XCTAssertTrue(viewModel.setSample(image: image))

        viewModel.analyzeColor()

        let movedToError = await waitForCondition {
            viewModel.state == .error("Synthetic failure")
        }
        XCTAssertTrue(movedToError)
    }

    func testSupportedBrandsIncludeFarrowBallAndExcludeBehrFromCatalogFlow() {
        XCTAssertEqual(
            PaintBrand.supportedCases.map(\.rawValue),
            ["benjamin_moore", "sherwin_williams", "farrow_ball"]
        )
        XCTAssertEqual(
            ColorCatalogViewModel.availableBrands.map(\.rawValue),
            ["benjamin_moore", "sherwin_williams", "farrow_ball"]
        )
    }

    func testCompactWordmarkMetricsOpticallyNormalizeBrandMarks() {
        let benjamin = PaintBrand.benjaminMoore.wordmarkMetrics(for: .compact)
        let sherwin = PaintBrand.sherwinWilliams.wordmarkMetrics(for: .compact)
        let farrow = PaintBrand.farrowBall.wordmarkMetrics(for: .compact)

        XCTAssertGreaterThan(sherwin.scale, benjamin.scale)
        XCTAssertGreaterThan(farrow.horizontalPadding, benjamin.horizontalPadding)
        XCTAssertGreaterThan(farrow.horizontalPadding, sherwin.horizontalPadding)
    }

    func testCardWordmarkMetricsGiveMarksMoreBreathingRoomThanCompactStyle() {
        let compact = PaintBrand.benjaminMoore.wordmarkMetrics(for: .compact)
        let card = PaintBrand.benjaminMoore.wordmarkMetrics(for: .card)

        XCTAssertGreaterThan(card.horizontalPadding, compact.horizontalPadding)
        XCTAssertGreaterThan(card.verticalPadding, compact.verticalPadding)
    }

    func testCatalogLoaderDecodesBundledJSONShapeIntoPaintColors() throws {
        let url = try writeTemporaryCatalogJSON(
            """
            [
              { "number": "SW 7005", "name": "Pure White", "family": "White", "hex": "F5F2E8" },
              { "number": "SW 6244", "name": "Naval", "family": "Blue", "hex": "2E384D" }
            ]
            """
        )

        let colors = try ColorCatalogViewModel.loadCatalog(from: url, brand: .sherwinWilliams)

        XCTAssertEqual(colors.map(\.number), ["SW 7005", "SW 6244"])
        XCTAssertEqual(colors.map(\.brand), [.sherwinWilliams, .sherwinWilliams])
        XCTAssertEqual(colors.map(\.hex), ["F5F2E8", "2E384D"])
    }

    func testCatalogLoaderDecodesFarrowBallCatalogEntries() throws {
        let farrowBall = try XCTUnwrap(PaintBrand(rawValue: "farrow_ball"))
        let url = try writeTemporaryCatalogJSON(
            """
            [
              { "number": "No. 30", "name": "Hague Blue", "family": "Blue", "hex": "3F4D57" },
              { "number": "No. 26", "name": "Down Pipe", "family": "Gray", "hex": "676A6C" }
            ]
            """
        )

        let colors = try ColorCatalogViewModel.loadCatalog(from: url, brand: farrowBall)

        XCTAssertEqual(colors.map(\.number), ["No. 30", "No. 26"])
        XCTAssertEqual(colors.map(\.brand), [farrowBall, farrowBall])
        XCTAssertEqual(colors.map(\.hex), ["3F4D57", "676A6C"])
    }

    func testFarrowBallColorsWithSharedNumbersRemainUniquelyIdentifiable() throws {
        let farrowBall = try XCTUnwrap(PaintBrand(rawValue: "farrow_ball"))

        let offWhite = PaintColor(number: "No. 3", name: "Off-White", family: "White", hex: "F2EEE7", brand: farrowBall)
        let shallot = PaintColor(number: "No. 3", name: "Shallot", family: "Brown", hex: "B78462", brand: farrowBall)

        XCTAssertNotEqual(offWhite.id, shallot.id)
        XCTAssertNotEqual(offWhite, shallot)
    }

    func testPopularSearchAndAllFiltersRespectFarrowBallBrand() async throws {
        let farrowBall = try XCTUnwrap(PaintBrand(rawValue: "farrow_ball"))
        let hagueBlue = PaintColor(number: "No. 30", name: "Hague Blue", family: "Blue", hex: "3F4D57", brand: farrowBall)
        let downPipe = PaintColor(number: "No. 26", name: "Down Pipe", family: "Gray", hex: "676A6C", brand: farrowBall)
        let lampRoomGray = PaintColor(number: "No. 88", name: "Lamp Room Gray", family: "Gray", hex: "B2B5B0", brand: farrowBall)
        let whiteDove = PaintColor(number: "OC-17", name: "White Dove", family: "White", hex: "F3EDE1", brand: .benjaminMoore)

        let farrowColors = [hagueBlue, downPipe, lampRoomGray]
        let farrowFamilyCounts = Dictionary(grouping: farrowColors, by: \.family)
            .map { ColorCatalogFamilyCount(family: $0.key, count: $0.value.count) }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.family < rhs.family
                }
                return lhs.count > rhs.count
            }
        var brandIndices = makeBrandIndices(from: [hagueBlue, downPipe, lampRoomGray, whiteDove])
        brandIndices[farrowBall] = ColorCatalogBrandIndex(
            allColors: farrowColors,
            searchEntries: farrowColors.map(ColorCatalogSearchEntry.init),
            popularColors: [hagueBlue, downPipe],
            familyCounts: farrowFamilyCounts
        )
        let provider = CountingColorCatalogProvider(
            brandIndices: brandIndices
        )
        let viewModel = ColorCatalogViewModel(
            catalogProvider: provider,
            popularColorsByBrand: [
                .benjaminMoore: [whiteDove],
                .sherwinWilliams: [],
                farrowBall: [hagueBlue, downPipe],
            ]
        )

        viewModel.selectedBrand = farrowBall
        await viewModel.loadIfNeeded()

        let popularLoaded = await waitForCondition {
            viewModel.filteredColors.map(\.number) == ["No. 30", "No. 26"]
        }
        XCTAssertTrue(popularLoaded)

        viewModel.searchText = "lamp"

        let searchLoaded = await waitForCondition {
            viewModel.filteredColors.map(\.number) == ["No. 88"]
        }
        XCTAssertTrue(searchLoaded)

        viewModel.searchText = ""
        viewModel.selectedFilter = .all

        let allLoaded = await waitForCondition {
            viewModel.filteredColors.map(\.number) == ["No. 30", "No. 26", "No. 88"]
        }
        XCTAssertTrue(allLoaded)
    }

    func testSelectedBrandPopularColorsAppearBeforeFullCatalogLoadCompletes() async {
        let whiteDove = PaintColor(number: "OC-17", name: "White Dove", family: "White", hex: "F3EDE1", brand: .benjaminMoore)
        let reverePewter = PaintColor(number: "HC-172", name: "Revere Pewter", family: "Neutral", hex: "CCC1AE", brand: .benjaminMoore)
        let provider = CountingColorCatalogProvider(
            brandIndices: makeBrandIndices(from: [whiteDove, reverePewter]),
            loadDelay: .milliseconds(220)
        )
        let viewModel = ColorCatalogViewModel(
            catalogProvider: provider,
            popularColorsByBrand: [
                .benjaminMoore: [whiteDove, reverePewter],
                .sherwinWilliams: [],
            ]
        )

        let loadTask = Task {
            await viewModel.loadIfNeeded()
        }

        let shellVisible = await waitForCondition(timeout: .milliseconds(120)) {
            viewModel.filteredColors.map(\.number) == ["OC-17", "HC-172"] &&
            !viewModel.hasLoadedCatalog
        }

        XCTAssertTrue(shellVisible)
        _ = await loadTask.value
    }

    func testAsyncCatalogLoadUsesProviderOnceAndCachesResults() async {
        let colors = [
            PaintColor(number: "OC-17", name: "White Dove", family: "White", hex: "F3EDE1", brand: .benjaminMoore),
            PaintColor(number: "HC-172", name: "Revere Pewter", family: "Neutral", hex: "CCC1AE", brand: .benjaminMoore),
            PaintColor(number: "SW 6244", name: "Naval", family: "Blue", hex: "2E384D", brand: .sherwinWilliams),
        ]
        let provider = CountingColorCatalogProvider(brandIndices: makeBrandIndices(from: colors))
        let viewModel = ColorCatalogViewModel(catalogProvider: provider)
        viewModel.selectedFilter = .all

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        let loaded = await waitForCondition {
            viewModel.hasLoadedCatalog &&
            viewModel.filteredColors.map(\.number) == ["OC-17", "HC-172"]
        }

        XCTAssertTrue(loaded)
        let loadCount = await provider.recordedLoadCount(for: .benjaminMoore)
        let requestedBrands = await provider.recordedRequestedBrands()
        XCTAssertEqual(loadCount, 1)
        XCTAssertEqual(requestedBrands, [.benjaminMoore])
    }

    func testSwitchingBrandsLoadsEachCatalogOnceAndReusesCache() async {
        let colors = [
            PaintColor(number: "OC-17", name: "White Dove", family: "White", hex: "F3EDE1", brand: .benjaminMoore),
            PaintColor(number: "HC-172", name: "Revere Pewter", family: "Neutral", hex: "CCC1AE", brand: .benjaminMoore),
            PaintColor(number: "SW 6244", name: "Naval", family: "Blue", hex: "2E384D", brand: .sherwinWilliams),
            PaintColor(number: "SW 7029", name: "Agreeable Gray", family: "Gray", hex: "CFC6B8", brand: .sherwinWilliams),
        ]
        let provider = CountingColorCatalogProvider(brandIndices: makeBrandIndices(from: colors))
        let viewModel = ColorCatalogViewModel(catalogProvider: provider)
        viewModel.selectedFilter = .all

        await viewModel.loadIfNeeded()

        let benjaminMooreLoaded = await waitForCondition {
            viewModel.filteredColors.map(\.number) == ["OC-17", "HC-172"]
        }
        XCTAssertTrue(benjaminMooreLoaded)

        viewModel.selectedBrand = .sherwinWilliams

        let sherwinWilliamsLoaded = await waitForCondition {
            viewModel.filteredColors.map(\.number) == ["SW 6244", "SW 7029"]
        }
        XCTAssertTrue(sherwinWilliamsLoaded)

        viewModel.selectedBrand = .benjaminMoore

        let benjaminMooreReused = await waitForCondition {
            viewModel.filteredColors.map(\.number) == ["OC-17", "HC-172"]
        }
        XCTAssertTrue(benjaminMooreReused)

        let benjaminMooreLoads = await provider.recordedLoadCount(for: .benjaminMoore)
        let sherwinWilliamsLoads = await provider.recordedLoadCount(for: .sherwinWilliams)
        XCTAssertEqual(benjaminMooreLoads, 1)
        XCTAssertEqual(sherwinWilliamsLoads, 1)
    }

    func testAllColorsPagingLoadsAdditionalPagesOnDemand() async {
        let allColors = (0..<150).map { index in
            PaintColor(
                number: "BM-\(index)",
                name: "Color \(index)",
                family: index.isMultiple(of: 2) ? "Neutral" : "Blue",
                hex: String(format: "%06X", index + 1),
                brand: .benjaminMoore
            )
        }
        let viewModel = ColorCatalogViewModel(allColors: allColors)
        viewModel.selectedBrand = .benjaminMoore
        viewModel.selectedFilter = .all

        let firstPageLoaded = await waitForCondition {
            viewModel.filteredColors.count == ColorCatalogViewModel.pageSize
        }

        XCTAssertTrue(firstPageLoaded)

        viewModel.loadNextPageIfNeeded(currentItem: viewModel.filteredColors.last)

        let secondPageLoaded = await waitForCondition {
            viewModel.filteredColors.count == ColorCatalogViewModel.pageSize * 2
        }

        XCTAssertTrue(secondPageLoaded)

        viewModel.loadNextPageIfNeeded(currentItem: viewModel.filteredColors.last)

        let finalPageLoaded = await waitForCondition {
            viewModel.filteredColors.count == allColors.count
        }

        XCTAssertTrue(finalPageLoaded)
        XCTAssertFalse(viewModel.canLoadMoreResults)
    }

    func testPopularFilterUsesCuratedNamesInsteadOfRawCatalogOrder() {
        let allColors = [
            PaintColor(number: "ZZ-1", name: "Zulu", family: "Neutral", hex: "111111", brand: .benjaminMoore),
            PaintColor(number: "OC-17", name: "White Dove", family: "White", hex: "F3EDE1", brand: .benjaminMoore),
            PaintColor(number: "HC-172", name: "Revere Pewter", family: "Neutral", hex: "CCC1AE", brand: .benjaminMoore),
            PaintColor(number: "HC-173", name: "Edgecomb Gray", family: "Neutral", hex: "C5BEAD", brand: .benjaminMoore),
            PaintColor(number: "SW 6244", name: "Naval", family: "Blue", hex: "2E384D", brand: .sherwinWilliams),
        ]
        let viewModel = ColorCatalogViewModel(allColors: allColors)

        viewModel.selectedBrand = .benjaminMoore
        viewModel.selectedFilter = .popular

        XCTAssertEqual(
            viewModel.filteredColors.map(\.name),
            ["White Dove", "Revere Pewter", "Edgecomb Gray"]
        )
    }

    func testSearchOnlyReturnsMatchesForSelectedBrand() async {
        let allColors = [
            PaintColor(number: "2134-40", name: "Stormy Sky", family: "Blue", hex: "6A7C8A", brand: .benjaminMoore),
            PaintColor(number: "SW 6244", name: "Naval", family: "Blue", hex: "2E384D", brand: .sherwinWilliams),
            PaintColor(number: "SW 6245", name: "Quicksilver", family: "Blue", hex: "97A3AF", brand: .sherwinWilliams),
        ]
        let viewModel = ColorCatalogViewModel(allColors: allColors)

        viewModel.selectedBrand = .sherwinWilliams
        viewModel.selectedFilter = .all
        viewModel.searchText = "SW 6244"

        let completed = await waitForCondition {
            viewModel.filteredColors.map(\.number) == ["SW 6244"]
        }

        XCTAssertTrue(completed)
    }

    func testSearchMatchesSherwinNumbersWithoutSpacing() async {
        let allColors = [
            PaintColor(number: "SW 6244", name: "Naval", family: "Blue", hex: "2F3D4C", brand: .sherwinWilliams),
            PaintColor(number: "SW 6245", name: "Quicksilver", family: "Blue", hex: "97A3AF", brand: .sherwinWilliams),
        ]
        let viewModel = ColorCatalogViewModel(allColors: allColors)

        viewModel.selectedBrand = .sherwinWilliams
        viewModel.selectedFilter = .all
        viewModel.searchText = "SW6244"

        let completed = await waitForCondition {
            viewModel.filteredColors.map(\.number) == ["SW 6244"]
        }

        XCTAssertTrue(completed)
    }

    func testSearchOnUncachedBrandShowsLoadingUntilBrandResolves() async {
        let swColors = [
            PaintColor(number: "SW 6244", name: "Naval", family: "Blue", hex: "2F3D4C", brand: .sherwinWilliams),
            PaintColor(number: "SW 6245", name: "Quicksilver", family: "Blue", hex: "97A3AF", brand: .sherwinWilliams),
        ]
        let provider = CountingColorCatalogProvider(
            brandIndices: makeBrandIndices(from: swColors),
            loadDelay: .milliseconds(520)
        )
        let viewModel = ColorCatalogViewModel(
            catalogProvider: provider,
            popularColorsByBrand: [
                .benjaminMoore: [],
                .sherwinWilliams: [swColors[0]],
            ]
        )

        viewModel.selectedBrand = .sherwinWilliams
        viewModel.searchText = "SW6244"

        let showsLoading = await waitForCondition(timeout: .milliseconds(340)) {
            viewModel.isLoading &&
            !viewModel.hasLoadedCatalog &&
            viewModel.filteredColors.isEmpty
        }
        XCTAssertTrue(showsLoading)

        let completed = await waitForCondition(timeout: .seconds(1)) {
            viewModel.filteredColors.map(\.number) == ["SW 6244"]
        }

        XCTAssertTrue(completed)
    }

    func testPopularModeRemainsUsableWhenFullCatalogLoadFails() async {
        let shellColors = [
            PaintColor(number: "OC-17", name: "White Dove", family: "White", hex: "F3EDE1", brand: .benjaminMoore),
            PaintColor(number: "HC-172", name: "Revere Pewter", family: "Neutral", hex: "CCC1AE", brand: .benjaminMoore),
        ]
        let provider = CountingColorCatalogProvider(
            brandIndices: [:],
            loadDelay: .milliseconds(60),
            failingBrands: [.benjaminMoore]
        )
        let viewModel = ColorCatalogViewModel(
            catalogProvider: provider,
            popularColorsByBrand: [
                .benjaminMoore: shellColors,
                .sherwinWilliams: [],
            ]
        )

        let loadTask = Task {
            await viewModel.loadIfNeeded()
        }

        let shellVisible = await waitForCondition(timeout: .milliseconds(50)) {
            viewModel.filteredColors.map(\.number) == shellColors.map(\.number)
        }
        XCTAssertTrue(shellVisible)

        _ = await loadTask.value

        XCTAssertEqual(viewModel.filteredColors.map(\.number), shellColors.map(\.number))
        XCTAssertTrue(viewModel.hasLoadedCatalog)
    }

    func testPaintColorEqualityHashingAndIDRemainStableWithDerivedColor() {
        let left = PaintColor(
            number: "OC-17",
            name: "White Dove",
            family: "White",
            hex: "F3EDE1",
            brand: .benjaminMoore
        )
        let right = PaintColor(
            number: "OC-17",
            name: "White Dove",
            family: "White",
            hex: "F3EDE1",
            brand: .benjaminMoore
        )

        XCTAssertEqual(left, right)
        XCTAssertEqual(left.id, "benjamin_moore-OC-17")
        XCTAssertEqual(Set([left, right]).count, 1)
        XCTAssertEqual(UIColor(left.color).cgColor.components?.count, UIColor(right.color).cgColor.components?.count)
    }

    func testShareLinksBuildSharePageAndDesignCardURLsWhenAvailable() {
        let visualization = Visualization(
            id: "visualization_123",
            remoteVisualizationID: "visualization_123",
            colorName: "White Dove",
            colorHex: "F3EDE1",
            colorCode: "OC-17",
            roomName: "Current Room",
            afterImagePath: "/tmp/after.jpg",
            shareID: "share_abc",
            surface: "Walls",
            createdAt: .now
        )

        let links = visualization.shareLinks(baseURL: URL(string: "https://example.com")!)

        XCTAssertEqual(links?.sharePageURL.absoluteString, "https://example.com/share/share_abc")
        XCTAssertEqual(links?.designCardURL.absoluteString, "https://example.com/api/share/share_abc/card")
    }

    func testVisualizationDecodingUsesExplicitStoredBrandWhenPresent() throws {
        let json = """
        {
          "id": "visualization_789",
          "colorName": "Hague Blue",
          "colorHex": "3F4D57",
          "colorCode": "No. 30",
          "brand": "farrow_ball",
          "roomName": "Current Room",
          "surface": "Walls",
          "createdAt": "2026-03-13T00:00:00Z"
        }
        """

        let visualization = try JSONDecoder().decode(Visualization.self, from: Data(json.utf8))

        XCTAssertEqual(visualization.inferredBrand.rawValue, "farrow_ball")
        XCTAssertEqual(visualization.asPaintColor.brand.rawValue, "farrow_ball")
    }

    func testVisualizationEncodingPersistsStoredBrandAndLegacyDecodeFallsBackToNumberInference() throws {
        let farrowBall = try XCTUnwrap(PaintBrand(rawValue: "farrow_ball"))
        let visualization = Visualization(
            id: "visualization_790",
            colorName: "Hague Blue",
            colorHex: "3F4D57",
            colorCode: "No. 30",
            roomName: "Current Room",
            shareID: nil,
            surface: "Walls",
            brand: farrowBall,
            createdAt: .now
        )

        let encoded = try JSONEncoder().encode(visualization)
        let encodedObject = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        XCTAssertEqual(encodedObject["brand"] as? String, "farrow_ball")

        let legacyJson = """
        {
          "id": "visualization_791",
          "colorName": "Naval",
          "colorHex": "2E384D",
          "colorCode": "SW 6244",
          "roomName": "Bedroom",
          "surface": "Walls",
          "createdAt": "2026-03-13T00:00:00Z"
        }
        """

        let legacyVisualization = try JSONDecoder().decode(Visualization.self, from: Data(legacyJson.utf8))
        XCTAssertEqual(legacyVisualization.inferredBrand, .sherwinWilliams)
    }

    func testShareLinksReturnNilWhenShareIDOrBaseURLMissing() {
        let visualizationWithoutShare = Visualization(
            id: "visualization_123",
            colorName: "White Dove",
            colorHex: "F3EDE1",
            colorCode: "OC-17",
            roomName: "Current Room",
            afterImagePath: "/tmp/after.jpg",
            shareID: nil,
            surface: "Walls",
            createdAt: .now
        )

        XCTAssertNil(visualizationWithoutShare.shareLinks(baseURL: URL(string: "https://example.com")!))

        let visualizationWithShare = Visualization(
            id: "visualization_456",
            colorName: "White Dove",
            colorHex: "F3EDE1",
            colorCode: "OC-17",
            roomName: "Current Room",
            afterImagePath: "/tmp/after.jpg",
            shareID: "share_abc",
            surface: "Walls",
            createdAt: .now
        )

        XCTAssertNil(visualizationWithShare.shareLinks(baseURL: nil))
    }

    func testShareActivityItemsIncludeSharePageURLWhenAvailable() {
        let visualization = Visualization(
            id: "visualization_123",
            remoteVisualizationID: "visualization_123",
            colorName: "White Dove",
            colorHex: "F3EDE1",
            colorCode: "OC-17",
            roomName: "Current Room",
            afterImagePath: "/tmp/after.jpg",
            shareID: "share_abc",
            surface: "Walls",
            createdAt: .now
        )
        let image = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).image { _ in
            UIColor.white.setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: 2, height: 2)).fill()
        }

        let items = visualization.shareActivityItems(
            image: image,
            baseURL: URL(string: "https://example.com")!
        )

        XCTAssertEqual(items.count, 2)
        XCTAssertTrue(items[0] is UIImage)
        XCTAssertEqual(
            (items[1] as? URL)?.absoluteString,
            "https://example.com/share/share_abc"
        )
    }

    func testShareActivityItemsFallbackToImageWhenShareLinkUnavailable() {
        let visualization = Visualization(
            id: "visualization_123",
            colorName: "White Dove",
            colorHex: "F3EDE1",
            colorCode: "OC-17",
            roomName: "Current Room",
            afterImagePath: "/tmp/after.jpg",
            shareID: nil,
            surface: "Walls",
            createdAt: .now
        )
        let image = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).image { _ in
            UIColor.white.setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: 2, height: 2)).fill()
        }

        let items = visualization.shareActivityItems(
            image: image,
            baseURL: URL(string: "https://example.com")!
        )

        XCTAssertEqual(items.count, 1)
        XCTAssertTrue(items[0] is UIImage)
    }

    func testSavedPreviewDesignCardRendererProducesBrandedCardWithoutShareConfiguration() throws {
        let visualization = Visualization(
            id: "visualization_123",
            colorName: "White Dove",
            colorHex: "F3EDE1",
            colorCode: "OC-17",
            roomName: "Current Room",
            shareID: nil,
            surface: "Walls",
            createdAt: .now
        )
        let afterImage = makeSolidTestImage(fill: .systemBlue)
        let beforeImage = makeSolidTestImage(fill: .systemOrange)

        let renderedImage = try XCTUnwrap(
            SavedPreviewDesignCardRenderer.render(
                theme: Theme(),
                visualization: visualization,
                beforeImage: beforeImage,
                afterImage: afterImage,
                scale: 1
            )
        )

        XCTAssertGreaterThan(renderedImage.size.width, 100)
        XCTAssertGreaterThan(renderedImage.size.height, 100)

        let overlaySample = try XCTUnwrap(
            pixelColor(
                in: renderedImage,
                at: CGPoint(x: renderedImage.size.width * 0.12, y: renderedImage.size.height * 0.84)
            )
        )
        XCTAssertFalse(overlaySample.isApproximatelyEqual(to: .systemBlue))
    }

    func testSavedPreviewDesignCardRendererStillProducesBrandedCardWithoutBeforeImage() throws {
        let visualization = Visualization(
            id: "visualization_456",
            colorName: "Naval",
            colorHex: "2E384D",
            colorCode: "SW 6244",
            roomName: "Bedroom",
            shareID: nil,
            surface: "Walls",
            createdAt: .now
        )
        let afterImage = makeSolidTestImage(fill: .systemGreen)

        let renderedImage = try XCTUnwrap(
            SavedPreviewDesignCardRenderer.render(
                theme: Theme(),
                visualization: visualization,
                beforeImage: nil,
                afterImage: afterImage,
                scale: 1
            )
        )

        let overlaySample = try XCTUnwrap(
            pixelColor(
                in: renderedImage,
                at: CGPoint(x: renderedImage.size.width * 0.12, y: renderedImage.size.height * 0.84)
            )
        )
        XCTAssertFalse(overlaySample.isApproximatelyEqual(to: .systemGreen))
    }

    func testSavedPreviewExportResolverUsesRenderedDesignCardForExportActions() throws {
        let previewImage = makeSolidTestImage(fill: .systemBlue)
        let designCardImage = makeSolidTestImage(fill: .systemPurple)

        let descriptor = SavedPreviewExportResolver.resolve(
            imageState: .ready(designCardImage),
            afterImage: previewImage,
            colorName: "White Dove"
        )

        XCTAssertEqual(descriptor.kind, .designCard)
        XCTAssertEqual(descriptor.primaryTitle, "Share Design Card")
        XCTAssertEqual(descriptor.shareSheetTitle, "White Dove Design Card")
        XCTAssertTrue(try XCTUnwrap(descriptor.image) === designCardImage)
        XCTAssertTrue(descriptor.canExport)
    }

    func testSavedPreviewExportResolverFallsBackToPreviewCopyWhenRenderingFails() throws {
        let previewImage = makeSolidTestImage(fill: .systemBlue)

        let descriptor = SavedPreviewExportResolver.resolve(
            imageState: .failed,
            afterImage: previewImage,
            colorName: "White Dove"
        )

        XCTAssertEqual(descriptor.kind, .preview)
        XCTAssertEqual(descriptor.primaryTitle, "Share Preview Image")
        XCTAssertEqual(descriptor.shareSheetTitle, "White Dove Preview")
        XCTAssertTrue(try XCTUnwrap(descriptor.image) === previewImage)
    }

    func testPhotoProcessingServiceCreatesReusableVariantsFromImportedFile() async throws {
        let tempDirectory = try makeTemporaryDirectory()
        let sourceURL = tempDirectory.appendingPathComponent("room.png")
        try XCTUnwrap(makeTestImage(fill: .systemBlue).pngData()).write(to: sourceURL)

        let service = PhotoProcessingService(
            rootDirectory: tempDirectory.appendingPathComponent("processed-assets", isDirectory: true)
        )

        let reference = try await service.importPhoto(
            ImportedPhoto(fileURL: sourceURL, isOriginalFile: true)
        )
        let asset = await service.asset(for: reference)
        let uploadData = try await service.uploadData(for: reference)
        let displayImage = await service.loadDisplayImage(for: reference, maxPixelSize: 512)

        XCTAssertTrue(FileManager.default.fileExists(atPath: asset.originalURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: asset.workingURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: asset.uploadURL.path))
        XCTAssertLessThanOrEqual(uploadData.count, 4_100_000)
        XCTAssertNotNil(displayImage)
        XCTAssertGreaterThan(reference.workingPixelSize.width, 0)
        XCTAssertGreaterThan(reference.workingPixelSize.height, 0)
        XCTAssertFalse(reference.fingerprint.isEmpty)
    }

    func testPhotoProcessingServiceBuildsWorkingRepresentationFromSourceDownsamplingLargeImages() throws {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: 3_072, height: 2_304),
            format: format
        )
        let largeImageData = try XCTUnwrap(
            renderer.image { _ in
                UIColor.systemIndigo.setFill()
                UIBezierPath(rect: CGRect(x: 0, y: 0, width: 3_072, height: 2_304)).fill()
            }.jpegData(compressionQuality: 0.92)
        )

        let representation = try PhotoProcessingService.makeWorkingRepresentation(
            from: largeImageData,
            maxDimension: 2_048
        )

        XCTAssertEqual(representation.originalPixelSize, PhotoPixelSize(width: 3_072, height: 2_304))
        XCTAssertLessThanOrEqual(
            max(representation.workingPixelSize.width, representation.workingPixelSize.height),
            2_048
        )
        XCTAssertGreaterThan(representation.workingPixelSize.width, 0)
        XCTAssertGreaterThan(representation.workingPixelSize.height, 0)
    }

    func testSetPhotoPersistsPhotoAssetReferenceRatherThanLegacyFileName() async throws {
        let tempDirectory = try makeTemporaryDirectory()
        let intakeCoordinator = PhotoIntakeCoordinator(
            processor: PhotoProcessingService(rootDirectory: tempDirectory)
        )
        let draftStore = InMemoryProjectDraftStore()
        let viewModel = await makeVisualizer(
            draftStore: draftStore,
            libraryStore: InMemoryVisualizationLibraryStore(),
            visualizationService: MockVisualizationService(),
            photoIntakeCoordinator: intakeCoordinator
        )

        viewModel.setPhoto(from: try XCTUnwrap(makeTestImage(fill: .systemOrange).pngData()))

        let persisted = await waitForAsyncCondition(timeout: .seconds(2)) {
            guard let draft = await draftStore.snapshotDraft() else { return false }
            return draft.photoAsset != nil
                && draft.photoFileName == nil
                && viewModel.photoAsset != nil
        }

        XCTAssertTrue(persisted)
    }

    func testSetPhotoFromImportedPhotoSnapshotsPickerFileBeforeTemporaryURLDisappears() async throws {
        let sourceData = try XCTUnwrap(makeTestImage(fill: .systemOrange).pngData())
        let sourceURL = try makeTemporaryDirectory().appendingPathComponent("picked-photo.png")
        try sourceData.write(to: sourceURL)

        let importedAsset = makePhotoAssetReference(id: "imported-photo")
        let intakeCoordinator = SnapshottingImportedPhotoCoordinator(
            result: PhotoIntakeResult(
                asset: importedAsset,
                displayImage: makeTestImage(fill: .systemOrange)
            )
        )
        let viewModel = await makeVisualizer(
            draftStore: InMemoryProjectDraftStore(),
            libraryStore: InMemoryVisualizationLibraryStore(),
            visualizationService: MockVisualizationService(),
            photoIntakeCoordinator: intakeCoordinator
        )

        await viewModel.setPhoto(from: ImportedPhoto(fileURL: sourceURL))
        try FileManager.default.removeItem(at: sourceURL)

        let photoReady = await waitForAsyncCondition(timeout: .seconds(2)) {
            viewModel.photoAsset?.id == importedAsset.id
                && viewModel.photo != nil
                && !viewModel.isCompressing
        }

        let importedData = await intakeCoordinator.recordedImportedData()
        let importedFileExtension = await intakeCoordinator.recordedImportedFileExtension()
        let importPhotoCallCount = await intakeCoordinator.recordedImportPhotoCallCount()

        XCTAssertTrue(photoReady)
        XCTAssertEqual(importedData, sourceData)
        XCTAssertEqual(importedFileExtension, "png")
        XCTAssertEqual(importPhotoCallCount, 0)
    }

    func testSetPhotoRemovesAbandonedImportedAssetWhenNewRequestSupersedesIt() async throws {
        let intakeCoordinator = ControlledPhotoIntakeCoordinator()
        let draftStore = InMemoryProjectDraftStore()
        let viewModel = await makeVisualizer(
            draftStore: draftStore,
            libraryStore: InMemoryVisualizationLibraryStore(),
            visualizationService: MockVisualizationService(),
            photoIntakeCoordinator: intakeCoordinator
        )

        let firstAsset = makePhotoAssetReference(id: "first-import")
        let secondAsset = makePhotoAssetReference(id: "second-import")

        viewModel.setPhoto(from: Data([0x01]))
        viewModel.setPhoto(from: Data([0x02]))

        let requestsEnqueued = await waitForAsyncCondition(timeout: .seconds(2)) {
            await intakeCoordinator.pendingDataImportCount() == 2
        }
        XCTAssertTrue(requestsEnqueued)

        await intakeCoordinator.completeMostRecentDataImport(
            with: PhotoIntakeResult(
                asset: secondAsset,
                displayImage: makeTestImage(fill: .systemPink)
            )
        )

        let secondApplied = await waitForAsyncCondition(timeout: .seconds(2)) {
            viewModel.photoAsset?.id == secondAsset.id
        }
        XCTAssertTrue(secondApplied)

        await intakeCoordinator.completeOldestDataImport(
            with: PhotoIntakeResult(
                asset: firstAsset,
                displayImage: makeTestImage(fill: .systemMint)
            )
        )

        let cleanedAbandonedAsset = await waitForAsyncCondition(timeout: .seconds(2)) {
            let removedAssetIDs = await intakeCoordinator.recordedRemovedAssetIDs()
            return removedAssetIDs.contains(firstAsset.id)
        }

        XCTAssertTrue(cleanedAbandonedAsset)
        XCTAssertEqual(viewModel.photoAsset?.id, secondAsset.id)
    }

    func testBootstrapMigratesLegacyDraftPhotoFileIntoPhotoAssetReference() async throws {
        let tempDirectory = try makeTemporaryDirectory()
        let intakeCoordinator = PhotoIntakeCoordinator(
            processor: PhotoProcessingService(rootDirectory: tempDirectory)
        )
        let legacyDraft = ProjectDraft(
            photoFileName: "legacy-room.jpg",
            photoFingerprint: "legacy-fingerprint"
        )
        let draftStore = InMemoryProjectDraftStore(
            draft: legacyDraft,
            legacyPhotoData: try XCTUnwrap(makeTestImage(fill: .systemTeal).jpegData(compressionQuality: 0.9))
        )

        let viewModel = await makeVisualizer(
            draftStore: draftStore,
            libraryStore: InMemoryVisualizationLibraryStore(),
            visualizationService: MockVisualizationService(),
            photoIntakeCoordinator: intakeCoordinator
        )

        let migrated = await waitForAsyncCondition(timeout: .seconds(2)) {
            guard let draft = await draftStore.snapshotDraft() else { return false }
            return draft.photoAsset != nil
                && draft.photoFileName == nil
                && viewModel.photoAsset != nil
        }

        XCTAssertTrue(migrated)
        let migratedDraft = await draftStore.snapshotDraft()
        XCTAssertEqual(migratedDraft?.photoAsset?.fingerprint, "legacy-fingerprint")
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

    private func waitForAsyncCondition(
        timeout: Duration = .seconds(1),
        interval: Duration = .milliseconds(20),
        condition: @escaping () async -> Bool
    ) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)

        while clock.now < deadline {
            if await condition() {
                return true
            }
            try? await Task.sleep(for: interval)
        }

        return await condition()
    }

    private func writeTemporaryCatalogJSON(_ contents: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        guard let data = contents.data(using: .utf8) else {
            throw XCTSkip("Could not encode test JSON fixture")
        }
        try data.write(to: url)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: url)
        }
        return url
    }

    private func makeBrandIndices(from colors: [PaintColor]) -> [PaintBrand: ColorCatalogBrandIndex] {
        Dictionary(grouping: colors, by: \.brand).mapValues { brandColors in
            ColorCatalogBrandIndex(
                allColors: brandColors,
                searchEntries: brandColors.map(ColorCatalogSearchEntry.init),
                popularColors: brandColors,
                familyCounts: Dictionary(grouping: brandColors, by: \.family)
                    .map { ColorCatalogFamilyCount(family: $0.key, count: $0.value.count) }
                    .sorted { lhs, rhs in
                        if lhs.count == rhs.count {
                            return lhs.family < rhs.family
                        }
                        return lhs.count > rhs.count
                    }
                )
        }
    }

    private func makeVisualizer(
        projectStore: InMemoryRoomProjectStore = InMemoryRoomProjectStore(),
        draftStore: InMemoryProjectDraftStore,
        libraryStore: InMemoryVisualizationLibraryStore,
        visualizationService: VisualizationService,
        photoIntakeCoordinator: (any PhotoIntakeCoordinating)? = nil
    ) async -> VisualizerViewModel {
        let viewModel = VisualizerViewModel(
            projectStore: projectStore,
            draftStore: draftStore,
            libraryStore: libraryStore,
            visualizationService: visualizationService,
            photoIntakeCoordinator: photoIntakeCoordinator
        )
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(20))

        let loaded = await waitForAsyncCondition(timeout: .seconds(1)) {
            let expectedDraft = await draftStore.snapshotDraft()
            let expectedResults = await libraryStore.snapshotResults()
            let expectedLibrary = await projectStore.snapshotLibrary()
            return !viewModel.isLoadingDraft
                && !viewModel.isLoadingLibrary
                && !viewModel.isLoadingProjects
                && viewModel.selectedColors == (expectedDraft?.selectedColors ?? [])
                && viewModel.selectedSurface == expectedDraft?.selectedSurface
                && viewModel.customSurfaceText == (expectedDraft?.customSurfaceText ?? "")
                && viewModel.savedResults == expectedResults
                && viewModel.projects == expectedLibrary.projects
        }
        XCTAssertTrue(loaded)
        return viewModel
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: url)
        }
        return url
    }

    private func makePhotoAssetReference(id: String) -> PhotoAssetReference {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(id, isDirectory: true)
        return PhotoAssetReference(
            id: id,
            fingerprint: "fingerprint-\(id)",
            originalPath: root.appendingPathComponent("original.jpg").path,
            workingPath: root.appendingPathComponent("working.jpg").path,
            uploadPath: root.appendingPathComponent("upload.jpg").path,
            originalPixelSize: PhotoPixelSize(width: 3_072, height: 2_304),
            workingPixelSize: PhotoPixelSize(width: 2_048, height: 1_536),
            createdAt: .now
        )
    }

    private func makeTestImage(fill: UIColor) -> UIImage {
        let size = CGSize(width: 120, height: 90)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            fill.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            UIColor.white.setFill()
            context.fill(CGRect(x: 10, y: 10, width: 72, height: 28))
        }
    }

    private func makeSolidTestImage(fill: UIColor, size: CGSize = CGSize(width: 120, height: 90)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            fill.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func pixelColor(in image: UIImage, at point: CGPoint) -> UIColor? {
        guard
            let cgImage = image.cgImage,
            point.x >= 0,
            point.y >= 0,
            Int(point.x) < cgImage.width,
            Int(point.y) < cgImage.height
        else {
            return nil
        }

        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var pixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let x = Int(point.x)
        let y = Int(point.y)
        let index = ((width * y) + x) * bytesPerPixel
        let red = CGFloat(pixels[index]) / 255
        let green = CGFloat(pixels[index + 1]) / 255
        let blue = CGFloat(pixels[index + 2]) / 255
        let alpha = CGFloat(pixels[index + 3]) / 255

        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    private func makeRequestFingerprint(
        photo: UIImage,
        color: PaintColor,
        surface: SurfaceType,
        customSurfaceText: String
    ) throws -> String {
        let photoFingerprint = try XCTUnwrap(VisualizationRequestFingerprint.photoFingerprint(for: photo))
        return VisualizationRequestFingerprint.make(
            photoFingerprint: photoFingerprint,
            color: color,
            surface: surface,
            customSurfaceText: customSurfaceText
        )
    }

    private func makeCachedResult(
        in directory: URL,
        id: String,
        photo: UIImage,
        color: PaintColor,
        surface: SurfaceType,
        customSurfaceText: String,
        roomName: String,
        requestFingerprint: String?
    ) throws -> VisualizationResult {
        let beforeURL = directory.appendingPathComponent("\(id)-before-card.jpg")
        let afterURL = directory.appendingPathComponent("\(id)-after-card.jpg")

        let beforeData = try XCTUnwrap(photo.jpegData(compressionQuality: 0.9))
        let afterData = try XCTUnwrap(photo.jpegData(compressionQuality: 0.9))
        try beforeData.write(to: beforeURL, options: .atomic)
        try afterData.write(to: afterURL, options: .atomic)

        return VisualizationResult(
            id: id,
            remoteVisualizationID: id,
            color: color,
            surface: surface.userFacingDescription(customSurfaceText: customSurfaceText),
            roomName: roomName,
            originalRemoteURL: "local://\(id)-before",
            resultRemoteURL: "local://\(id)-after",
            originalFullRemoteURL: nil,
            resultFullRemoteURL: nil,
            shareID: id,
            originalImagePath: beforeURL.path,
            resultImagePath: afterURL.path,
            originalFullImagePath: nil,
            resultFullImagePath: nil,
            createdAt: .now,
            requestFingerprint: requestFingerprint
        )
    }
}

private extension VisualizationJobItem {
    var isCompleted: Bool {
        if case .completed = state {
            return true
        }
        return false
    }
}

private extension UIColor {
    func isApproximatelyEqual(to other: UIColor, tolerance: CGFloat = 0.08) -> Bool {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        var otherRed: CGFloat = 0
        var otherGreen: CGFloat = 0
        var otherBlue: CGFloat = 0
        var otherAlpha: CGFloat = 0

        guard
            getRed(&red, green: &green, blue: &blue, alpha: &alpha),
            other.getRed(&otherRed, green: &otherGreen, blue: &otherBlue, alpha: &otherAlpha)
        else {
            return false
        }

        return abs(red - otherRed) <= tolerance
            && abs(green - otherGreen) <= tolerance
            && abs(blue - otherBlue) <= tolerance
            && abs(alpha - otherAlpha) <= tolerance
    }
}
