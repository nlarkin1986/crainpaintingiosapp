import SwiftUI

struct PaintColor: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let number: String
    let name: String
    let family: String
    let hex: String
    let brand: PaintBrand
    let color: Color

    init(number: String, name: String, family: String, hex: String, brand: PaintBrand) {
        self.id = "\(brand.rawValue)-\(number)"
        self.number = number
        self.name = name
        self.family = family
        self.hex = hex
        self.brand = brand
        self.color = Color(hex: hex)
    }

    // Codable conformance — Color is not Codable, so decode/encode manually
    enum CodingKeys: String, CodingKey {
        case number, name, family, hex, brand
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let number = try container.decode(String.self, forKey: .number)
        let name = try container.decode(String.self, forKey: .name)
        let family = try container.decode(String.self, forKey: .family)
        let hex = try container.decode(String.self, forKey: .hex)
        let brand = try container.decode(PaintBrand.self, forKey: .brand)
        self.init(number: number, name: name, family: family, hex: hex, brand: brand)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(number, forKey: .number)
        try container.encode(name, forKey: .name)
        try container.encode(family, forKey: .family)
        try container.encode(hex, forKey: .hex)
        try container.encode(brand, forKey: .brand)
    }

    // Hashable — exclude `color` (which is derived from `hex`)
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: PaintColor, rhs: PaintColor) -> Bool {
        lhs.id == rhs.id
    }
}

enum PaintBrand: String, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    case benjaminMoore = "benjamin_moore"
    case sherwinWilliams = "sherwin_williams"
    case behr = "behr"

    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .benjaminMoore: "Benjamin Moore"
        case .sherwinWilliams: "Sherwin-Williams"
        case .behr: "Behr"
        }
    }
}
