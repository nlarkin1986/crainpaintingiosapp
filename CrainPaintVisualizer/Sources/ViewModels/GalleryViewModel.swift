import SwiftUI

@MainActor
@Observable
final class GalleryViewModel {
    struct RoomSection: Identifiable, Hashable {
        let id: String
        let name: String
        let icon: String
        let visualizations: [Visualization]
    }

    func sections(using visualizer: VisualizerViewModel) -> [RoomSection] {
        let generated = generatedSections(using: visualizer)
        return generated.isEmpty ? Self.curatedSections : generated
    }

    func visualization(for id: String, using visualizer: VisualizerViewModel) -> Visualization? {
        sections(using: visualizer)
            .flatMap(\.visualizations)
            .first(where: { $0.id == id })
    }

    private func generatedSections(using visualizer: VisualizerViewModel) -> [RoomSection] {
        if !visualizer.generatedVisualizations.isEmpty {
            return [
                RoomSection(
                    id: "generated-\(roomName(for: visualizer).lowercased().replacingOccurrences(of: " ", with: "-"))",
                    name: roomName(for: visualizer),
                    icon: iconName(for: visualizer.selectedSurface),
                    visualizations: visualizer.generatedVisualizations
                )
            ]
        }

        guard !visualizer.selectedColors.isEmpty,
              visualizer.isShowingGenerationPlaceholders else { return [] }

        let roomName = roomName(for: visualizer)
        let surface = visualizer.surfaceDescription.isEmpty ? "Selected Surface" : visualizer.surfaceDescription
        let icon = iconName(for: visualizer.selectedSurface)

        let visualizations = visualizer.selectedColors.enumerated().map { index, color in
            Visualization(
                id: "generated-\(index)-\(color.id)",
                colorName: color.name,
                colorHex: color.hex,
                colorCode: color.number,
                roomName: roomName,
                beforeImageName: "",
                afterImageName: "",
                surface: surface
            )
        }

        return [
            RoomSection(
                id: "generated-\(roomName.lowercased().replacingOccurrences(of: " ", with: "-"))",
                name: roomName,
                icon: icon,
                visualizations: visualizations
            )
        ]
    }

    private func roomName(for visualizer: VisualizerViewModel) -> String {
        switch visualizer.selectedSurface {
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
            let trimmed = visualizer.customSurfaceText.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "Custom Surface" : trimmed
        case nil:
            return visualizer.hasPhoto ? "Current Project" : "Saved Inspirations"
        }
    }

    private func iconName(for surface: SurfaceType?) -> String {
        switch surface {
        case .cabinets:
            return "archivebox"
        case .doors:
            return "door.left.hand.open"
        case .ceiling:
            return "rectangle.topthird.inset.filled"
        case .trimBase:
            return "ruler"
        case .accentWall:
            return "rectangle.split.2x1"
        case .walls:
            return "square.3.layers.3d"
        case .custom, nil:
            return "photo.on.rectangle.angled"
        }
    }

    private static let curatedSections: [RoomSection] = [
        RoomSection(
            id: "living-room",
            name: "Living Room",
            icon: "sofa",
            visualizations: [
                Visualization(
                    id: "1",
                    colorName: "Hale Navy",
                    colorHex: "3C4659",
                    colorCode: "2163-10",
                    roomName: "Living Room",
                    beforeImageName: "room1",
                    afterImageName: "room1_after",
                    surface: "Full Walls"
                ),
                Visualization(
                    id: "2",
                    colorName: "Sea Salt",
                    colorHex: "B8C9C0",
                    colorCode: "AF-70",
                    roomName: "Living Room",
                    beforeImageName: "room2",
                    afterImageName: "room2_after",
                    surface: "Accent Wall"
                ),
                Visualization(
                    id: "3",
                    colorName: "Revere Pewter",
                    colorHex: "CCC1AE",
                    colorCode: "HC-172",
                    roomName: "Living Room",
                    beforeImageName: "room3",
                    afterImageName: "room3_after",
                    surface: "Full Walls"
                ),
            ]
        ),
        RoomSection(
            id: "primary-bedroom",
            name: "Primary Bedroom",
            icon: "bed.double",
            visualizations: [
                Visualization(
                    id: "4",
                    colorName: "Palladian Blue",
                    colorHex: "B5CED0",
                    colorCode: "2144-40",
                    roomName: "Primary Bedroom",
                    beforeImageName: "room4",
                    afterImageName: "room4_after",
                    surface: "Full Walls"
                ),
                Visualization(
                    id: "5",
                    colorName: "Cloud White",
                    colorHex: "F2EDE3",
                    colorCode: "OC-130",
                    roomName: "Primary Bedroom",
                    beforeImageName: "room5",
                    afterImageName: "room5_after",
                    surface: "Trim & Base"
                ),
            ]
        ),
    ]
}
