import XCTest
@testable import CrainPaintVisualizer

final class RoomProjectMigrationTests: XCTestCase {
    func testMigrateLegacyDraftCreatesActiveProjectWithPreservedSelections() throws {
        let whiteDove = PaintColor(
            number: "OC-17",
            name: "White Dove",
            family: "White",
            hex: "F3EDE1",
            brand: .benjaminMoore
        )
        let legacyDraft = ProjectDraft(
            selectedBrand: .benjaminMoore,
            selectedColors: [whiteDove],
            selectedSurface: .walls,
            customSurfaceText: "",
            photoFileName: "legacy-room.jpg",
            photoFingerprint: "photo-fingerprint-123"
        )

        let migration = RoomProjectMigration.migrate(
            legacyDraft: legacyDraft,
            savedResults: []
        )

        XCTAssertEqual(migration.library.projects.count, 1)
        XCTAssertEqual(migration.library.activeProjectID, migration.library.projects.first?.id)

        let project = try XCTUnwrap(migration.library.projects.first)
        XCTAssertEqual(project.preferredBrand, .benjaminMoore)
        XCTAssertEqual(project.candidateColors, [whiteDove])
        XCTAssertEqual(project.selectedSurface, .walls)
        XCTAssertEqual(project.photoFileName, "legacy-room.jpg")
        XCTAssertEqual(project.photoFingerprint, "photo-fingerprint-123")
        XCTAssertEqual(project.source, .legacyImport)
        XCTAssertEqual(project.state, .directionSelected)
    }

    func testMigrateLegacyResultsGroupsSharedBeforeImageIntoSingleImportedProject() throws {
        let whiteDove = PaintColor(
            number: "OC-17",
            name: "White Dove",
            family: "White",
            hex: "F3EDE1",
            brand: .benjaminMoore
        )
        let haleNavy = PaintColor(
            number: "HC-154",
            name: "Hale Navy",
            family: "Blue",
            hex: "44515D",
            brand: .benjaminMoore
        )
        let seaSalt = PaintColor(
            number: "SW6204",
            name: "Sea Salt",
            family: "Green",
            hex: "CDD5CF",
            brand: .sherwinWilliams
        )

        let sharedBeforePath = "/tmp/room-a-before.jpg"
        let migrated = RoomProjectMigration.migrate(
            legacyDraft: nil,
            savedResults: [
                makeResult(id: "viz-a", color: whiteDove, beforePath: sharedBeforePath, originalURL: "https://example.com/a-before"),
                makeResult(id: "viz-b", color: haleNavy, beforePath: sharedBeforePath, originalURL: "https://example.com/a-before"),
                makeResult(id: "viz-c", color: seaSalt, beforePath: "/tmp/room-b-before.jpg", originalURL: "https://example.com/b-before"),
            ]
        )

        XCTAssertNil(migrated.library.activeProjectID)
        XCTAssertEqual(migrated.library.projects.count, 2)

        let groupedProject = try XCTUnwrap(
            migrated.library.projects.first(where: { Set($0.visualizationIDs) == ["viz-a", "viz-b"] })
        )
        XCTAssertEqual(groupedProject.source, .legacyImport)
        XCTAssertEqual(groupedProject.state, .resultsReady)
        XCTAssertEqual(groupedProject.candidateColors.map(\.id), [whiteDove.id, haleNavy.id])
        XCTAssertEqual(groupedProject.selectedVisualizationID, "viz-a")

        let groupedResults = migrated.savedResults.filter { ["viz-a", "viz-b"].contains($0.id) }
        XCTAssertEqual(Set(groupedResults.compactMap(\.projectID)), [groupedProject.id])

        let standaloneProject = try XCTUnwrap(
            migrated.library.projects.first(where: { $0.visualizationIDs == ["viz-c"] })
        )
        XCTAssertEqual(standaloneProject.candidateColors.map(\.id), [seaSalt.id])
        XCTAssertEqual(migrated.savedResults.first(where: { $0.id == "viz-c" })?.projectID, standaloneProject.id)
    }

    private func makeResult(
        id: String,
        color: PaintColor,
        beforePath: String,
        originalURL: String
    ) -> VisualizationResult {
        VisualizationResult(
            id: id,
            remoteVisualizationID: "remote-\(id)",
            color: color,
            surface: "Full Walls",
            roomName: "Living Room",
            originalRemoteURL: originalURL,
            resultRemoteURL: "https://example.com/\(id)-after",
            originalFullRemoteURL: nil,
            resultFullRemoteURL: nil,
            shareID: "share-\(id)",
            originalImagePath: beforePath,
            resultImagePath: "/tmp/\(id)-after.jpg",
            originalFullImagePath: nil,
            resultFullImagePath: nil,
            createdAt: .now
        )
    }
}
