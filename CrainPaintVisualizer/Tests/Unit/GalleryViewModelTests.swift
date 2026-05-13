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
        visualizer.generationState = .preparing

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

    func testVisualizationLookupFindsCompletedAIGeneratedVisualization() {
        let visualizer = VisualizerViewModel()
        let gallery = GalleryViewModel()
        let color = PaintColor(
            number: "OC-17",
            name: "White Dove",
            family: "White",
            hex: "F3EDE1",
            brand: .benjaminMoore
        )

        visualizer.generatedVisualizations = [
            Visualization(
                id: "share_123",
                colorName: color.name,
                colorHex: color.hex,
                colorCode: color.number,
                roomName: "Current Room",
                beforeImageName: "",
                afterImageName: "",
                surface: "Full Walls",
                originalImageURL: URL(string: "https://example.com/original.jpg"),
                resultImageURL: URL(string: "https://example.com/result.jpg"),
                shareId: "share_123",
                isAIGenerated: true
            )
        ]

        let visualization = gallery.visualization(for: "share_123", using: visualizer)

        XCTAssertEqual(visualization?.colorName, "White Dove")
        XCTAssertEqual(visualization?.surface, "Full Walls")
        XCTAssertEqual(visualization?.resultImageURL?.absoluteString, "https://example.com/result.jpg")
    }
}
