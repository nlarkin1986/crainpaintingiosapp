import AVFoundation
import PhotosUI
import SwiftUI

struct ColorMatcherView: View {
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
                    .padding(.top, theme.spacingSM)

                Spacer()

                if viewModel.state == .analyzing {
                    HStack(spacing: theme.spacingSM) {
                        ProgressView()
                            .tint(theme.primary)
                        Text("Analyzing Color...")
                            .font(theme.subhead)
                            .foregroundStyle(theme.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(theme.primary.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            bottomCard
        }
        .ignoresSafeArea(edges: .top)
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { image in
                viewModel.setSample(image: image)
                viewModel.analyzeColor()
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
                viewModel.setSample(image: image)
                viewModel.analyzeColor()
            }
        }
        .toast(isPresented: $showToast, message: toastMessage, icon: "checkmark.circle.fill")
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

            LinearGradient(
                colors: [Color.black.opacity(0.5), Color.black.opacity(0.2), Color.black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RoundedRectangle(cornerRadius: theme.radiusXL)
                .stroke(.white.opacity(0.8), lineWidth: 2)
                .frame(width: 250, height: 250)
                .overlay(
                    CropCorners()
                        .stroke(theme.primary, lineWidth: 3)
                        .padding(-2)
                )

            Circle()
                .fill(theme.primary)
                .frame(width: 12, height: 12)
                .opacity(viewModel.state == .analyzing ? 1 : 0.6)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: viewModel.state == .analyzing)

            if !viewModel.hasSample {
                VStack(spacing: theme.spacingSM) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 42, weight: .light))
                        .foregroundStyle(.white.opacity(0.85))
                    Text("Center the color inside the frame")
                        .font(theme.subhead)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
    }

    private var topBar: some View {
        HStack {
            iconPill(symbol: "xmark") { dismiss() }

            Spacer()

            Text(viewModel.hasSample ? "Review your sample" : "Capture a color sample")
                .font(theme.caption)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.black.opacity(0.35))
                .clipShape(Capsule())

            Spacer()

            iconPill(symbol: "camera.fill") {
                requestCameraAccess()
            }
        }
    }

