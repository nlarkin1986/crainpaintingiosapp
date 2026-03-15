import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import UIKit

enum ColorMatcherAnalysisPhase: Int, CaseIterable, Equatable {
    case readingSample
    case comparingCatalogs
    case rankingMatches
}

struct ColorMatcherTiming: Equatable {
    let captureConfirmationDuration: Duration
    let analysisPhaseDuration: Duration
    let resultRevealInterval: Duration

    static let `default` = ColorMatcherTiming(
        captureConfirmationDuration: .milliseconds(400),
        analysisPhaseDuration: .milliseconds(900),
        resultRevealInterval: .milliseconds(120)
    )

    static let immediate = ColorMatcherTiming(
        captureConfirmationDuration: .zero,
        analysisPhaseDuration: .zero,
        resultRevealInterval: .zero
    )
}

struct ColorMatchResult: Identifiable, Hashable, Sendable {
    let id: String
    let color: PaintColor
    let confidence: Int
    let rationale: String
}

enum ColorMatcherState: Equatable {
    case capturing
    case sampleLocked
    case analyzing(ColorMatcherAnalysisPhase)
    case results
    case needsRetake
    case error(String)
}

extension ColorMatcherState {
    var isAnalyzing: Bool {
        if case .analyzing = self {
            return true
        }
        return false
    }
}

@MainActor
@Observable
final class ColorMatcherViewModel {
    var state: ColorMatcherState = .capturing
    var matches: [ColorMatchResult] = []
    var sampledHex = "A4AE9F"
    var sampleImage: UIImage?
    var sampleCropImage: UIImage?
    var sampleWarnings: [String] = []
    var sampleQuality: ColorMatchQuality = .good
    var sampleDiagnostics: ColorMatchDiagnostics = .empty
    var matchMethod: ColorMatchMethod = .deterministicCV
    var isTorchOn = false
    var errorMessage: String?

    private let service: ColorMatchService
    private let timing: ColorMatcherTiming
    private var analysisTask: Task<Void, Never>?
    private var phaseTask: Task<Void, Never>?
    private var sampleFocusRect: ColorMatchFocusRect?
    private var captureContext: ColorMatchCaptureContext?

    init(
        service: ColorMatchService = RemoteColorMatchService(),
        timing: ColorMatcherTiming = .default
    ) {
        self.service = service
        self.timing = timing
    }

    var hasSample: Bool { sampleImage != nil }
    var analysisPhase: ColorMatcherAnalysisPhase? {
        if case .analyzing(let phase) = state {
            return phase
        }
        return nil
    }
    var captureConfirmationDuration: Duration { timing.captureConfirmationDuration }
    var resultRevealInterval: Duration { timing.resultRevealInterval }

    @discardableResult
    func setSample(
        image: UIImage,
        focusRect: ColorMatchFocusRect? = nil,
        captureContext: ColorMatchCaptureContext? = nil
    ) -> Bool {
        cancelTasks()
        matches = []
        errorMessage = nil
        sampleWarnings = []
        sampleQuality = .good
        sampleDiagnostics = .empty
        matchMethod = .deterministicCV

        guard let sampledHex = Self.extractSampleHex(from: image, focusRect: focusRect) else {
            sampleImage = nil
            sampleCropImage = nil
            sampleFocusRect = nil
            self.captureContext = nil
            state = .error("Couldn’t read a clear color from that photo. Try centering the sample and using even light.")
            return false
        }

        sampleImage = image
        sampleCropImage = Self.extractSampleCropImage(from: image, focusRect: focusRect)
        sampleFocusRect = focusRect
        self.captureContext = captureContext
        self.sampledHex = sampledHex
        state = .sampleLocked
        return true
    }

