import Foundation

enum SurfaceType: String, CaseIterable, Hashable, Sendable {
    case walls = "Full Walls"
    case trimBase = "Trim & Base"
    case accentWall = "Accent Wall"
    case doors = "Doors"
    case cabinets = "Cabinets"
    case ceiling = "Ceiling"
    case custom = "Custom / Other"

    var iconName: String {
        switch self {
        case .walls: "square.3.layers.3d"
        case .trimBase: "ruler"
        case .accentWall: "rectangle.split.2x1"
        case .doors: "door.left.hand.open"
        case .cabinets: "archivebox"
        case .ceiling: "rectangle.topthird.inset.filled"
        case .custom: "paintpalette"
        }
    }
}
