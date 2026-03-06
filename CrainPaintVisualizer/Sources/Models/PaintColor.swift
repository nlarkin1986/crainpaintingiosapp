import SwiftUI

struct PaintColor: Codable, Hashable, Identifiable, Sendable {
    let number: String
    let name: String
    let family: String
    let hex: String
    let brand: PaintBrand

    var id: String { "\(brand.rawValue)-\(number)" }
    var color: Color { Color(hex: hex) }

    static func placeholder() -> PaintColor {
        PaintColor(number: "HC-00", name: "Placeholder", family: "Neutral", hex: "CCCCCC", brand: .benjaminMoore)
    }
}

enum PaintBrand: String, Codable, CaseIterable, Hashable, Sendable {
    case benjaminMoore = "benjamin_moore"
    case sherwinWilliams = "sherwin_williams"
    case behr = "behr"

    var displayName: String {
        switch self {
        case .benjaminMoore: "Benjamin Moore"
        case .sherwinWilliams: "Sherwin-Williams"
        case .behr: "Behr"
        }
    }
}
