import Foundation

enum AppRoute: Hashable {
    case brandSelector
    case itemPicker
    case photoUpload
    case surfacePicker
    case colorMatcher
    case resultsGallery
    case visualizationDetail(id: String)
    case reportsHome
    case masterReport(reportId: String)
    case sampleOutput(reportId: String, chapterId: String?)
    case consultationCheckout(reportId: String)
}
