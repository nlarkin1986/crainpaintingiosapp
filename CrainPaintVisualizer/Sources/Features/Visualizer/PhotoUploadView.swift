import SwiftUI
import PhotosUI
import AVFoundation

struct PhotoUploadView: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @Environment(VisualizerViewModel.self) private var visualizerVM
    @State private var showCamera = false
    @State private var showCameraAlert = false
    @State private var cameraAlertMessage = "Please enable camera access in Settings to take photos."
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: theme.spacingMD) {
                    BrandedHeader(title: "Upload Your Space")

                    StepProgressView(steps: ["Color", "Photo", "Surface"], currentStep: 1, icons: ["paintpalette", "camera", "sofa"])

                    // Upload zone
                    if let photo = visualizerVM.photo {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: photo)
                                .resizable()
                                .aspectRatio(3/4, contentMode: .fit)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))

                            Button {
                                visualizerVM.photo = nil
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
                        .padding(.horizontal, theme.spacingLG)
                    } else if visualizerVM.isCompressing {
                        VStack(spacing: theme.spacingSM) {
                            ProgressView()
                            Text("Preparing your photo...")
                                .font(theme.caption)
                                .foregroundStyle(theme.mutedForeground)
                        }
                        .frame(maxWidth: .infinity)
                        .aspectRatio(3/4, contentMode: .fit)
                        .background(theme.muted)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
                        .padding(.horizontal, theme.spacingLG)
                    } else {
                        // Empty upload zone
                        VStack(spacing: theme.spacingMD) {
                            // Upload icon in white circle
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

                            Text("Capture or select a photo of the room you want to visualize")
                                .font(theme.caption)
                                .foregroundStyle(theme.mutedForeground)
                                .multilineTextAlignment(.center)

                            // Camera & Library as vertical 2-column cards
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
                        .aspectRatio(3/4, contentMode: .fit)
                        .background(theme.muted.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.radiusLG)
                                .stroke(theme.border, style: StrokeStyle(lineWidth: 1.5, dash: [8]))
                        )
                        .padding(.horizontal, theme.spacingLG)
                    }

                    // Pro Tip — primary tinted
                    HStack(alignment: .top, spacing: theme.spacingSM) {
                        Image(systemName: "lightbulb")
                            .foregroundStyle(theme.primary)
                        Text("Pro Tip: Use natural lighting and capture the full wall for best results.")
                            .font(theme.caption)
                            .foregroundStyle(theme.foreground)
                    }
                    .padding(theme.spacingSM)
                    .background(theme.primary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: theme.radiusSM))
                    .padding(.horizontal, theme.spacingLG)
                }
            }

            FloatingActionBar {
                AppButton("Next Step", variant: .cta, icon: "arrow.right", isDisabled: !visualizerVM.hasPhoto) {
                    router.navigate(to: .surfacePicker)
                }
                .accessibilityIdentifier("photoUpload.nextStep")
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.success, trigger: visualizerVM.hasPhoto)
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { image in
                if let data = image.jpegData(compressionQuality: 0.9) {
                    visualizerVM.setPhoto(from: data)
                }
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
            if let data = try? await selectedPhoto.loadTransferable(type: Data.self) {
                visualizerVM.setPhoto(from: data)
            }
        }
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
                    .fill(theme.primary.opacity(0.1))
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
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
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
}
