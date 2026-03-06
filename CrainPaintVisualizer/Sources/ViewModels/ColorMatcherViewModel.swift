import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import UIKit

struct ColorMatchResult: Identifiable, Hashable {
    let id: String
    let color: PaintColor
    let confidence: Int
}

enum ColorMatcherState: Equatable {
    case aligning
    case analyzing
    case results
    case noMatch
    case error(String)
}

@MainActor
@Observable
final class ColorMatcherViewModel {
    var state: ColorMatcherState = .aligning
    var matches: [ColorMatchResult] = []
    var sampledHex = "A4AE9F"
    var sampleImage: UIImage?
    var isTorchOn = false
    var errorMessage: String?

    private let service: ColorMatchService
    private var analysisTask: Task<Void, Never>?

    init(service: ColorMatchService = RemoteColorMatchService()) {
        self.service = service
    }

    var hasSample: Bool { sampleImage != nil }

    @discardableResult
    func setSample(image: UIImage) -> Bool {
        analysisTask?.cancel()
        matches = []
        errorMessage = nil

        guard let sampledHex = Self.extractSampleHex(from: image) else {
            sampleImage = nil
            state = .error("Couldn’t read a clear color from that photo. Try centering the sample and using even light.")
            return false
        }

        sampleImage = image
        self.sampledHex = sampledHex
        state = .aligning
        return true
    }

    func analyzeColor() {
        guard hasSample else {
            state = .aligning
            return
        }

        analysisTask?.cancel()
        state = .analyzing
        errorMessage = nil
        matches = []

        analysisTask = Task {
            try? await Task.sleep(for: .milliseconds(650))
            guard !Task.isCancelled else { return }

            do {
                let detected = try await service.match(sampleHex: sampledHex)
                if detected.isEmpty {
                    state = .noMatch
                    return
                }

                matches = detected
                state = .results
            } catch {
                errorMessage = error.localizedDescription
                state = .error("Couldn’t match this color right now. Check connection and retry.")
            }
        }
    }

    func retake() {
        analysisTask?.cancel()
        state = .aligning
        errorMessage = nil
        matches = []
        sampleImage = nil
    }

    private nonisolated static func extractSampleHex(from image: UIImage) -> String? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let extent = ciImage.extent.integral
        guard !extent.isEmpty else { return nil }

        let focusSize = max(min(extent.width, extent.height) * 0.28, 24)
        let focusRect = CGRect(
            x: extent.midX - (focusSize / 2),
            y: extent.midY - (focusSize / 2),
            width: focusSize,
            height: focusSize
        )

        let filter = CIFilter.areaAverage()
        filter.inputImage = ciImage.cropped(to: focusRect)
        filter.extent = focusRect

        guard let outputImage = filter.outputImage else { return nil }

        let context = CIContext(options: [.workingColorSpace: NSNull()])
        var rgba = [UInt8](repeating: 0, count: 4)
        context.render(
            outputImage,
            toBitmap: &rgba,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )

        return String(format: "%02X%02X%02X", rgba[0], rgba[1], rgba[2])
    }
}
