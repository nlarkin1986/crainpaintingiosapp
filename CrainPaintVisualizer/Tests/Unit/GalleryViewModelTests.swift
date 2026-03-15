import XCTest
@testable import CrainPaintVisualizer

@MainActor
final class GalleryViewModelTests: XCTestCase {
    func testGeneratedSectionsUseCurrentVisualizerSelections() {
        let visualizer = VisualizerViewModel()
        let gallery = GalleryViewModel()

        let whiteDove = PaintColor(
            number: "OC-17",
            name: "White Dove",
            family: "White",
            hex: "F3EDE1",
            brand: .benjaminMoore
        )
        let haleNavy = PaintColor(
            number: "2163-10",
            name: "Hale Navy",
            family: "Blue",
            hex: "3C4659",
            brand: .benjaminMoore
        )

        _ = visualizer.addColor(whiteDove)
        _ = visualizer.addColor(haleNavy)
        visualizer.selectedSurface = .walls

        let sections = gallery.sections(using: visualizer)

        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections[0].name, "Current Room")
        XCTAssertEqual(sections[0].visualizations.map(\.colorCode), ["OC-17", "2163-10"])
    }

    func testFallsBackToCuratedSectionsWithoutSelections() {
        let visualizer = VisualizerViewModel()
        let gallery = GalleryViewModel()

        let sections = gallery.sections(using: visualizer)

        XCTAssertFalse(sections.isEmpty)
        XCTAssertEqual(sections.first?.name, "Living Room")
    }

    func testVisualizationLookupFindsGeneratedVisualization() {
        let visualizer = VisualizerViewModel()
        let gallery = GalleryViewModel()
        let color = PaintColor(
            number: "OC-17",
            name: "White Dove",
            family: "White",
            hex: "F3EDE1",
            brand: .benjaminMoore
        )

        _ = visualizer.addColor(color)
        let visualization = gallery.visualization(for: "generated-0-\(color.id)", using: visualizer)

        XCTAssertEqual(visualization?.colorName, "White Dove")
        XCTAssertEqual(visualization?.surface, "Selected Surface")
    }

    func testProcessingPresentationUsesActiveSingularCopyWithoutReadyCount() {
        let color = PaintColor(
            number: "OC-17",
            name: "White Dove",
            family: "White",
            hex: "F3EDE1",
            brand: .benjaminMoore
        )
        let job = VisualizationJob(
            surfaceDescription: "Full Walls",
            roomName: "Current Room",
            items: [VisualizationJobItem(color: color)]
        )

        let presentation = ResultsGalleryProcessingPresentation(
            job: job,
            completedCount: 0,
            lastGenerationMessage: nil
        )

        XCTAssertEqual(presentation.title, "Rendering your preview")
        XCTAssertEqual(presentation.subtitle, "Applying White Dove to full walls now")
        XCTAssertNil(presentation.detail)
        XCTAssertEqual(
            presentation.helperText,
            "Rendering continues if you leave this screen. Your preview will appear here automatically when it's ready."
        )
        XCTAssertEqual(presentation.statusToken(for: .generating), "Rendering now")
        XCTAssertEqual(presentation.statusToken(for: .failed("Example")), "Needs review")
    }

    func testProcessingPresentationUsesPluralCopyAndPrefersJobNotice() {
        let firstColor = PaintColor(
            number: "OC-17",
            name: "White Dove",
            family: "White",
            hex: "F3EDE1",
            brand: .benjaminMoore
        )
        let secondColor = PaintColor(
            number: "2163-10",
            name: "Hale Navy",
            family: "Blue",
            hex: "3C4659",
            brand: .benjaminMoore
        )
        let job = VisualizationJob(
            surfaceDescription: "Full Walls",
            roomName: "Current Room",
            items: [
                VisualizationJobItem(
                    color: firstColor,
                    state: .completed(mockVisualizationResult(color: firstColor))
                ),
                VisualizationJobItem(color: secondColor, state: .generating)
            ],
            notice: "Rate limit in effect."
        )

        let presentation = ResultsGalleryProcessingPresentation(
            job: job,
            completedCount: 1,
            lastGenerationMessage: "Fallback message"
        )

        XCTAssertEqual(presentation.title, "Rendering your previews")
        XCTAssertEqual(presentation.subtitle, "Applying Hale Navy to full walls now")
        XCTAssertEqual(presentation.detail, "1 of 2 ready")
        XCTAssertEqual(
            presentation.helperText,
            "Rendering continues if you leave this screen. Finished previews will appear here automatically."
        )
        XCTAssertEqual(presentation.notice, "Rate limit in effect.")
        XCTAssertEqual(presentation.statusToken(for: .queued), "Queued")
        XCTAssertEqual(presentation.statusToken(for: .generating), "Rendering now")
        XCTAssertEqual(presentation.statusToken(for: .completed(mockVisualizationResult(color: firstColor))), "Ready")
    }

    private func mockVisualizationResult(color: PaintColor) -> VisualizationResult {
        VisualizationResult(
            id: "result-\(color.id)",
            remoteVisualizationID: nil,
            color: color,
            surface: "Full Walls",
            roomName: "Current Room",
            originalRemoteURL: "https://example.com/original.jpg",
            resultRemoteURL: "https://example.com/result.jpg",
            originalFullRemoteURL: nil,
            resultFullRemoteURL: nil,
            shareID: "share-\(color.id)",
            originalImagePath: "/tmp/original-\(color.id).jpg",
            resultImagePath: "/tmp/result-\(color.id).jpg",
            originalFullImagePath: nil,
            resultFullImagePath: nil,
            createdAt: .now
        )
    }
}
