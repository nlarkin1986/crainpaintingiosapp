import Foundation

private struct ColorMatchRequest: Encodable {
    let sampleHex: String
}

private struct ColorMatchResponseItem: Decodable {
    let name: String
    let number: String
    let family: String
    let hex: String
    let brand: String
    let confidence: Int
}

protocol ColorMatchService {
    func match(sampleHex: String) async throws -> [ColorMatchResult]
}

struct RemoteColorMatchService: ColorMatchService {
    private let client: APIClient?
    private let fallback: ColorMatchService

    init(baseURL: URL? = APIEnvironment.baseURL, fallback: ColorMatchService = LocalColorMatchService()) {
        if let baseURL {
            self.client = APIClient(baseURL: baseURL)
        } else {
            self.client = nil
        }
        self.fallback = fallback
    }

    func match(sampleHex: String) async throws -> [ColorMatchResult] {
        guard let client else {
            return try await fallback.match(sampleHex: sampleHex)
        }

        do {
            let response: [ColorMatchResponseItem] = try await client.postJSON(
                "/api/color-match",
                body: ColorMatchRequest(sampleHex: sampleHex)
            )

            let mapped = response.compactMap { item -> ColorMatchResult? in
                guard let brand = PaintBrand(rawValue: item.brand) else { return nil }
                let color = PaintColor(number: item.number, name: item.name, family: item.family, hex: item.hex, brand: brand)
                return ColorMatchResult(id: "\(brand.rawValue)-\(item.number)", color: color, confidence: item.confidence)
            }

            return mapped.isEmpty ? try await fallback.match(sampleHex: sampleHex) : mapped
        } catch {
            return try await fallback.match(sampleHex: sampleHex)
        }
    }
}

struct LocalColorMatchService: ColorMatchService {
    private let referenceColors: [PaintColor] = [
        PaintColor(number: "HC-114", name: "Saybrook Sage", family: "Green", hex: "A4AE9F", brand: .benjaminMoore),
        PaintColor(number: "SW 9130", name: "Evergreen Fog", family: "Green", hex: "9EA998", brand: .sherwinWilliams),
        PaintColor(number: "PPU10-11", name: "Sage Brush", family: "Green", hex: "A8B29F", brand: .behr),
        PaintColor(number: "OC-45", name: "Swiss Coffee", family: "White", hex: "E9E1D1", brand: .benjaminMoore),
        PaintColor(number: "SW 6244", name: "Naval", family: "Blue", hex: "2E384D", brand: .sherwinWilliams),
        PaintColor(number: "2163-10", name: "Hale Navy", family: "Blue", hex: "3C4659", brand: .benjaminMoore),
    ]

    func match(sampleHex: String) async throws -> [ColorMatchResult] {
        guard let sampleRGB = rgb(hex: sampleHex) else { return [] }

        let ranked = referenceColors
            .map { color in
                let distance = rgb(hex: color.hex).map { euclideanDistance($0, sampleRGB) } ?? 999
                return (color, distance)
            }
            .sorted { $0.1 < $1.1 }
            .prefix(3)
            .enumerated()
            .map { index, pair in
                let confidence = max(70, min(99, 99 - Int(pair.1 / 4) - (index * 2)))
                return ColorMatchResult(
                    id: pair.0.id,
                    color: pair.0,
                    confidence: confidence
                )
            }

        return Array(ranked)
    }

    private func euclideanDistance(_ lhs: (Double, Double, Double), _ rhs: (Double, Double, Double)) -> Double {
        let r = lhs.0 - rhs.0
        let g = lhs.1 - rhs.1
        let b = lhs.2 - rhs.2
        return sqrt(r * r + g * g + b * b)
    }

    private func rgb(hex: String) -> (Double, Double, Double)? {
        var text = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        text = text.replacingOccurrences(of: "#", with: "")
        guard text.count == 6 else { return nil }

        var value: UInt64 = 0
        guard Scanner(string: text).scanHexInt64(&value) else { return nil }

        let r = Double((value >> 16) & 0xFF)
        let g = Double((value >> 8) & 0xFF)
        let b = Double(value & 0xFF)
        return (r, g, b)
    }
}
