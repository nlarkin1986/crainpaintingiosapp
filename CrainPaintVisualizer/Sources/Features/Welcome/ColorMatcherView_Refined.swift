import AVFoundation
import PhotosUI
import SwiftUI

/// **Expert Panel Refinements Applied:**
/// - Sarah Chen: Simplified header hierarchy, clearer visual structure
/// - Marcus Rodriguez: Native iOS camera patterns, improved touch targets
/// - Priya Kapoor: Enhanced visual design, better color presentation
/// - David Kim: Improved button labels, clearer interaction states
/// - Jordan Taylor: Enhanced VoiceOver labels, better accessibility hints

struct ColorMatcherView_Refined: View {
    @Environment(Theme.self) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(FavoritesViewModel.self) private var favoritesVM
    @Environment(VisualizerViewModel.self) private var visualizerVM

    @State private var viewModel = ColorMatcherViewModel()
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var showCamera = false
    @State private var showCameraAlert = false
    @State private var cameraAlertMessage = "Please enable camera access in Settings to sample a color."
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        ZStack(alignment: .bottom) {
            cameraLayer

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, theme.spacingMD)
                    .padding(.top, 12)

                Spacer()

                // Refined analyzing state
                if viewModel.state == .analyzing {
                    HStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                        Text("Analyzing Color...")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial.opacity(0.8))
                    .clipShape(Capsule())
                }
            }

            bottomCard
        }
        .ignoresSafeArea(edges: .top)
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { image in
                if viewModel.setSample(image: image) {
                    viewModel.analyzeColor()
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
            if let data = try? await selectedPhoto.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                if viewModel.setSample(image: image) {
                    viewModel.analyzeColor()
                }
            }
        }
        .toast(isPresented: $showToast, message: toastMessage, icon: "checkmark.circle.fill")
        .sensoryFeedback(.success, trigger: showToast)
    }

    private var cameraLayer: some View {
        ZStack {
            if let sampleImage = viewModel.sampleImage {
                Image(uiImage: sampleImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [Color.black.opacity(0.92), Color.black.opacity(0.72)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }

            // Refined overlay gradient
            LinearGradient(
                colors: [
                    Color.black.opacity(0.4), 
                    Color.black.opacity(0.1), 
                    Color.black.opacity(0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Enhanced scanning frame
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.9), lineWidth: 3)
                .frame(width: 260, height: 260)
                .overlay(
                    CropCorners()
                        .stroke(theme.primary, lineWidth: 4)
                        .padding(-3)
                )
                .shadow(color: theme.primary.opacity(0.5), radius: 12)

            // Center dot with animation
            Circle()
                .fill(theme.primary)
                .frame(width: 16, height: 16)
                .shadow(color: theme.primary.opacity(0.6), radius: 8)
                .scaleEffect(viewModel.state == .analyzing ? 1.2 : 1.0)
                .opacity(viewModel.state == .analyzing ? 1 : 0.7)
                .animation(
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: viewModel.state == .analyzing
                )

            // Instruction overlay when no sample
            if !viewModel.hasSample {
                VStack(spacing: 16) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(.white.opacity(0.9))
                    Text("Center the color in the frame")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.95))
                }
            }
        }
    }

    private var topBar: some View {
        HStack {
            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial.opacity(0.6))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Close color matcher")

            Spacer()

            // Status pill
            Text(viewModel.hasSample ? "Review Sample" : "Capture Color")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial.opacity(0.6))
                .clipShape(Capsule())

            Spacer()

            // Camera button
            Button {
                requestCameraAccess()
            } label: {
                Image(systemName: "camera.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial.opacity(0.6))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Open camera")
        }
    }

    private var bottomCard: some View {
        let hasSample = viewModel.hasSample
        let libraryLabel = hasSample ? "New Photo" : "Photo Library"

        return VStack(spacing: 20) {
            // Drag handle
            RoundedRectangle(cornerRadius: 3)
                .fill(theme.mutedForeground.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            // Enhanced header
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.hasSample ? "Paint Matches" : "Match Any Color")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(theme.foreground)
                    
                    Text(viewModel.hasSample 
                         ? "\(viewModel.matches.count) closest paint colors" 
                         : "Capture or upload to find exact matches")
                        .font(.system(size: 15))
                        .foregroundStyle(theme.mutedForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                if viewModel.hasSample {
                    // Refined sampled color display
                    Circle()
                        .fill(Color(hex: viewModel.sampledHex))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .strokeBorder(theme.border, lineWidth: 2)
                        )
                        .shadow(
                            color: Color(hex: viewModel.sampledHex).opacity(0.4), 
                            radius: 8, 
                            y: 4
                        )
                }
            }

            // Status banners
            if case .error(let message) = viewModel.state {
                enhancedStateBanner(
                    text: message, 
                    icon: "exclamationmark.triangle.fill",
                    color: theme.destructive
                )
            } else if viewModel.state == .analyzing {
                HStack(spacing: 12) {
                    ProgressView()
                        .tint(theme.primary)
                    Text("Analyzing color sample...")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(theme.foreground)
                    Spacer()
                }
                .padding(16)
                .background(theme.primary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if !viewModel.hasSample {
                enhancedStateBanner(
                    text: "Capture or upload a painted surface to find the closest catalog match",
                    icon: "camera.viewfinder",
                    color: theme.mutedForeground
                )
            } else if viewModel.matches.isEmpty {
                enhancedStateBanner(
                    text: "No strong match found. Try better lighting or a different angle.",
                    icon: "exclamationmark.circle",
                    color: theme.mutedForeground
                )
            } else {
                // Match results
                VStack(spacing: 12) {
                    ForEach(viewModel.matches) { match in
                        refinedMatchRow(match)
                    }
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                // Primary camera button
                Button {
                    viewModel.retake()
                    requestCameraAccess()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "camera")
                            .font(.system(size: 16, weight: .semibold))
                        Text(viewModel.hasSample ? "Scan Again" : "Use Camera")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(ScaleButtonStyle())

                // Photo library picker
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 16, weight: .semibold))
                        Text(libraryLabel)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(theme.foreground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(theme.border, lineWidth: 2)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.horizontal, theme.spacingMD)
        .padding(.bottom, theme.spacingLG)
        .padding(.top, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    private func refinedMatchRow(_ match: ColorMatchResult) -> some View {
        HStack(spacing: 16) {
            // Color swatch
            RoundedRectangle(cornerRadius: 12)
                .fill(match.color.color)
                .frame(width: 64, height: 64)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(theme.border, lineWidth: 2)
                )
                .shadow(color: match.color.color.opacity(0.3), radius: 6, y: 3)

            // Color info
            VStack(alignment: .leading, spacing: 6) {
                confidenceBadge(match.confidence)
                
                Text(match.color.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.foreground)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(match.color.brand.displayName)
                    Text("·")
                    Text(match.color.number)
                }
                .font(.system(size: 13))
                .foregroundStyle(theme.mutedForeground)
            }

            Spacer()

            // Add button
            Button {
                let addedFavorite = favoritesVM.addFavorite(match.color)
                let addedPalette = visualizerVM.addColor(match.color)
                toastMessage = addedFavorite || addedPalette ? "Color added" : "Already saved"
                showToast = true
            } label: {
                Image(systemName: favoritesVM.isFavorite(match.color) ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(
                        favoritesVM.isFavorite(match.color) ? theme.primary : theme.primary
                    )
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .accessibilityLabel(favoritesVM.isFavorite(match.color) ? "Already saved" : "Add to favorites")
        }
        .padding(16)
        .background(
            match.confidence >= 96 
                ? theme.primary.opacity(0.06) 
                : theme.card
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    match.confidence >= 96 ? theme.primary.opacity(0.2) : theme.border,
                    lineWidth: match.confidence >= 96 ? 2 : 1
                )
        )
    }

    @ViewBuilder
    private func confidenceBadge(_ confidence: Int) -> some View {
        let text = "\(confidence)% MATCH"
        if confidence >= 96 {
            // Best match
            Text(text)
                .font(.system(size: 11, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(theme.primary)
                .clipShape(Capsule())
        } else if confidence >= 90 {
            // Good match
            Text(text)
                .font(.system(size: 11, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(theme.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(theme.primary.opacity(0.1))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(theme.primary, lineWidth: 1.5)
                )
        } else {
            // Okay match
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(theme.mutedForeground)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(theme.muted)
                .clipShape(Capsule())
        }
    }

    private func enhancedStateBanner(text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(theme.foreground)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(16)
        .background(theme.muted)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func requestCameraAccess() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            cameraAlertMessage = "This device does not have an available camera. Use the photo library instead."
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
                        cameraAlertMessage = "Please enable camera access in Settings to sample colors."
                        showCameraAlert = true
                    }
                }
            }
        default:
            cameraAlertMessage = "Please enable camera access in Settings to sample colors."
            showCameraAlert = true
        }
    }
}

private struct CropCorners: Shape {
    func path(in rect: CGRect) -> Path {
        let len: CGFloat = 28
        var path = Path()

        // Top left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + len))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + len, y: rect.minY))

        // Top right
        path.move(to: CGPoint(x: rect.maxX - len, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + len))

        // Bottom right
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - len))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - len, y: rect.maxY))

        // Bottom left
        path.move(to: CGPoint(x: rect.minX + len, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - len))

        return path
    }
}
