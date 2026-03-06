import Foundation

enum AppRoute: Hashable {
    case brandSelector
    case itemPicker
    case photoUpload
    case surfacePicker
    case colorMatcher
    case resultsGallery
    case visualizationDetail(id: String)
}
