import Foundation

enum SurfaceType: String, CaseIterable, Codable, Hashable, Sendable {
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

    var testIdentifier: String {
        switch self {
        case .walls: "fullWalls"
        case .trimBase: "trimBase"
        case .accentWall: "accentWall"
        case .doors: "doors"
        case .cabinets: "cabinets"
        case .ceiling: "ceiling"
        case .custom: "custom"
        }
    }

    func apiSurfaceValue(customSurfaceText: String) -> String {
        switch self {
        case .walls:
            return "Walls"
        case .trimBase:
            return "Trim"
        case .accentWall, .custom:
            return "custom"
        case .doors:
            return "Front Door"
        case .cabinets:
            return "Cabinets"
        case .ceiling:
            return "Ceiling"
        }
    }

    func apiCustomInstruction(customSurfaceText: String) -> String? {
        switch self {
        case .accentWall:
            return "accent wall only"
        case .custom:
            let trimmed = customSurfaceText.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        default:
            return nil
        }
    }

    func userFacingDescription(customSurfaceText: String) -> String {
        switch self {
        case .custom:
            let trimmed = customSurfaceText.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? rawValue : trimmed
        default:
            return rawValue
        }
    }

    static func restoredSelection(from description: String) -> (surface: SurfaceType?, customSurfaceText: String) {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return (nil, "") }

        if let exactMatch = allCases.first(where: { $0.rawValue.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return (exactMatch, "")
        }

        switch trimmed.lowercased() {
        case "walls", "full walls":
            return (.walls, "")
        case "trim", "trim & base", "trim and base":
            return (.trimBase, "")
        case "accent wall", "accent wall only":
            return (.accentWall, "")
        case "front door", "door", "doors":
            return (.doors, "")
        case "cabinet", "cabinets":
            return (.cabinets, "")
        case "ceiling":
            return (.ceiling, "")
        case "custom surface", "custom / other":
            return (.custom, "")
        default:
            return (.custom, trimmed)
        }
    }
}
