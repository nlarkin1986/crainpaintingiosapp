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
}

enum VisualizationStatus: Equatable {
    case pending
    case generating
    case complete(originalURL: URL, resultURL: URL, shareId: String)
    case failed(error: String)
}
