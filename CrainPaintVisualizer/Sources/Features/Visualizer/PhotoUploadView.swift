import AVFoundation
import PhotosUI
import SwiftUI

struct PhotoUploadView: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @Environment(VisualizerViewModel.self) private var visualizerVM
    @State private var showCamera = false
    @State private var showCameraAlert = false
    @State private var cameraAlertMessage = "Please enable camera access in Settings to take photos."
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isImportingPhoto = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: theme.space16) {
                    WizardHeader(
                        steps: wizardSteps,
                        currentStep: 0,
                        helper: "Upload a clear photo of the room you want to repaint."
                    )

                    uploadSurface
                        .padding(.horizontal, theme.spacingMD)
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("photoUpload.surface")

                    inlineHint

                    Button {
                        router.navigate(to: .colorMatcher)
                    } label: {
                        HStack(spacing: theme.space8) {
                            Image(systemName: "camera.viewfinder")
                            Text("Need to match an object color first? Open Color Matcher")
                        }
                        .font(theme.captionSmall.weight(.semibold))
                        .foregroundStyle(theme.primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("photoUpload.openColorMatcher")
                }
                .padding(.bottom, 120)
            }

            FloatingActionBar {
                AppButton("Continue to Surface", variant: .cta, icon: "arrow.right", isDisabled: !visualizerVM.hasPhoto) {
                    router.navigate(to: .surfacePicker)
                }
                .accessibilityIdentifier("photoUpload.nextStep")
            }
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle("Add Photo")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.success, trigger: visualizerVM.hasPhoto)
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { capture in
                visualizerVM.setPhoto(from: capture.data)
            }
        }
        .alert("Camera Access Required", isPresented: $showCameraAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(cameraAlertMessage)
        }
        .task(id: selectedPhoto) {
            guard let selectedPhoto else { return }
            isImportingPhoto = true
            defer { isImportingPhoto = false }

            if let importedPhoto = try? await selectedPhoto.loadTransferable(type: ImportedPhoto.self) {
                await visualizerVM.setPhoto(from: importedPhoto)
            }
        }
    }

    @ViewBuilder
    private var uploadSurface: some View {
        if let photo = visualizerVM.photo {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(photo.size.width / max(photo.size.height, 1), contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))

                Button {
                    visualizerVM.clearPhoto()
                } label: {
                    Text("Change Photo")
                        .font(theme.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                .padding(12)
            }
        } else if visualizerVM.isCompressing || isImportingPhoto {
            VStack(spacing: theme.spacingSM) {
                ProgressView()
                Text("Preparing your photo...")
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(3 / 4, contentMode: .fit)
            .background(theme.muted)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
        } else {
            VStack(spacing: theme.space16) {
                ZStack {
                    Circle()
                        .fill(theme.card)
                        .frame(width: 80, height: 80)
                        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                    Image(systemName: "arrow.up.doc")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(theme.primary)
                }

                Text("Take or Upload Photo")
                    .font(theme.headline)
                    .foregroundStyle(theme.foreground)

                Text("Capture or select the room you want to visualize.")
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
                    .multilineTextAlignment(.center)

                HStack(spacing: theme.spacingSM) {
                    uploadOptionCard(icon: "camera", label: "Camera") {
                        requestCameraAccess()
                    }

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        uploadOptionCardLabel(icon: "photo.on.rectangle", label: "Library")
                    }
                }
            }
            .padding(theme.spacingLG)
            .frame(maxWidth: .infinity)
            .aspectRatio(3 / 4, contentMode: .fit)
            .background(theme.muted.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radiusLG)
                    .stroke(theme.border, style: StrokeStyle(lineWidth: 1.5, dash: [8]))
            )
        }
    }

    private var inlineHint: some View {
        HStack(alignment: .top, spacing: theme.space8) {
            Image(systemName: "lightbulb")
                .foregroundStyle(theme.primary)
            Text("Use even light and keep the wall or surface fully in frame for the most believable preview.")
                .font(theme.caption)
                .foregroundStyle(theme.mutedForeground)
        }
        .padding(.horizontal, theme.spacingMD)
    }

    private func uploadOptionCard(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            uploadOptionCardLabel(icon: icon, label: label)
        }
    }

    private func uploadOptionCardLabel(icon: String, label: String) -> some View {
        VStack(spacing: theme.spacingSM) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(theme.primary)
            }
            Text(label)
                .font(theme.subhead)
                .foregroundStyle(theme.foreground)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, theme.spacingMD)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusMD)
                .stroke(theme.border, lineWidth: 1)
        )
    }

    private func requestCameraAccess() {
        guard CameraView.isCameraAvailable else {
            cameraAlertMessage = "This device does not have an available camera right now. Use the photo library instead."
            showCameraAlert = true
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    if granted {
                        showCamera = true
                    } else {
                        cameraAlertMessage = "Please enable camera access in Settings to take photos."
                        showCameraAlert = true
                    }
                }
            }
        default:
            cameraAlertMessage = "Please enable camera access in Settings to take photos."
            showCameraAlert = true
        }
    }

    private var wizardSteps: [String] {
        ["Photo", "Surface", "Colors", "Review"]
    }
}
