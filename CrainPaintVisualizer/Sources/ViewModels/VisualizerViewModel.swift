import SwiftUI
import PhotosUI

@MainActor
@Observable
final class VisualizerViewModel {
    var selectedBrand: PaintBrand = .benjaminMoore
    var selectedColors: [PaintColor] = []
    var photo: UIImage?
    var selectedSurface: SurfaceType?
    var customSurfaceText = ""
    var isCompressing = false

    var canAddColor: Bool { selectedColors.count < 5 }
    var hasPhoto: Bool { photo != nil }
    var surfaceDescription: String {
        if selectedSurface == .custom { return customSurfaceText }
        return selectedSurface?.rawValue ?? ""
    }

    func toggleColor(_ color: PaintColor) {
        if let index = selectedColors.firstIndex(of: color) {
            selectedColors.remove(at: index)
        } else if canAddColor {
            selectedColors.append(color)
        }
    }

    func isSelected(_ color: PaintColor) -> Bool {
        selectedColors.contains(color)
    }

    func setPhoto(from data: Data) {
        isCompressing = true
        Task.detached(priority: .userInitiated) {
            let compressed = Self.compressImage(data: data, maxDimension: 2048, quality: 0.8)
            await MainActor.run {
                self.photo = compressed
                self.isCompressing = false
            }
        }
    }

    func reset() {
        selectedBrand = .benjaminMoore
        selectedColors = []
        photo = nil
        selectedSurface = nil
        customSurfaceText = ""
    }

    private nonisolated static func compressImage(data: Data, maxDimension: CGFloat, quality: CGFloat) -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }
        let size = image.size
        let scale = min(maxDimension / max(size.width, size.height), 1.0)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        guard let jpegData = resized.jpegData(compressionQuality: quality) else { return resized }
        if jpegData.count <= 3_500_000 { return UIImage(data: jpegData) ?? resized }

        // Iteratively reduce quality
        var q = quality - 0.1
        while q > 0.1 {
            if let data = resized.jpegData(compressionQuality: q), data.count <= 3_500_000 {
                return UIImage(data: data) ?? resized
            }
            q -= 0.1
        }
        return resized
    }
}
