import AVFoundation
import PhotosUI
import SwiftUI

struct PhotoUploadView: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @Environment(VisualizerViewModel.self) private var visualizerVM
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showCamera = false
    @State private var showCameraAlert = false
    @State private var cameraAlertMessage = "Please enable camera access in Settings to take photos."
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isImportingPhoto = false
    @State private var hasAppeared = false
    @State private var cameraTapCount = 0
    @State private var libraryTapCount = 0

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: theme.space24) {
                    WizardHeader(
                        steps: wizardSteps,
                        currentStep: 0,
                        helper: "Upload a clear photo of the room you want to repaint."
                    )

                    uploadSurface
                        .padding(.horizontal, theme.spacingMD)
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("photoUpload.surface")
                }
                .padding(.bottom, 120)
            }

            FloatingActionBar {
                AppButton("Continue to Surface", variant: .cta, icon: "arrow.right", isDisabled: !visualizerVM.hasPhoto) {
                    router.navigate(to: .surfacePicker)
                }
                .animation(reduceMotion ? .none : Theme.animationDefault, value: visualizerVM.hasPhoto)
                .accessibilityIdentifier("photoUpload.nextStep")
            }
        }
        .background(theme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Add Photo")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.success, trigger: visualizerVM.hasPhoto)
        .sensoryFeedback(.impact(weight: .light), trigger: cameraTapCount)
        .sensoryFeedback(.impact(weight: .light), trigger: libraryTapCount)
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

            do {
                if let data = try await selectedPhoto.loadTransferable(type: Data.self) {
                    visualizerVM.setPhoto(from: data)
                }
            } catch {
                showCameraAlert = true
                cameraAlertMessage = "Unable to load the selected photo. Please try a different image."
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
                Text("Take or Upload Photo")
                    .font(theme.heading2)
                    .foregroundStyle(theme.foreground)

                Text("Capture or select the room you want to visualize")
                    .font(theme.bodyDefault)
                    .foregroundStyle(theme.mutedForeground)
                    .multilineTextAlignment(.center)

                HStack(spacing: theme.spacingSM) {
                    uploadOptionCard(icon: "camera", label: "Camera") {
                        cameraTapCount += 1
                        requestCameraAccess()
                    }

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        uploadOptionCardLabel(icon: "photo.on.rectangle", label: "Library")
                    }
                    .onChange(of: selectedPhoto) { libraryTapCount += 1 }
                }

                Divider()
                    .foregroundStyle(theme.border)

                // Inline tip
                HStack(alignment: .top, spacing: theme.space8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(theme.primary.opacity(0.7))
                    Text("Use even lighting for the most believable preview")
                        .font(theme.captionSmall)
                        .foregroundStyle(theme.mutedForeground)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

            }
            .padding(theme.space24)
            .frame(maxWidth: .infinity)
            .background(theme.card)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radiusXL)
                    .stroke(theme.border.opacity(0.8), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
            .offset(y: hasAppeared ? 0 : 30)
            .opacity(hasAppeared ? 1 : 0)
            .animation(reduceMotion ? .none : .spring(response: 0.6, dampingFraction: 0.8), value: hasAppeared)
            .onAppear {
                guard !hasAppeared else { return }
                hasAppeared = true
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
