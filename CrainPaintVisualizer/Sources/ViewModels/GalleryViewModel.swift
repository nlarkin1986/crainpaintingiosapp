import SwiftUI

@MainActor
@Observable
final class GalleryViewModel {
    struct RoomSection: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let visualizations: [Visualization]
    }

    var sections: [RoomSection] = [
        RoomSection(name: "Living Room", icon: "sofa", visualizations: [
            Visualization(id: "1", colorName: "Hale Navy", colorHex: "3C4659", colorCode: "HC-172", roomName: "Living Room", beforeImageName: "room1", afterImageName: "room1_after", surface: "Full Walls"),
            Visualization(id: "2", colorName: "Sea Salt", colorHex: "B8C9C0", colorCode: "AF-70", roomName: "Living Room", beforeImageName: "room2", afterImageName: "room2_after", surface: "Accent Wall"),
            Visualization(id: "3", colorName: "Revere Pewter", colorHex: "CCC1AE", colorCode: "HC-172", roomName: "Living Room", beforeImageName: "room3", afterImageName: "room3_after", surface: "Full Walls"),
        ]),
        RoomSection(name: "Master Bedroom", icon: "bed.double", visualizations: [
            Visualization(id: "4", colorName: "Palladian Blue", colorHex: "B5CED0", colorCode: "2144-40", roomName: "Master Bedroom", beforeImageName: "room4", afterImageName: "room4_after", surface: "Full Walls"),
            Visualization(id: "5", colorName: "Cloud White", colorHex: "F2EDE3", colorCode: "OC-130", roomName: "Master Bedroom", beforeImageName: "room5", afterImageName: "room5_after", surface: "Trim & Base"),
        ]),
    ]
}
