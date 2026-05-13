import Foundation

struct Visualization: Identifiable, Hashable {
    let id: String
    let colorName: String
    let colorHex: String
    let colorCode: String
    let roomName: String
    let beforeImageName: String
    let afterImageName: String
    let surface: String
    var originalImageURL: URL? = nil
    var resultImageURL: URL? = nil
    var shareId: String? = nil
    var isAIGenerated: Bool = false

    var inferredBrand: PaintBrand {
        colorCode.uppercased().contains("SW") ? .sherwinWilliams : .benjaminMoore
    }

    var hasReferenceImages: Bool {
        resultImageURL != nil || (!beforeImageName.isEmpty && !afterImageName.isEmpty)
    }

    var asPaintColor: PaintColor {
        PaintColor(number: colorCode, name: colorName, family: "Curated", hex: colorHex, brand: inferredBrand)
    }
}