    private var bottomCard: some View {
        let hasSample = viewModel.hasSample
        let libraryLabel = hasSample ? "Library" : "Upload"
        let cardColor = theme.card
        let borderColor = theme.border
        let foregroundColor = theme.foreground

        return VStack(spacing: theme.spacingMD) {
            RoundedRectangle(cornerRadius: 3)
                .fill(theme.border)
                .frame(width: 48, height: 6)
                .padding(.top, 8)

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.hasSample ? "Matches Found" : "Find The Closest Paint")
                        .font(theme.title)
                    Text(viewModel.hasSample ? "3 closest cross-brand matches" : "Capture or upload a sample and we’ll match it.")
                        .font(theme.subhead)
                        .foregroundStyle(theme.mutedForeground)
                }
                Spacer()
                if viewModel.hasSample {
                    Circle()
                        .fill(Color(hex: viewModel.sampledHex))
                        .frame(width: 46, height: 46)
                        .overlay(
                            Circle()
                                .stroke(theme.border, lineWidth: 1)
                        )
                }
            }

            if case .error(let message) = viewModel.state {
                stateBanner(text: message)
            } else if viewModel.state == .analyzing {
                HStack(spacing: theme.spacingSM) {
                    ProgressView()
                        .tint(theme.primary)
                    Text("Analyzing the sampled color…")
                        .font(theme.subhead)
                        .foregroundStyle(theme.foreground)
                    Spacer()
                }
                .padding(theme.spacingSM)
                .background(theme.muted)
                .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))
            } else if !viewModel.hasSample {
                stateBanner(
                    text: "Capture or upload a painted surface and we’ll find the closest catalog match.",
                    icon: "camera.viewfinder"
                )
            } else if viewModel.matches.isEmpty {
                stateBanner(text: "No strong match yet. Try a steadier angle or better light.")
            } else {
                VStack(spacing: theme.spacingSM) {
                    ForEach(viewModel.matches) { match in
                        matchRow(match)
                    }
                }
            }

            HStack(spacing: theme.spacingSM) {
                AppButton(viewModel.hasSample ? "Scan Again" : "Use Camera", variant: .primary, icon: "camera") {
                    viewModel.retake()
                    requestCameraAccess()
                }
                .frame(maxWidth: .infinity)

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack(spacing: theme.spacingSM) {
                        Image(systemName: "photo.on.rectangle")
                        Text(libraryLabel)
                            .font(TypographyTokens.bodySmall)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .foregroundStyle(foregroundColor)
                    .background(cardColor)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radiusMD)
                            .stroke(borderColor, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, theme.spacingMD)
        .padding(.bottom, theme.spacingLG)
        .padding(.top, theme.spacingSM)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
        .padding(.horizontal, theme.spacingSM)
        .padding(.bottom, theme.spacingSM)
    }

    private func matchRow(_ match: ColorMatchResult) -> some View {
        HStack(spacing: theme.spacingMD) {
            RoundedRectangle(cornerRadius: theme.radiusMD)
                .fill(match.color.color)
                .frame(width: 54, height: 54)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radiusMD)
                        .stroke(theme.border, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 2) {
                confidenceBadge(match.confidence)
                Text(match.color.name)
                    .font(theme.headline)
                    .foregroundStyle(theme.foreground)
                    .lineLimit(1)
                Text("\(match.color.brand.displayName) \u{00B7} \(match.color.number)")
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
            }

            Spacer()

            Button {
                let addedFavorite = favoritesVM.addFavorite(match.color)
                let addedPalette = visualizerVM.addColor(match.color)
                toastMessage = addedFavorite || addedPalette ? "Color added" : "Already saved"
                showToast = true
            } label: {
                Image(systemName: favoritesVM.isFavorite(match.color) ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(theme.primary)
            }
        }
        .padding(theme.spacingMD)
        .background(match.confidence >= 96 ? theme.primary.opacity(0.06) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusLG)
                .stroke(theme.border, lineWidth: 1)
        )
    }

    private func iconPill(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.black.opacity(0.35))
                .clipShape(Circle())
        }
        .accessibilityLabel(symbol.contains("xmark") ? "Close" : "Open camera")
    }

    @ViewBuilder
    private func confidenceBadge(_ confidence: Int) -> some View {
        let text = "\(confidence)% MATCH"
        if confidence >= 96 {
            Text(text)
                .font(theme.micro)
                .fontWeight(.bold)
                .foregroundStyle(theme.actionPrimaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(theme.actionPrimary)
                .clipShape(Capsule())
        } else if confidence >= 90 {
            Text(text)
                .font(theme.micro)
                .fontWeight(.bold)
                .foregroundStyle(theme.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    Capsule().stroke(theme.primary, lineWidth: 1)
                )
        } else {
            Text(text)
                .font(theme.micro)
                .fontWeight(.bold)
                .foregroundStyle(theme.mutedForeground)
        }
    }

    private func stateBanner(text: String, icon: String = "exclamationmark.circle") -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(theme.mutedForeground)
            Text(text)
                .font(theme.caption)
                .foregroundStyle(theme.mutedForeground)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(theme.spacingSM)
        .background(theme.muted)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))
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
                        cameraAlertMessage = "Please enable camera access in Settings to sample a color."
                        showCameraAlert = true
                    }
                }
            }
        default:
            cameraAlertMessage = "Please enable camera access in Settings to sample a color."
            showCameraAlert = true
        }
    }
}

private struct CropCorners: Shape {
    func path(in rect: CGRect) -> Path {
        let len: CGFloat = 24
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY + len))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + len, y: rect.minY))

        path.move(to: CGPoint(x: rect.maxX - len, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + len))

        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - len))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - len, y: rect.maxY))

        path.move(to: CGPoint(x: rect.minX + len, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - len))

        return path
    }
}
