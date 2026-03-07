import SwiftUI
import PhotosUI
import AVFoundation

struct PhotoUploadView: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @Environment(VisualizerViewModel.self) private var visualizerVM
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showCamera = false
    @State private var showCameraAlert = false
    @State private var cameraAlertMessage = "Please enable camera access in Settings to take photos."
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showSuccessAnimation = false
    @State private var uploadProgress: Double = 0
    
    private var roomPhotoAspectRatio: CGFloat {
        guard let photo = visualizerVM.photo, photo.size.height > 0 else { return 3.0 / 4.0 }
        return photo.size.width / photo.size.height
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: theme.spacingMD) {
                    
                    // ✅ Step indicator badge
                    stepIndicatorBadge

                    // Upload zone with success animation
                    if let photo = visualizerVM.photo {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: photo)
                                .resizable()
                                .aspectRatio(roomPhotoAspectRatio, contentMode: .fit)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
                                .overlay(
                                    RoundedRectangle(cornerRadius: theme.radiusLG)
                                        .stroke(ColorTokens.feedbackSuccess, lineWidth: 3)
                                        .opacity(showSuccessAnimation ? 1 : 0)
                                        .scaleEffect(showSuccessAnimation ? 1.0 : 0.9)
                                        .animation(.springBouncy, value: showSuccessAnimation)
                                )
                            
                            // Success checkmark
                            if showSuccessAnimation && !reduceMotion {
                                VStack {
                                    HStack {
                                        Spacer()
                                        ZStack {
                                            Circle()
                                                .fill(ColorTokens.feedbackSuccess)
                                                .frame(width: 48, height: 48)
                                                .shadow(color: ColorTokens.feedbackSuccess.opacity(0.4), radius: 12, y: 4)
                                            
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                        .bounce(trigger: showSuccessAnimation ? 1 : 0)
                                        .padding(16)
                                    }
                                    Spacer()
                                }
                            }

                            Button {
                                visualizerVM.photo = nil
                                showSuccessAnimation = false
                            } label: {
                                Text("Change Photo")
                                    .font(theme.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }
                            .padding(12)
                            .offset(y: 44) // Move below success indicator
                        }
                        .padding(.horizontal, theme.spacingLG)
                    } else if visualizerVM.isCompressing {
                        // Enhanced loading state with progress
                        VStack(spacing: theme.spacingSM) {
                            ZStack {
                                Circle()
                                    .stroke(theme.muted, lineWidth: 4)
                                    .frame(width: 60, height: 60)
                                
                                Circle()
                                    .trim(from: 0, to: uploadProgress)
                                    .stroke(theme.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                    .frame(width: 60, height: 60)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.easeInOut(duration: 0.5), value: uploadProgress)
                                
                                Image(systemName: "photo")
                                    .font(.system(size: 24))
                                    .foregroundStyle(theme.primary)
                            }
                            
                            Text("Preparing your photo...")
                                .font(theme.caption)
                                .foregroundStyle(theme.mutedForeground)
                            
                            Text("\(Int(uploadProgress * 100))%")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(theme.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .aspectRatio(roomPhotoAspectRatio, contentMode: .fit)
                        .background(theme.muted)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
                        .padding(.horizontal, theme.spacingLG)
                        .onAppear {
                            // Simulate upload progress
                            withAnimation(.easeInOut(duration: 1.5)) {
                                uploadProgress = 1.0
                            }
                        }
                    } else {
                        // Empty upload zone with pulse animation
                        VStack(spacing: theme.spacingMD) {
                            // Upload icon with pulse effect
                            ZStack {
                                Circle()
                                    .fill(theme.card)
                                    .frame(width: 80, height: 80)
                                    .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                                Image(systemName: "arrow.up.doc")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundStyle(theme.primary)
                            }
                            .pulse(isActive: true)

                            Text("Show Us Your Space")
                                .font(theme.headline)
                                .foregroundStyle(theme.foreground)

                            Text("Capture or select a photo of the room you want to visualize")
                                .font(theme.caption)
                                .foregroundStyle(theme.mutedForeground)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, theme.spacingLG)

                            // Camera & Library with enhanced buttons
                            HStack(spacing: theme.spacingSM) {
                                uploadOptionCard(icon: "camera.fill", label: "Camera") {
                                    requestCameraAccess()
                                }

                                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                    uploadOptionCardLabel(icon: "photo.on.rectangle.angled", label: "Library")
                                }
                                .buttonStyle(EnhancedButtonStyle())
                            }
                            .padding(.horizontal, theme.spacingLG)
                        }
                        .padding(.vertical, theme.spacingXL)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(roomPhotoAspectRatio, contentMode: .fit)
                        .background(
                            LinearGradient(
                                colors: [
                                    theme.muted.opacity(0.3),
                                    theme.muted.opacity(0.5),
                                    theme.muted.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.radiusLG)
                                .stroke(theme.border, style: StrokeStyle(lineWidth: 2, dash: [8, 8]))
                        )
                        .padding(.horizontal, theme.spacingLG)
                    }

                    // Pro Tip with better styling
                    HStack(alignment: .top, spacing: theme.spacingSM) {
                        ZStack {
                            Circle()
                                .fill(ColorTokens.sunshine.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(ColorTokens.sunshine)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Pro Tip")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(theme.foreground)
                            
                            Text("Use natural lighting and capture the full wall for best results. Avoid shadows and reflections.")
                                .font(theme.caption)
                                .foregroundStyle(theme.mutedForeground)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(theme.spacingMD)
                    .background(ColorTokens.sunshine.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radiusMD)
                            .stroke(ColorTokens.sunshine.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, theme.spacingLG)
                    .pulse(isActive: !visualizerVM.hasPhoto)
                }
            }

            FloatingActionBar {
                AppButton("Next Step", variant: .cta, icon: "arrow.right", isDisabled: !visualizerVM.hasPhoto) {
                    router.navigate(to: .surfacePicker)
                }
                .accessibilityIdentifier("photoUpload.nextStep")
            }
        }
        .navigationTitle("Upload Your Photo")
        .navigationBarTitleDisplayMode(.large)
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
                uploadProgress = 0
                visualizerVM.setPhoto(from: data)
            }
        }
        .onChange(of: visualizerVM.hasPhoto) { _, hasPhoto in
            if hasPhoto {
                // Trigger success animation
                withAnimation(.springBouncy.delay(0.3)) {
                    showSuccessAnimation = true
                }
                
                // Auto-dismiss after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation {
                        showSuccessAnimation = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var stepIndicatorBadge: some View {
        HStack {
            HStack(spacing: 8) {
                // Step 2 indicator with completed step 1
                HStack(spacing: 6) {
                    stepIndicatorDot(number: 1, isActive: false, isComplete: true)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(theme.mutedForeground)
                    stepIndicatorDot(number: 2, isActive: true, isComplete: false)
                }
                Text("Step 2 of 3")
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
            }
            Spacer()
        }
        .padding(.horizontal, theme.spacingLG)
        .padding(.top, 8)
    }
    
    private func stepIndicatorDot(number: Int, isActive: Bool, isComplete: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isActive ? theme.actionPrimary : isComplete ? ColorTokens.feedbackSuccess : theme.muted)
                .frame(width: 24, height: 24)
            
            if isComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Text("\(number)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isActive ? .white : theme.mutedForeground)
            }
        }
    }
    
    // MARK: - Upload Options
    private func uploadOptionCard(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            uploadOptionCardLabel(icon: icon, label: label)
        }
        .buttonStyle(EnhancedButtonStyle())
    }

    private func uploadOptionCardLabel(icon: String, label: String) -> some View {
        VStack(spacing: theme.spacingSM) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [theme.primary.opacity(0.15), theme.primary.opacity(0.08)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(theme.primary)
            }
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(theme.foreground)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, theme.spacingLG)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusLG)
                .stroke(theme.border, lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
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