    func analyzeColor() {
        guard let sampleImage else {
            state = .capturing
            return
        }

        cancelTasks()
        state = .sampleLocked
        errorMessage = nil
        matches = []

        analysisTask = Task {
            if timing.captureConfirmationDuration > .zero {
                try? await Task.sleep(for: timing.captureConfirmationDuration)
            }
            guard !Task.isCancelled else { return }

            state = .analyzing(.readingSample)
            startPhaseCycling()

            do {
                let response = try await service.match(
                    image: sampleImage,
                    focusRect: sampleFocusRect,
                    captureContext: captureContext
                )
                guard !Task.isCancelled else { return }
                phaseTask?.cancel()

                sampledHex = response.sampleHex
                sampleWarnings = response.warnings
                sampleQuality = response.quality
                sampleDiagnostics = response.diagnostics
                matchMethod = response.matchMethod

                if response.matches.isEmpty {
                    matches = []
                    state = .needsRetake
                    return
                }

                matches = response.matches
                state = .results
            } catch {
                phaseTask?.cancel()
                guard !Task.isCancelled else { return }
                let message = (error as? LocalizedError)?.errorDescription
                    ?? error.localizedDescription
                errorMessage = message
                state = .error(message)
            }
        }
    }

    func cancelAnalysis() {
        guard hasSample else {
            state = .capturing
            return
        }

        cancelTasks()
        matches = []
        errorMessage = nil
        sampleWarnings = []
        sampleQuality = .good
        sampleDiagnostics = .empty
        matchMethod = .deterministicCV
        state = .sampleLocked
    }

    func retake() {
        cancelTasks()
        state = .capturing
        errorMessage = nil
        matches = []
        sampleImage = nil
        sampleCropImage = nil
        sampleWarnings = []
        sampleQuality = .good
        sampleDiagnostics = .empty
        matchMethod = .deterministicCV
        sampleFocusRect = nil
        captureContext = nil
    }

    private func startPhaseCycling() {
        guard timing.analysisPhaseDuration > .zero else { return }

        phaseTask?.cancel()
        phaseTask = Task {
            var phaseIndex = 0
            let phases = ColorMatcherAnalysisPhase.allCases

            while !Task.isCancelled {
                try? await Task.sleep(for: timing.analysisPhaseDuration)
                guard !Task.isCancelled else { return }
                guard state.isAnalyzing else { return }

                phaseIndex = min(phaseIndex + 1, phases.count - 1)
                state = .analyzing(phases[phaseIndex])
            }
        }
    }

    private func cancelTasks() {
        analysisTask?.cancel()
        phaseTask?.cancel()
        analysisTask = nil
        phaseTask = nil
    }

    private nonisolated static func extractSampleHex(
        from image: UIImage,
        focusRect: ColorMatchFocusRect?
    ) -> String? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let extent = ciImage.extent.integral
        guard !extent.isEmpty else { return nil }

        let sampleRect: CGRect
        if let focusRect {
            sampleRect = CGRect(
                x: extent.origin.x + (extent.width * focusRect.x),
                y: extent.origin.y + (extent.height * focusRect.y),
                width: max(1, extent.width * focusRect.width),
                height: max(1, extent.height * focusRect.height)
            ).intersection(extent)
        } else {
            let focusSize = max(min(extent.width, extent.height) * 0.28, 24)
            sampleRect = CGRect(
                x: extent.midX - (focusSize / 2),
                y: extent.midY - (focusSize / 2),
                width: focusSize,
                height: focusSize
            )
        }

        guard !sampleRect.isEmpty else { return nil }

        let filter = CIFilter.areaAverage()
        filter.inputImage = ciImage.cropped(to: sampleRect)
        filter.extent = sampleRect

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

    private nonisolated static func extractSampleCropImage(
        from image: UIImage,
        focusRect: ColorMatchFocusRect?
    ) -> UIImage? {
        let normalizedRect: CGRect
        if let focusRect {
            normalizedRect = CGRect(
                x: focusRect.x,
                y: focusRect.y,
                width: focusRect.width,
                height: focusRect.height
            )
        } else {
            normalizedRect = CGRect(x: 0.36, y: 0.36, width: 0.28, height: 0.28)
        }

        let imageRect = CGRect(origin: .zero, size: image.size)
        let cropRect = CGRect(
            x: imageRect.width * normalizedRect.origin.x,
            y: imageRect.height * normalizedRect.origin.y,
            width: imageRect.width * normalizedRect.width,
            height: imageRect.height * normalizedRect.height
        ).intersection(imageRect)

        guard !cropRect.isEmpty else { return nil }

        let targetSize = cropRect.size
        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            UIColor.white.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: targetSize)).fill()
            image.draw(
                in: CGRect(
                    x: -cropRect.origin.x,
                    y: -cropRect.origin.y,
                    width: image.size.width,
                    height: image.size.height
                )
            )
        }
    }
}
