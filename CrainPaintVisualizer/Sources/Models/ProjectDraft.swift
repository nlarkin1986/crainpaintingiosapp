import Foundation

struct ProjectDraft: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var selectedBrand: PaintBrand
    var selectedColors: [PaintColor]
    var selectedSurface: SurfaceType?
    var customSurfaceText: String
    var photoAsset: PhotoAssetReference?
    var photoFileName: String?
    var photoFingerprint: String?
    var updatedAt: Date

    init(
        id: String = "active-project",
        selectedBrand: PaintBrand = .benjaminMoore,
        selectedColors: [PaintColor] = [],
        selectedSurface: SurfaceType? = nil,
        customSurfaceText: String = "",
        photoAsset: PhotoAssetReference? = nil,
        photoFileName: String? = nil,
        photoFingerprint: String? = nil,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.selectedBrand = selectedBrand
        self.selectedColors = selectedColors
        self.selectedSurface = selectedSurface
        self.customSurfaceText = customSurfaceText
        self.photoAsset = photoAsset
        self.photoFileName = photoFileName
        self.photoFingerprint = photoFingerprint
        self.updatedAt = updatedAt
    }

    var hasPhoto: Bool { photoAsset != nil || photoFileName != nil }
    var hasSelections: Bool {
        !selectedColors.isEmpty || hasPhoto || selectedSurface != nil || !customSurfaceText.isEmpty
    }

    var surfaceDescription: String {
        if selectedSurface == .custom {
            let trimmed = customSurfaceText.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? selectedSurface?.rawValue ?? "" : trimmed
        }
        return selectedSurface?.rawValue ?? ""
    }
}
