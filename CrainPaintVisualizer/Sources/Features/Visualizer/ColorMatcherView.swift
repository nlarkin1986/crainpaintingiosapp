import AVFoundation
import PhotosUI
import SwiftUI

struct ColorMatcherView: View {
    @Environment(Theme.self) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(VisualizerViewModel.self) private var visualizerVM
    @Environment(FavoritesViewModel.self) private var favoritesVM

    @State private var viewModel: ColorMatcherViewModel
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastIcon = "checkmark.circle.fill"
    @State private var showCamera = false
    @State private var showCameraAlert = false
    @State private var cameraAlertMessage = "Please enable camera access in Settings to sample a color."
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var captureViewportSize: CGSize = .zero
    @State private var focusRectInView: CGRect = .zero
    @State private var revealedMatchCount = 0
    @State private var sampleLockPulse = false
    @State private var analysisSweepActive = false
    @State private var sampleHandoffVisible = false
    @State private var sampleHandoffProgress: CGFloat = 0
    @State private var didSeedUITestSample = false
    @State private var cameraEntryState: CameraEntryState = .initial
    @State private var cameraAlertOffersSettings = true
    @State private var isImportingPhoto = false
    @State private var resultRevealTask: Task<Void, Never>?
    @State private var sampleHandoffTask: Task<Void, Never>?

    private let focusCornerRadius: CGFloat = 30

    init() {
        _viewModel = State(initialValue: Self.makeViewModel())
    }

