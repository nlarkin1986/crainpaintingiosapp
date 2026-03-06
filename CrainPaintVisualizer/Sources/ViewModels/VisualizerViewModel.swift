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

    private var compressionTask: Task<Void, Never>?
    private var compressionRequestID = UUID()

    var canAddColor: Bool { selectedColors.count < 5 }
    var hasPhoto: Bool { photo != nil }
    var surfaceDescription: String {
        if selectedSurface == .custom { return customSurfaceText }
        return selectedSurface?.rawValue ?? ""
    }

    init(processInfo: ProcessInfo = .processInfo) {
        if processInfo.arguments.contains("UITEST_SEED_PHOTO") {
            photo = Self.makeUITestImage()
        }
    }

    func toggleColor(_ color: PaintColor) {
        if let index = selectedColors.firstIndex(of: color) {
            selectedColors.remove(at: index)
        } else if canAddColor {
            selectedColors.append(color)
        }
    }

    @discardableResult
    func addColor(_ color: PaintColor) -> Bool {
        guard !selectedColors.contains(color), canAddColor else { return false }
        if selectedColors.isEmpty {
            selectedBrand = color.brand
        }
        selectedColors.append(color)
        return true
    }

    func startFlow(with color: PaintColor) {
        compressionTask?.cancel()
        selectedBrand = color.brand
        selectedColors = [color]
        photo = nil
        selectedSurface = nil
        customSurfaceText = ""
        isCompressing = false
    }

    func isSelected(_ color: PaintColor) -> Bool {
        selectedColors.contains(color)
    }

    func setPhoto(from data: Data) {
        compressionTask?.cancel()
        let requestID = UUID()
        compressionRequestID = requestID
        isCompressing = true
        photo = nil

        compressionTask = Task(priority: .userInitiated) { [data] in
            let compressed = Self.compressImage(data: data, maxDimension: 2048, quality: 0.8)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard self.compressionRequestID == requestID else { return }
                self.photo = compressed
                self.isCompressing = false
            }
        }
    }

    func reset() {
        compressionTask?.cancel()
        selectedBrand = .benjaminMoore
        selectedColors = []
        photo = nil
        selectedSurface = nil
        customSurfaceText = ""
        isCompressing = false
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

    private nonisolated static func makeUITestImage() -> UIImage {
        let size = CGSize(width: 1200, height: 900)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            UIColor(red: 0.95, green: 0.92, blue: 0.88, alpha: 1).setFill()
            context.fill(rect)

            UIColor(red: 0.82, green: 0.78, blue: 0.72, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: size.height * 0.62, width: size.width, height: size.height * 0.38))

            UIColor(red: 0.72, green: 0.68, blue: 0.62, alpha: 1).setFill()
            context.fill(CGRect(x: size.width * 0.14, y: size.height * 0.28, width: size.width * 0.72, height: size.height * 0.42))

            UIColor(red: 0.62, green: 0.58, blue: 0.52, alpha: 1).setFill()
            context.fill(CGRect(x: size.width * 0.22, y: size.height * 0.42, width: size.width * 0.18, height: size.height * 0.2))
        }
    }
}
