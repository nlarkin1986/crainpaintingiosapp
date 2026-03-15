import AVFoundation
import ObjectiveC
import SwiftUI
import UIKit

struct CapturedPhoto {
    let data: Data
    let captureContext: ColorMatchCaptureContext?
}

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var cameraModel = CameraCaptureModel()

    let onCapture: (CapturedPhoto) -> Void
    var onCancel: (() -> Void)? = nil

    static var isCameraAvailable: Bool {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if cameraModel.isConfigured {
                CameraPreviewRepresentable(session: cameraModel.session)
                    .ignoresSafeArea()
            } else {
                ProgressView()
                    .tint(.white)
            }

            VStack {
                HStack {
                    Button {
                        onCancel?()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.35))
                            .clipShape(Circle())
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Spacer()

                Button {
                    Task {
                        if let capturedPhoto = try? await cameraModel.capturePhoto() {
                            onCapture(capturedPhoto)
                            dismiss()
                        }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(cameraModel.isCapturing ? 0.45 : 0.92))
                            .frame(width: 84, height: 84)
                        Circle()
                            .stroke(.white.opacity(0.45), lineWidth: 6)
                            .frame(width: 96, height: 96)
                    }
                }
                .disabled(!cameraModel.canCapture)
                .padding(.bottom, 44)
            }
        }
        .task {
            await cameraModel.start()
        }
        .onDisappear {
            cameraModel.stop()
        }
    }
}

private struct CameraPreviewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.videoPreviewLayer.session = session
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }
}

private final class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

@MainActor
@Observable
private final class CameraCaptureModel: NSObject {
    let session = AVCaptureSession()

    var isConfigured = false
    var isCapturing = false
    var canCapture: Bool {
        isConfigured && !isCapturing
    }

    private let photoOutput = AVCapturePhotoOutput()
    private var activeDevice: AVCaptureDevice?

    func start() async {
        guard !isConfigured else {
            if !session.isRunning {
                session.startRunning()
            }
            return
        }

        do {
            try configureSession()
            isConfigured = true
            if !session.isRunning {
                session.startRunning()
            }
        } catch {
            isConfigured = false
        }
    }

    func stop() {
        if session.isRunning {
            session.stopRunning()
        }
    }

    func capturePhoto() async throws -> CapturedPhoto {
        guard canCapture else {
            throw PhotoProcessingError.invalidImageData
        }

        isCapturing = true
        defer { isCapturing = false }

        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        settings.photoQualityPrioritization = .quality
        settings.maxPhotoDimensions = photoOutput.maxPhotoDimensions

        let captureContext = makeCaptureContext()

        return try await withCheckedThrowingContinuation { continuation in
            let delegate = PhotoCaptureDelegate(
                captureContext: captureContext,
                onComplete: { result in
                    continuation.resume(with: result)
                }
            )
            photoOutput.capturePhoto(with: settings, delegate: delegate)
            objc_setAssociatedObject(
                photoOutput,
                &PhotoCaptureDelegate.associationKey,
                delegate,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    private func configureSession() throws {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .photo

        if let currentInput = session.inputs.first {
            session.removeInput(currentInput)
        }

        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .back
        )
        guard let device = discoverySession.devices.first else {
            throw PhotoProcessingError.invalidImageData
        }
        activeDevice = device

        let input = try AVCaptureDeviceInput(device: device)
        if session.canAddInput(input) {
            session.addInput(input)
        }

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.maxPhotoQualityPrioritization = .quality

            if let preferredDimensions = device.activeFormat.supportedMaxPhotoDimensions.max(
                by: { lhs, rhs in
                    Int(lhs.width) * Int(lhs.height) < Int(rhs.width) * Int(rhs.height)
                }
            ) {
                photoOutput.maxPhotoDimensions = preferredDimensions
            }
        }
    }

    private func makeCaptureContext() -> ColorMatchCaptureContext {
        let whiteBalanceGains = activeDevice?.deviceWhiteBalanceGains
        return ColorMatchCaptureContext(
            flashUsed: false,
            exposureBias: activeDevice.map { Double($0.exposureTargetBias) },
            whiteBalanceMode: activeDevice.map { String(describing: $0.whiteBalanceMode) },
            whiteBalanceTemperature: nil,
            whiteBalanceTint: nil,
            whiteBalanceRedGain: whiteBalanceGains.map { Double($0.redGain) },
            whiteBalanceGreenGain: whiteBalanceGains.map { Double($0.greenGain) },
            whiteBalanceBlueGain: whiteBalanceGains.map { Double($0.blueGain) },
            iso: activeDevice.map { Double($0.iso) },
            exposureDurationSeconds: activeDevice.map { CMTimeGetSeconds($0.exposureDuration) },
            deviceModel: UIDevice.current.model,
            capturedAt: .now,
            latitude: nil,
            longitude: nil,
            source: "ios_camera"
        )
    }
}

private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    static var associationKey = 0

    let captureContext: ColorMatchCaptureContext?
    let onComplete: (Result<CapturedPhoto, Error>) -> Void

    init(
        captureContext: ColorMatchCaptureContext?,
        onComplete: @escaping (Result<CapturedPhoto, Error>) -> Void
    ) {
        self.captureContext = captureContext
        self.onComplete = onComplete
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        defer {
            objc_setAssociatedObject(
                output,
                &Self.associationKey,
                nil,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }

        if let error {
            onComplete(.failure(error))
            return
        }

        guard let data = photo.fileDataRepresentation() else {
            onComplete(.failure(PhotoProcessingError.invalidImageData))
            return
        }

        onComplete(.success(CapturedPhoto(data: data, captureContext: captureContext)))
    }
}