    var body: some View {
        ZStack {
            cameraLayer
                .ignoresSafeArea()
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            topOverlay
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomInset
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.9), value: viewModel.hasSample)
        .animation(.spring(response: 0.34, dampingFraction: 0.9), value: viewModel.state)
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(
                onCapture: { capture in
                    handleSelectedCapture(capture)
                },
                onCancel: handleCameraCancel
            )
        }
        .alert("Camera Access Required", isPresented: $showCameraAlert) {
            if cameraAlertOffersSettings {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
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

            if let importedPhoto = try? await selectedPhoto.loadTransferable(type: ImportedPhoto.self),
               let image = try? await PhotoIntakeCoordinator.shared.loadTransientImage(from: importedPhoto, maxPixelSize: 1_600) {
                handleSelectedImage(image, source: "ios_library")
            }
        }
        .task {
            await handleInitialAppearance()
        }
        .onChange(of: viewModel.state, initial: true) { _, newValue in
            handleStateChange(newValue)
        }
        .toast(isPresented: $showToast, message: toastMessage, icon: toastIcon)
    }

    private var cameraLayer: some View {
        GeometryReader { geometry in
            let focusRect = makeFocusRect(for: geometry.size)
            let hintY = min(focusRect.maxY + 58, geometry.size.height - 220)
            let focusSize = focusRect.width

            ZStack {
                if let sampleImage = viewModel.sampleImage {
                    Image(uiImage: sampleImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    LinearGradient(
                        colors: [Color.black.opacity(0.92), Color.black.opacity(0.78)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

                LinearGradient(
                    colors: [
                        Color.black.opacity(cameraGradientTopOpacity),
                        Color.black.opacity(cameraGradientBottomOpacity)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Path { path in
                    path.addRect(CGRect(origin: .zero, size: geometry.size))
                    path.addRoundedRect(
                        in: focusRect,
                        cornerSize: CGSize(width: focusCornerRadius, height: focusCornerRadius)
                    )
                }
                .fill(Color.black.opacity(maskOpacity), style: FillStyle(eoFill: true))

                RoundedRectangle(cornerRadius: focusCornerRadius)
                    .fill(.white.opacity(isAnalyzing ? 0.06 : (viewModel.hasSample ? 0.03 : 0)))
                    .frame(width: focusSize, height: focusSize)
                    .position(x: focusRect.midX, y: focusRect.midY)

                RoundedRectangle(cornerRadius: focusCornerRadius)
                    .stroke(.white.opacity(viewModel.hasSample ? 0.16 : 0.3), lineWidth: 1.5)
                    .frame(width: focusSize, height: focusSize)
                    .position(x: focusRect.midX, y: focusRect.midY)

                CropCorners()
                    .stroke(theme.primary, lineWidth: 5)
                    .frame(width: focusSize, height: focusSize)
                    .scaleEffect(sampleLockPulse ? 1.03 : 1)
                    .opacity(sampleLockPulse ? 1 : 0.92)
                    .position(x: focusRect.midX, y: focusRect.midY)

                if sampleHandoffVisible {
                    sampleHandoffToken(canvasSize: geometry.size, focusRect: focusRect)
                        .allowsHitTesting(false)
                        .zIndex(2)
                }

                if viewModel.state == .capturing {
                    Circle()
                        .fill(theme.primary)
                        .frame(width: 14, height: 14)
                        .opacity(0.72)
                        .position(x: focusRect.midX, y: focusRect.midY)

                    VStack(spacing: theme.space8) {
                        Text("Center the color in the square")
                            .font(theme.label.weight(.semibold))
                            .foregroundStyle(.white)

                        Text("We sample the full area inside the frame. Flat, even light works best.")
                            .font(theme.caption)
                            .foregroundStyle(.white.opacity(0.82))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 250)
                    }
                    .position(x: geometry.size.width / 2, y: hintY)
                } else if viewModel.state == .sampleLocked {
                    focusStatusPill(
                        text: "Sample captured",
                        icon: "checkmark.circle.fill"
                    )
                    .position(x: geometry.size.width / 2, y: hintY)
                    .accessibilityIdentifier("colorMatcher.sampleLocked")
                } else if isAnalyzing {
                    focusStatusPill(
                        text: analysisCameraStatusLabel,
                        icon: "paintpalette.fill"
                    )
                    .position(x: geometry.size.width / 2, y: hintY)
                    .accessibilityIdentifier("colorMatcher.analysisState")
                }

                Color.clear
                    .onAppear {
                        updateCaptureGeometry(size: geometry.size, focusRect: focusRect)
                    }
                    .onChange(of: geometry.size) { _, newValue in
                        updateCaptureGeometry(size: newValue, focusRect: makeFocusRect(for: newValue))
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func makeFocusRect(for size: CGSize) -> CGRect {
        let focusSize = min(max(size.width - 92, 220), 300)
        let focusCenterY = max(size.height * 0.38, (focusSize / 2) + 120)
        return CGRect(
            x: (size.width - focusSize) / 2,
            y: focusCenterY - (focusSize / 2),
            width: focusSize,
            height: focusSize
        )
    }

    private func handleSelectedImage(
        _ image: UIImage,
        source: String,
        captureContext: ColorMatchCaptureContext? = nil
    ) {
        cameraEntryState = .initial
        let focusRect = normalizedFocusRect(for: image)
        let resolvedCaptureContext = captureContext ?? ColorMatchCaptureContext(source: source)

        if viewModel.setSample(
            image: image,
            focusRect: focusRect,
            captureContext: resolvedCaptureContext
        ) {
            viewModel.analyzeColor()
        }
    }

    private func handleSelectedCapture(_ capture: CapturedPhoto) {
        showCamera = false
        guard let image = UIImage(data: capture.data) else {
            return
        }
        handleSelectedImage(image, source: "ios_camera", captureContext: capture.captureContext)
    }

    private func updateCaptureGeometry(size: CGSize, focusRect: CGRect) {
        captureViewportSize = size
        focusRectInView = focusRect
    }

    private func normalizedFocusRect(for image: UIImage) -> ColorMatchFocusRect {
        let defaultRect = ColorMatchFocusRect(x: 0.36, y: 0.36, width: 0.28, height: 0.28)

        guard captureViewportSize.width > 0,
              captureViewportSize.height > 0,
              focusRectInView.width > 0,
              focusRectInView.height > 0,
              image.size.width > 0,
              image.size.height > 0 else {
            return defaultRect
        }

        let viewSize = captureViewportSize
        let imageSize = image.size
        let scale = max(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
        let displayedSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let xInset = max(0, (displayedSize.width - viewSize.width) / 2)
        let yInset = max(0, (displayedSize.height - viewSize.height) / 2)

        let normalizedX = max(0, min(1, (focusRectInView.minX + xInset) / displayedSize.width))
        let normalizedY = max(0, min(1, (focusRectInView.minY + yInset) / displayedSize.height))
        let normalizedWidth = max(0.05, min(1, focusRectInView.width / displayedSize.width))
        let normalizedHeight = max(0.05, min(1, focusRectInView.height / displayedSize.height))
        let clampedWidth = max(0.05, min(normalizedWidth, 1 - normalizedX))
        let clampedHeight = max(0.05, min(normalizedHeight, 1 - normalizedY))

        return ColorMatchFocusRect(
            x: normalizedX,
            y: normalizedY,
            width: clampedWidth,
            height: clampedHeight
        )
    }

    private var topOverlay: some View {
        HStack {
            chromeButton(symbol: "chevron.left", label: "Back") {
                dismiss()
            }

            Spacer()
        }
        .padding(.horizontal, theme.spacingMD)
        .padding(.top, theme.space8)
        .padding(.bottom, theme.space8)
    }

    @ViewBuilder
    private var bottomInset: some View {
        if viewModel.hasSample {
            bottomCard(showsHandle: true) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: theme.space16) {
                        resultsHeader
                        sheetContent
                        actionArea
                    }
                    .padding(.horizontal, theme.space16)
                    .padding(.top, theme.space16)
                    .padding(.bottom, theme.space20)
                }
                .frame(maxHeight: resultsPanelMaxHeight, alignment: .top)
            }
            .accessibilityIdentifier("colorMatcher.sheet")
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            bottomCard {
                VStack(alignment: .leading, spacing: theme.space16) {
                    VStack(alignment: .leading, spacing: theme.space4) {
                        Text("Match a real-world color")
                            .font(theme.heading2)
                            .foregroundStyle(theme.foreground)

                        Text(cameraIntroCopy)
                            .font(theme.bodySmall)
                            .foregroundStyle(theme.mutedForeground)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if case .error(let message) = viewModel.state {
                        stateBanner(text: message, icon: "exclamationmark.triangle", accent: theme.feedbackWarning)
                    }

                    HStack(spacing: theme.space12) {
                        AppButton(primaryCameraActionTitle, variant: .primary, icon: "camera") {
                            requestCameraAccess()
                        }
                        .accessibilityIdentifier("colorMatcher.useCamera")

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            outlineActionLabel(title: "Upload Photo", icon: "photo.on.rectangle")
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("colorMatcher.uploadPhoto")
                    }
                }
                .padding(.horizontal, theme.space16)
                .padding(.top, theme.space16)
                .padding(.bottom, theme.space16)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var resultsHeader: some View {
        VStack(alignment: .leading, spacing: theme.space12) {
            Text(sheetTitle)
                .font(theme.heading2)
                .foregroundStyle(theme.foreground)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("colorMatcher.sheetTitle")

            Text(sheetSubtitle)
                .font(theme.bodySmall)
                .foregroundStyle(theme.mutedForeground)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .center, spacing: theme.space12) {
                capturedSampleCard
                    .accessibilityIdentifier("colorMatcher.capturedSample")
                    .opacity(sampleHandoffVisible && viewModel.state == .sampleLocked ? 0.46 : 1)
                    .scaleEffect(sampleHandoffVisible && viewModel.state == .sampleLocked ? 0.97 : 1, anchor: .topLeading)

                if viewModel.state == .results {
                    Text("\(viewModel.matches.count) matches")
                        .font(theme.captionSmall.weight(.semibold))
                        .foregroundStyle(theme.primary)
                        .padding(.horizontal, theme.space12)
                        .padding(.vertical, theme.space12)
                        .background(theme.primary.opacity(0.1))
                        .clipShape(Capsule())
                        .accessibilityIdentifier("colorMatcher.matchesCount")
                }
            }
        }
    }

    private var capturedSampleCard: some View {
        HStack(spacing: theme.space12) {
            Group {
                if let sampleCropImage = viewModel.sampleCropImage {
                    Image(uiImage: sampleCropImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: theme.radiusMD)
                        .fill(theme.muted)
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.radiusMD)
                                .fill(Color(hex: viewModel.sampledHex).opacity(0.16))
                        )
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radiusMD)
                    .stroke(theme.borderSubtle, lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("Captured sample")
                    .font(theme.micro.weight(.bold))
                    .tracking(0.6)
                    .foregroundStyle(theme.mutedForeground)
                Text("#\(viewModel.sampledHex)")
                    .font(theme.monoLabel)
                    .foregroundStyle(theme.foreground)
            }

            Spacer(minLength: theme.space8)

            Circle()
                .fill(Color(hex: viewModel.sampledHex))
                .frame(width: 22, height: 22)
                .overlay(
                    Circle()
                        .stroke(theme.borderSubtle, lineWidth: 1)
                )
        }
        .padding(.horizontal, theme.space12)
        .padding(.vertical, theme.space12)
        .background(theme.secondary)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusLG)
                .stroke(theme.primary.opacity(sampleHandoffVisible && viewModel.state == .sampleLocked ? 0.22 : 0), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var sheetContent: some View {
        switch viewModel.state {
        case .capturing:
            EmptyView()
        case .sampleLocked:
            sampleLockedCard
        case .analyzing:
            analysisBenchCard
        case .needsRetake:
            needsRetakeCard
        case .error(let message):
            stateBanner(text: message, icon: "exclamationmark.triangle", accent: theme.feedbackWarning)
        case .results:
            resultsContent
        }
    }

    private var sampleLockedCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Sample captured", systemImage: "checkmark.circle.fill")
                .font(theme.label.weight(.semibold))
                .foregroundStyle(theme.primary)

            Text("We locked the color inside the frame and are moving it into the paint bench now.")
                .font(theme.bodySmall)
                .foregroundStyle(theme.mutedForeground)
        }
        .padding(14)
        .background(theme.secondary)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("colorMatcher.sampleLockedCard")
    }

    private var analysisBenchCard: some View {
        VStack(alignment: .leading, spacing: theme.space16) {
            HStack(alignment: .top, spacing: theme.space12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Paint Sample Bench")
                        .font(theme.heading3)
                        .foregroundStyle(theme.foreground)
                    Text("Cross-brand comparison is underway.")
                        .font(theme.caption)
                        .foregroundStyle(theme.mutedForeground)
                }

                Spacer()

                HStack(spacing: 6) {
                    analysisBrandBadge("BM")
                    analysisBrandBadge("SW")
                }
            }

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: theme.radiusLG)
                    .fill(theme.muted)

                RoundedRectangle(cornerRadius: theme.radiusLG)
                    .fill(Color(hex: viewModel.sampledHex).opacity(0.12))

                if reduceMotion {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.primary.opacity(0.32))
                        .frame(height: 4)
                        .padding(.horizontal, theme.space16)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, theme.space16)
                } else {
                    AnalysisBenchSweep(active: analysisSweepActive, tint: theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
                }

                HStack(spacing: theme.space12) {
                    Circle()
                        .fill(Color(hex: viewModel.sampledHex))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.72), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 3) {
                        Text(analysisBenchTitle)
                            .font(theme.label.weight(.semibold))
                            .foregroundStyle(theme.foreground)
                        Text(analysisBenchDetail)
                            .font(theme.caption)
                            .foregroundStyle(theme.mutedForeground)
                    }

                    Spacer()
                }
                .padding(theme.space16)
            }
            .frame(height: 108)

            VStack(spacing: 10) {
                ForEach(ColorMatcherAnalysisPhase.allCases, id: \.self) { phase in
                    analysisPhaseRow(phase)
                }
            }
        }
        .padding(theme.space16)
        .background(theme.secondary)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusXL)
                .stroke(theme.primary.opacity(0.12), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("colorMatcher.analysisBench")
    }

    private var needsRetakeCard: some View {
        VStack(alignment: .leading, spacing: theme.space12) {
            stateBanner(
                text: "We did not get a reliable paint match from this sample. Try a steadier angle, less glare, or a flatter patch of color.",
                icon: "camera.filters",
                accent: theme.feedbackWarning
            )

            VStack(alignment: .leading, spacing: theme.space8) {
                Text("Best results usually come from:")
                    .font(theme.label.weight(.semibold))
                    .foregroundStyle(theme.foreground)

                Text("Even light, less texture, and a tighter crop around one consistent tone.")
                    .font(theme.bodySmall)
                    .foregroundStyle(theme.mutedForeground)
            }
            .padding(14)
            .background(theme.secondary.opacity(0.65))
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
        }
    }

    private var resultsContent: some View {
        VStack(alignment: .leading, spacing: theme.space12) {
            if !viewModel.sampleWarnings.isEmpty {
                stateBanner(
                    text: viewModel.sampleWarnings.joined(separator: " "),
                    icon: viewModel.sampleQuality == .poor ? "exclamationmark.triangle" : "camera.filters",
                    accent: viewModel.sampleQuality == .poor ? theme.feedbackWarning : theme.primary
                )
            }

            if let leadMatch = visibleMatches.first {
                leadMatchCard(leadMatch)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }

            if visibleMatches.count > 1 {
                VStack(spacing: theme.space8) {
                    ForEach(Array(visibleMatches.dropFirst())) { match in
                        matchRow(match)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var actionArea: some View {
        switch viewModel.state {
        case .capturing, .sampleLocked:
            EmptyView()
        case .analyzing:
            AppButton("Cancel Analysis", variant: .outline, icon: "xmark") {
                viewModel.cancelAnalysis()
            }
            .accessibilityIdentifier("colorMatcher.cancelAnalysis")
        case .needsRetake, .error:
            VStack(spacing: theme.space12) {
                AppButton("Try Again With This Sample", variant: .outline, icon: "arrow.clockwise") {
                    viewModel.analyzeColor()
                }
                .accessibilityIdentifier("colorMatcher.retryAnalysis")

                retakeActions
            }
        case .results:
            retakeActions
        }
    }

    private var retakeActions: some View {
        HStack(spacing: theme.space12) {
            AppButton("Retake", variant: .outline, icon: "camera.rotate") {
                viewModel.retake()
                requestCameraAccess()
            }
            .accessibilityIdentifier("colorMatcher.retake")

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                outlineActionLabel(title: "Upload Different", icon: "photo.on.rectangle")
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("colorMatcher.uploadDifferent")
        }
    }

    private var sheetTitle: String {
        switch viewModel.state {
        case .capturing:
            return "Match a real-world color"
        case .sampleLocked:
            return "Sample captured"
        case .analyzing:
            return "Matching your sample"
        case .results:
            return "Closest paint matches"
        case .needsRetake:
            return "We need a cleaner sample"
        case .error:
            return viewModel.hasSample ? "We couldn't finish that match" : "We couldn't read that sample"
        }
    }

    private var sheetSubtitle: String {
        switch viewModel.state {
        case .capturing:
            return cameraIntroCopy
        case .sampleLocked:
            return "We locked the captured color and are about to compare it across Benjamin Moore and Sherwin-Williams."
        case .analyzing:
            return "This is the captured input, not the final answer. We are comparing it against both paint catalogs now."
        case .results:
            return "Add the strongest match to your project or choose a close alternate below."
        case .needsRetake:
            return "A cleaner angle, softer light, or less texture usually improves the result."
        case .error:
            return viewModel.hasSample
                ? "You can retry this captured sample or replace it with a new photo."
                : "Try another photo with steadier framing and more even light."
        }
    }

    private var cameraGradientTopOpacity: Double {
        if isAnalyzing {
            return 0.26
        }
        return viewModel.hasSample ? 0.14 : 0.2
    }

    private var cameraGradientBottomOpacity: Double {
        if isAnalyzing {
            return 0.62
        }
        return viewModel.hasSample ? 0.38 : 0.46
    }

    private var maskOpacity: Double {
        if isAnalyzing {
            return 0.7
        }
        return viewModel.hasSample ? 0.46 : 0.56
    }

    private var isAnalyzing: Bool {
        viewModel.state.isAnalyzing
    }

    private var analysisCameraStatusLabel: String {
        guard let phase = viewModel.analysisPhase else { return "Analyzing paint sample" }
        switch phase {
        case .readingSample:
            return "Reading the sampled tone"
        case .comparingCatalogs:
            return "Comparing paint catalogs"
        case .rankingMatches:
            return "Ranking the closest matches"
        }
    }

    private var analysisBenchTitle: String {
        guard let phase = viewModel.analysisPhase else { return "Reading the surface tone" }
        switch phase {
        case .readingSample:
            return "Reading the surface tone"
        case .comparingCatalogs:
            return "Comparing Benjamin Moore and Sherwin-Williams"
        case .rankingMatches:
            return "Ranking the closest paint matches"
        }
    }

    private var analysisBenchDetail: String {
        guard let phase = viewModel.analysisPhase else { return "Capturing the strongest read from the selected area." }
        switch phase {
        case .readingSample:
            return "Taking the strongest read from the area inside the frame."
        case .comparingCatalogs:
            return "Checking undertone and depth against both paint catalogs."
        case .rankingMatches:
            return "Building a shortlist based on the closest cross-brand fit."
        }
    }

    private func analysisBrandBadge(_ title: String) -> some View {
        Text(title)
            .font(theme.micro.weight(.bold))
            .foregroundStyle(theme.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(theme.primary.opacity(0.1))
            .clipShape(Capsule())
    }

    private func analysisPhaseRow(_ phase: ColorMatcherAnalysisPhase) -> some View {
        let isActive = viewModel.analysisPhase == phase

        return HStack(spacing: 10) {
            Circle()
                .fill(isActive ? theme.primary : theme.borderSubtle)
                .frame(width: 10, height: 10)

            Text(phase.rowLabel)
                .font(theme.bodySmall)
                .foregroundStyle(isActive ? theme.foreground : theme.mutedForeground)

            Spacer()
        }
        .padding(.horizontal, theme.space12)
        .padding(.vertical, 10)
        .background(isActive ? theme.card : theme.card.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
    }

    private var visibleMatches: [ColorMatchResult] {
        let clampedCount = max(0, min(revealedMatchCount, viewModel.matches.count))
        return Array(viewModel.matches.prefix(clampedCount))
    }

    private func leadMatchCard(_ match: ColorMatchResult) -> some View {
        matchCard(
            match,
            emphasized: true,
            accessibilityIdentifier: "colorMatcher.match.\(match.id)"
        )
    }

    private func matchRow(_ match: ColorMatchResult) -> some View {
        matchCard(
            match,
            emphasized: false,
            accessibilityIdentifier: "colorMatcher.match.\(match.id)"
        )
    }

    private func matchCard(
        _ match: ColorMatchResult,
        emphasized: Bool,
        accessibilityIdentifier: String
    ) -> some View {
        let isSelected = visualizerVM.isSelected(match.color)
        let isFavorite = favoritesVM.isFavorite(match.color)

        return HStack(spacing: theme.space12) {
            RoundedRectangle(cornerRadius: theme.radiusLG)
                .fill(match.color.color)
                .frame(width: emphasized ? 64 : 56, height: emphasized ? 64 : 56)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radiusLG)
                        .stroke(theme.borderSubtle, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 3) {
                confidenceBadge(match.confidence)
                Text(match.color.name)
                    .font(emphasized ? theme.heading2 : theme.heading3)
                    .foregroundStyle(theme.foreground)
                    .lineLimit(1)
                Text("\(match.color.brand.displayName) • \(match.color.number)")
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
            }

            Spacer(minLength: theme.space8)

            HStack(spacing: theme.space8) {
                Button {
                    toggleFavorite(match)
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isFavorite ? Color.red : theme.primary)
                        .frame(width: 44, height: 44)
                        .background(isFavorite ? Color.red.opacity(0.1) : theme.secondary)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("colorMatcher.favorite.\(match.id)")
                .accessibilityLabel(isFavorite ? "Remove \(match.color.name) from favorites" : "Save \(match.color.name) to favorites")
                .accessibilityValue(isFavorite ? "Saved" : "Not saved")

                Button {
                    useMatch(match, dismissAfterSelection: true)
                } label: {
                    Text(isSelected ? "Added" : "Use")
                        .font(theme.captionSmall.weight(.semibold))
                        .foregroundStyle(isSelected ? theme.feedbackSuccess : theme.actionPrimaryText)
                        .padding(.horizontal, theme.space12)
                        .padding(.vertical, theme.space8)
                        .background(isSelected ? theme.feedbackSuccess.opacity(0.14) : theme.actionPrimary)
                        .clipShape(Capsule())
                }
                .disabled(!canUse(match: match))
                .opacity(canUse(match: match) ? 1 : 0.65)
                .accessibilityLabel(isSelected ? "\(match.color.name) already added" : "Use \(match.color.name)")
            }
        }
        .padding(theme.space12)
        .background(emphasized ? theme.primary.opacity(0.09) : theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusXL)
                .stroke(
                    isSelected
                        ? theme.feedbackSuccess.opacity(0.26)
                        : (emphasized ? theme.primary.opacity(0.22) : theme.borderSubtle),
                    lineWidth: 1
                )
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private func focusStatusPill(text: String, icon: String) -> some View {
        HStack(spacing: theme.space8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
            Text(text)
                .font(theme.captionSmall.weight(.semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, theme.space12)
        .padding(.vertical, theme.space8)
        .background(.black.opacity(0.4))
        .clipShape(Capsule())
    }

    private func chromeButton(symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.black.opacity(0.34))
                .clipShape(Circle())
        }
        .accessibilityLabel(label)
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
                .padding(.vertical, 3)
                .background(theme.actionPrimary)
                .clipShape(Capsule())
        } else if confidence >= 90 {
            Text(text)
                .font(theme.micro)
                .fontWeight(.bold)
                .foregroundStyle(theme.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .stroke(theme.primary, lineWidth: 1)
                )
        } else {
            Text(text)
                .font(theme.micro)
                .fontWeight(.bold)
                .foregroundStyle(theme.mutedForeground)
        }
    }

    private func stateBanner(
        text: String,
        icon: String = "exclamationmark.circle",
        accent: Color? = nil
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(accent ?? theme.primary)
            Text(text)
                .font(theme.bodySmall)
                .foregroundStyle(theme.mutedForeground)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(theme.space12)
        .background(theme.secondary)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
    }

    private func outlineActionLabel(title: String, icon: String) -> some View {
        HStack(spacing: theme.space8) {
            Image(systemName: icon)
            Text(title)
                .font(theme.label)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .foregroundStyle(theme.foreground)
        .background(theme.secondary)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusMD)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
    }

    private func bottomCard<Content: View>(
        showsHandle: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            if showsHandle {
                RoundedRectangle(cornerRadius: 3)
                    .fill(theme.borderSubtle)
                    .frame(width: 48, height: 6)
                    .padding(.top, 10)
            }

            content()
        }
        .frame(maxWidth: .infinity)
        .background(theme.card.opacity(0.98))
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: theme.radiusXL,
                topTrailingRadius: theme.radiusXL
            )
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: theme.radiusXL,
                topTrailingRadius: theme.radiusXL
            )
            .stroke(theme.borderSubtle, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 22, y: -8)
    }

    private var resultsPanelMaxHeight: CGFloat {
        let availableHeight = captureViewportSize.height > 0 ? captureViewportSize.height : 560
        return min(availableHeight * 0.58, 560)
    }

    private func canUse(match: ColorMatchResult) -> Bool {
        visualizerVM.isSelected(match.color) || visualizerVM.canAddColor
    }

    private func useMatch(_ match: ColorMatchResult, dismissAfterSelection: Bool) {
        let completedSelection: Bool

        if visualizerVM.isSelected(match.color) {
            toastMessage = "\(match.color.name) is already in your project."
            toastIcon = "checkmark.circle.fill"
            completedSelection = true
        } else if visualizerVM.addColor(match.color) {
            toastMessage = "\(match.color.name) added to your project."
            toastIcon = "checkmark.circle.fill"
            completedSelection = true
        } else {
            toastMessage = "Your project palette already has five colors."
            toastIcon = "exclamationmark.triangle.fill"
            completedSelection = false
        }

        if dismissAfterSelection, completedSelection {
            dismiss()
            return
        }

        showToast = true
    }

    private func toggleFavorite(_ match: ColorMatchResult) {
        if favoritesVM.isFavorite(match.color) {
            _ = favoritesVM.removeFavorite(match.color)
            toastMessage = "Removed from favorites"
            toastIcon = "heart.slash.fill"
        } else {
            _ = favoritesVM.addFavorite(match.color)
            toastMessage = "Saved to favorites"
            toastIcon = "heart.fill"
        }

        showToast = true
    }

    private func requestCameraAccess() {
        if forcesUnavailableCamera {
            presentCameraRecovery(
                message: "This device does not have an available camera right now. Use the photo library instead.",
                offersSettings: false
            )
            return
        }

        guard CameraView.isCameraAvailable else {
            presentCameraRecovery(
                message: "This device does not have an available camera right now. Use the photo library instead.",
                offersSettings: false
            )
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
                        presentCameraRecovery(
                            message: "Please enable camera access in Settings to sample a color.",
                            offersSettings: true
                        )
                    }
                }
            }
        default:
            presentCameraRecovery(
                message: "Please enable camera access in Settings to sample a color.",
                offersSettings: true
            )
        }
    }

    private func handleStateChange(_ newValue: ColorMatcherState) {
        resultRevealTask?.cancel()
        resultRevealTask = nil
        sampleHandoffTask?.cancel()
        sampleHandoffTask = nil

        switch newValue {
        case .sampleLocked:
            revealedMatchCount = 0
            analysisSweepActive = false
            triggerSampleLockPulse()
            startSampleHandoff()
        case .analyzing:
            revealedMatchCount = 0
            startAnalysisSweep()
        case .results:
            analysisSweepActive = false
            startResultsReveal()
        default:
            analysisSweepActive = false
            revealedMatchCount = 0
            sampleHandoffVisible = false
            sampleHandoffProgress = 0
        }
    }

    private func triggerSampleLockPulse() {
        sampleLockPulse = false
        guard !reduceMotion else { return }

        withAnimation(.spring(response: 0.24, dampingFraction: 0.7)) {
            sampleLockPulse = true
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(220))
            withAnimation(.easeOut(duration: 0.16)) {
                sampleLockPulse = false
            }
        }
    }

    private func startAnalysisSweep() {
        guard !reduceMotion else {
            analysisSweepActive = false
            return
        }

        analysisSweepActive = false
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: false)) {
            analysisSweepActive = true
        }
    }

    private func startResultsReveal() {
        let totalMatches = viewModel.matches.count
        guard totalMatches > 0 else {
            revealedMatchCount = 0
            return
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
            revealedMatchCount = 1
        }

        guard totalMatches > 1 else { return }

        resultRevealTask = Task { @MainActor in
            for nextCount in 2...totalMatches {
                if viewModel.resultRevealInterval > .zero {
                    try? await Task.sleep(for: viewModel.resultRevealInterval)
                }
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
                    revealedMatchCount = nextCount
                }
            }
        }
    }

    private func startSampleHandoff() {
        let animationDuration = max(0.22, min(durationSeconds(viewModel.captureConfirmationDuration) * 0.82, 0.52))

        sampleHandoffVisible = true
        sampleHandoffProgress = 0

        if reduceMotion {
            withAnimation(.easeOut(duration: 0.18)) {
                sampleHandoffProgress = 1
            }
        } else {
            withAnimation(.spring(response: animationDuration, dampingFraction: 0.84)) {
                sampleHandoffProgress = 1
            }
        }

        sampleHandoffTask = Task { @MainActor in
            let settleDuration = reduceMotion ? min(animationDuration, 0.2) : animationDuration
            try? await Task.sleep(for: .milliseconds(Int((settleDuration * 1000).rounded())))
            guard !Task.isCancelled else { return }
            sampleHandoffVisible = false
            sampleHandoffProgress = 0
        }
    }

    private func durationSeconds(_ duration: Duration) -> Double {
        let components = duration.components
        return Double(components.seconds) + (Double(components.attoseconds) / 1_000_000_000_000_000_000)
    }

    private func seedUITestSampleIfNeeded() async {
        guard !didSeedUITestSample else { return }
        guard ProcessInfo.processInfo.arguments.contains("UITEST_COLOR_MATCHER_SEED_SAMPLE") else { return }

        didSeedUITestSample = true
        try? await Task.sleep(for: .milliseconds(150))
        handleSelectedImage(Self.makeUITestSampleImage(), source: "ui_test_seed")
    }

    private static func makeViewModel() -> ColorMatcherViewModel {
        let processInfo = ProcessInfo.processInfo

        if processInfo.arguments.contains("UITEST_COLOR_MATCHER_MOCK") {
            let delayMilliseconds = Int(processInfo.environment["UITEST_COLOR_MATCHER_MOCK_DELAY_MS"] ?? "") ?? 1200
            let captureConfirmationMilliseconds = Int(processInfo.environment["UITEST_COLOR_MATCHER_CAPTURE_MS"] ?? "") ?? 1600
            let analysisPhaseMilliseconds = Int(processInfo.environment["UITEST_COLOR_MATCHER_PHASE_MS"] ?? "") ?? 450
            let resultRevealMilliseconds = Int(processInfo.environment["UITEST_COLOR_MATCHER_REVEAL_MS"] ?? "") ?? 40
            return ColorMatcherViewModel(
                service: UITestColorMatchService(delay: .milliseconds(delayMilliseconds)),
                timing: ColorMatcherTiming(
                    captureConfirmationDuration: .milliseconds(captureConfirmationMilliseconds),
                    analysisPhaseDuration: .milliseconds(analysisPhaseMilliseconds),
                    resultRevealInterval: .milliseconds(resultRevealMilliseconds)
                )
            )
        }

        return ColorMatcherViewModel()
    }

    private func handleInitialAppearance() async {
        guard shouldSeedUITestSample else { return }
        await seedUITestSampleIfNeeded()
    }

    private func handleCameraCancel() {
        cameraEntryState = .recovery
    }

    private func presentCameraRecovery(message: String, offersSettings: Bool) {
        cameraEntryState = .recovery
        cameraAlertMessage = message
        cameraAlertOffersSettings = offersSettings
        showCameraAlert = true
    }

    private var shouldSeedUITestSample: Bool {
        ProcessInfo.processInfo.arguments.contains("UITEST_COLOR_MATCHER_SEED_SAMPLE")
    }

    private var forcesUnavailableCamera: Bool {
        ProcessInfo.processInfo.arguments.contains("UITEST_COLOR_MATCHER_FORCE_CAMERA_UNAVAILABLE")
    }

    private var primaryCameraActionTitle: String {
        cameraEntryState == .recovery ? "Use Camera Again" : "Use Camera"
    }

    private var cameraIntroCopy: String {
        switch cameraEntryState {
        case .initial:
            return "Use the camera for the strongest read, or upload a photo when you already have a sample."
        case .recovery:
            return "Camera is the fastest way to match. If you already have a sample photo, upload it instead."
        }
    }

    private enum CameraEntryState {
        case initial
        case recovery
    }

    private static func makeUITestSampleImage() -> UIImage {
        let size = CGSize(width: 1200, height: 1200)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            UIColor(red: 0.14, green: 0.16, blue: 0.15, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))

            UIColor(red: 0.08, green: 0.11, blue: 0.09, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: size.width, height: 300))

            UIColor(red: 0.76, green: 0.07, blue: 0.46, alpha: 1).setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 230, y: 320, width: 170, height: 170))
            context.cgContext.fillEllipse(in: CGRect(x: 390, y: 310, width: 190, height: 190))
            context.cgContext.fillEllipse(in: CGRect(x: 565, y: 340, width: 180, height: 180))
            context.cgContext.fillEllipse(in: CGRect(x: 735, y: 300, width: 190, height: 190))
            context.cgContext.fillEllipse(in: CGRect(x: 320, y: 500, width: 220, height: 220))
            context.cgContext.fillEllipse(in: CGRect(x: 560, y: 520, width: 210, height: 210))
            context.cgContext.fillEllipse(in: CGRect(x: 780, y: 520, width: 170, height: 170))

            UIColor(red: 0.22, green: 0.31, blue: 0.22, alpha: 1).setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 140, y: 150, width: 220, height: 220))
            context.cgContext.fillEllipse(in: CGRect(x: 760, y: 130, width: 250, height: 250))
        }
    }

    private func sampleHandoffToken(canvasSize: CGSize, focusRect: CGRect) -> some View {
        let startSize = CGSize(width: focusRect.width * 0.54, height: focusRect.width * 0.22)
        let endSize = CGSize(width: 132, height: 64)
        let startPoint = CGPoint(x: focusRect.midX, y: focusRect.midY)
        let sheetTopY = max(canvasSize.height - resultsPanelMaxHeight, focusRect.maxY + 80)
        let endPoint = CGPoint(x: 120, y: min(sheetTopY + 58, canvasSize.height - 140))

        let width = lerp(startSize.width, endSize.width, progress: sampleHandoffProgress)
        let height = lerp(startSize.height, endSize.height, progress: sampleHandoffProgress)
        let x = lerp(startPoint.x, endPoint.x, progress: sampleHandoffProgress)
        let y = lerp(startPoint.y, endPoint.y, progress: sampleHandoffProgress)
        let opacity = reduceMotion
            ? (sampleHandoffVisible ? 1 : 0)
            : max(0, 1 - max(0, sampleHandoffProgress - 0.88) / 0.12)

        return HStack(spacing: 8) {
            Group {
                if let sampleCropImage = viewModel.sampleCropImage {
                    Image(uiImage: sampleCropImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: viewModel.sampledHex).opacity(0.2))
                }
            }
            .frame(width: height, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Circle()
                .fill(Color(hex: viewModel.sampledHex))
                .frame(width: 18, height: 18)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.72), lineWidth: 1)
                )

            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(width: width, height: height)
        .background(theme.card.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(theme.primary.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 20, y: 10)
        .position(x: x, y: y)
        .scaleEffect(reduceMotion ? 1 - (sampleHandoffProgress * 0.02) : 1 - (sampleHandoffProgress * 0.08))
        .opacity(opacity)
    }

    private func lerp(_ start: CGFloat, _ end: CGFloat, progress: CGFloat) -> CGFloat {
        start + ((end - start) * progress)
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

private struct AnalysisBenchSweep: View {
    let active: Bool
    let tint: Color

    var body: some View {
        GeometryReader { geometry in
            let sweepWidth = geometry.size.width * 0.42

            LinearGradient(
                colors: [Color.clear, tint.opacity(0.12), tint.opacity(0.4), Color.clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: sweepWidth)
            .rotationEffect(.degrees(-10))
            .offset(x: active ? geometry.size.width : -sweepWidth, y: 0)
        }
        .allowsHitTesting(false)
    }
}

private struct UITestColorMatchService: ColorMatchService {
    let delay: Duration

    func match(
        image: UIImage,
        focusRect: ColorMatchFocusRect?,
        captureContext: ColorMatchCaptureContext?
    ) async throws -> ColorMatchResponseData {
        if delay > .zero {
            try? await Task.sleep(for: delay)
        }

        return ColorMatchResponseData(
            sampleHex: "C11276",
            quality: .mixed,
            warnings: ["This sample includes visible color variation, so the match may be less precise."],
            diagnostics: .empty,
            matchMethod: .deterministicFallback,
            matches: [
                ColorMatchResult(
                    id: "benjamin_moore-2077-30",
                    color: PaintColor(
                        number: "2077-30",
                        name: "Hot Lips",
                        family: "Pink",
                        hex: "BE4A8B",
                        brand: .benjaminMoore
                    ),
                    confidence: 85,
                    rationale: "Closest match for the strongest midtone in the sample."
                ),
                ColorMatchResult(
                    id: "sherwin_williams-SW 6840",
                    color: PaintColor(
                        number: "SW 6840",
                        name: "Exuberant Pink",
                        family: "Pink",
                        hex: "B85790",
                        brand: .sherwinWilliams
                    ),
                    confidence: 79,
                    rationale: "A close alternate with similar saturation."
                ),
            ]
        )
    }
}

private extension ColorMatcherAnalysisPhase {
    var rowLabel: String {
        switch self {
        case .readingSample:
            return "Reading the surface tone"
        case .comparingCatalogs:
            return "Comparing Benjamin Moore and Sherwin-Williams"
        case .rankingMatches:
            return "Ranking the closest paint matches"
        }
    }
}
