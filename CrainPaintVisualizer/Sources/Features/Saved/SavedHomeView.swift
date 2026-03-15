import SwiftUI
import Photos
import UIKit

struct SavedHomeView: View {
    @Environment(Theme.self) private var theme
    @Environment(AppState.self) private var appState
    @Environment(TabRouter.self) private var tabRouter
    @Environment(RouterPath.self) private var router
    @Environment(VisualizerViewModel.self) private var visualizerVM
    @Environment(FavoritesViewModel.self) private var favoritesVM
    @Environment(ReportsViewModel.self) private var reportsVM

    private let previewColumns = [GridItem(.adaptive(minimum: 160), spacing: 12)]
    private let colorColumns = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: theme.space16) {
                CompactScreenHeader(
                    title: "Saved",
                    subtitle: "Reopen design cards, colors, and consultation reports.",
                    detail: appState.selectedSavedSection.rawValue
                )

                Picker("Saved Section", selection: Bindable(appState).selectedSavedSection) {
                    ForEach(SavedLandingSection.allCases) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, theme.spacingMD)

                Group {
                    switch appState.selectedSavedSection {
                case .previews:
                    previewsSection
                case .colors:
                    colorsSection
                case .reports:
                    reportsSection
                    }
                }
            }
            .padding(.bottom, theme.spacing2XL)
        }
        .background(theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await reportsVM.refreshReports()
        }
    }

    @ViewBuilder
    private var previewsSection: some View {
        VStack(spacing: 0) {
            if visualizerVM.savedVisualizations.isEmpty {
                emptyCard(
                    title: "No design cards yet",
                    body: "Finished previews appear here automatically as design cards you can reopen, share, or save to Photos.",
                    buttonLabel: "Start a Preview"
                ) {
                    tabRouter.openVisualizer(appState: appState, route: .photoUpload)
                }
            } else {
                LazyVGrid(columns: previewColumns, spacing: 12) {
                    ForEach(visualizerVM.savedVisualizations) { visualization in
                        Button {
                            router.navigate(to: .savedPreviewDetail(visualization: visualization))
                        } label: {
                            VStack(alignment: .leading, spacing: theme.space8) {
                                VisualizationLoadedImageView(
                                    visualization: visualization,
                                    role: .after,
                                    preset: .savedGrid,
                                    contentMode: .fill
                                ) {
                                    RoundedRectangle(cornerRadius: theme.radiusLG)
                                        .fill(Color(hex: visualization.colorHex).opacity(0.22))
                                }
                                .frame(height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))

                                Text(visualization.colorName)
                                    .font(theme.heading3)
                                    .lineLimit(1)
                                Text(visualization.roomName)
                                    .font(theme.caption)
                                    .foregroundStyle(theme.mutedForeground)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(theme.space12)
                            .background(theme.card)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
                            .overlay(
                                RoundedRectangle(cornerRadius: theme.radiusXL)
                                    .stroke(theme.borderSubtle, lineWidth: 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .accessibilityIdentifier("saved.previews.card")
                    }
                }
                .padding(.horizontal, theme.spacingMD)
            }
        }
        .accessibilityIdentifier("saved.currentSection.previews")
    }

    @ViewBuilder
    private var colorsSection: some View {
        VStack(spacing: 0) {
            if favoritesVM.favorites.isEmpty {
                emptyCard(
                    title: "No saved colors yet",
                    body: "Save colors from the matcher or a room preview to build your shortlist.",
                    buttonLabel: "Open Color Matcher"
                ) {
                    tabRouter.openVisualizer(appState: appState, route: .colorMatcher)
                }
            } else {
                LazyVGrid(columns: colorColumns, spacing: 12) {
                    ForEach(favoritesVM.favorites) { color in
                        Button {
                            visualizerVM.startFlow(with: color)
                            tabRouter.openVisualizer(appState: appState, route: .itemPicker)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                RoundedRectangle(cornerRadius: theme.radiusLG)
                                    .fill(color.color)
                                    .frame(height: 110)

                                Text(color.name)
                                    .font(theme.heading3)
                                    .foregroundStyle(theme.foreground)
                                    .lineLimit(1)
                                Text("\(color.brand.displayName) • \(color.number)")
                                    .font(theme.caption)
                                    .foregroundStyle(theme.mutedForeground)
                            }
                            .padding(theme.space12)
                            .background(theme.card)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
                            .overlay(
                                RoundedRectangle(cornerRadius: theme.radiusXL)
                                    .stroke(theme.borderSubtle, lineWidth: 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, theme.spacingMD)
            }
        }
        .accessibilityIdentifier("saved.currentSection.colors")
    }

    @ViewBuilder
    private var reportsSection: some View {
        VStack(spacing: 0) {
            if reportsVM.reports.isEmpty {
                emptyCard(
                    title: "No consultation reports yet",
                    body: "Reports appear here after checkout and stay easy to reopen while they generate and once they are ready.",
                    buttonLabel: "Explore Expert Help"
                ) {
                    appState.selectedTab = .expert
                }
            } else {
                VStack(spacing: theme.space12) {
                    ForEach(reportsVM.reports) { report in
                        Button {
                            router.navigate(to: .masterReport(reportId: report.id))
                        } label: {
                            HStack(spacing: theme.space12) {
                                Circle()
                                    .fill(theme.primary.opacity(0.12))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: report.status == .ready ? "doc.text.fill" : "clock.fill")
                                            .foregroundStyle(theme.primary)
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(report.title)
                                        .font(theme.heading3)
                                        .foregroundStyle(theme.foreground)
                                    Text(report.status == .ready ? "Ready to review" : "Generating")
                                        .font(theme.caption)
                                        .foregroundStyle(theme.mutedForeground)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(theme.mutedForeground)
                            }
                            .padding(theme.space16)
                            .background(theme.card)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
                            .overlay(
                                RoundedRectangle(cornerRadius: theme.radiusXL)
                                    .stroke(theme.borderSubtle, lineWidth: 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, theme.spacingMD)
            }
        }
        .accessibilityIdentifier("saved.currentSection.reports")
    }

    private func emptyCard(title: String, body: String, buttonLabel: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: theme.space16) {
            Text(title)
                .font(theme.heading2)
                .foregroundStyle(theme.foreground)
            Text(body)
                .font(theme.bodySmall)
                .foregroundStyle(theme.mutedForeground)
                .multilineTextAlignment(.center)
            AppButton(buttonLabel, variant: .outline, icon: "arrow.right", action: action)
        }
        .padding(theme.space24)
        .frame(maxWidth: .infinity)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusXL)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
        .padding(.horizontal, theme.spacingMD)
    }
}

private enum SavedPreviewSheetDestination: String, Identifiable {
    case share

    var id: String { rawValue }
}

struct SavedPreviewDetailView: View {
    @Environment(Theme.self) private var theme
    @Environment(AppState.self) private var appState
    @Environment(TabRouter.self) private var tabRouter
    @Environment(VisualizerViewModel.self) private var visualizerVM

    let visualization: Visualization

    @State private var showFullscreen = false
    @State private var showComparisonPreview = false
    @State private var beforeImage: UIImage?
    @State private var afterImage: UIImage?
    @State private var designCardImage: UIImage?
    @State private var didAttemptImageLoad = false
    @State private var isPreparingDesignCard = false
    @State private var showOverflowActions = false
    @State private var showToast = false
    @State private var toastMessage = "Saved to Photos"
    @State private var activeSheet: SavedPreviewSheetDestination?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: theme.space16) {
                designCardHero
                colorSummaryCard
            }
            .padding(.vertical, theme.spacingMD)
            .padding(.bottom, theme.spacingXL)
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle(visualization.roomName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    activeSheet = .share
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel(primaryShareTitle)
                .accessibilityIdentifier("savedPreviewDetail.share")

                Button {
                    showOverflowActions = true
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("More Actions")
                .accessibilityIdentifier("savedPreviewDetail.more")
            }
        }
        .confirmationDialog("Design Card Actions", isPresented: $showOverflowActions, titleVisibility: .visible) {
            Button("Open Before/After Preview") {
                showComparisonPreview = true
            }
            .accessibilityIdentifier("savedPreviewDetail.openComparison")

            Button("Save to Photos") {
                saveDesignCardToPhotos()
            }
            .accessibilityIdentifier("savedPreviewDetail.saveToPhotos")

            Button("Reopen Preview") {
                reopenPreviewInVisualizer()
            }
            .accessibilityIdentifier("savedPreviewDetail.edit")

            Button("Cancel", role: .cancel) {}
        }
        .toast(isPresented: $showToast, message: toastMessage, icon: "checkmark.circle.fill")
        .task(id: visualization.id) {
            await loadSavedPreviewAssets()
        }
        .fullScreenCover(isPresented: $showFullscreen) {
            FullscreenImageViewer(
                image: fullscreenImage,
                title: fullscreenTitle,
                uiImage: fullscreenUIImage
            )
        }
        .sheet(item: $activeSheet) { _ in
            SavedPreviewShareSheet(
                visualization: visualization,
                beforeImage: beforeImage,
                afterImage: afterImage,
                initialExportImage: designCardImage,
                onEdit: reopenPreviewInVisualizer
            )
        }
        .sheet(isPresented: $showComparisonPreview) {
            SavedPreviewComparisonSheet(
                title: visualization.colorName,
                beforeImage: beforeImage,
                afterImage: afterImage
            )
        }
    }

    private var primaryShareTitle: String {
        visualization.shareLinks() == nil ? "Share Preview Image" : "Share Design Card"
    }

    private var fullscreenTitle: String {
        designCardImage == nil ? visualization.colorName : "\(visualization.colorName) Design Card"
    }

    private var fullscreenImage: Image {
        if let designCardImage {
            return Image(uiImage: designCardImage)
        }
        if let afterImage {
            return Image(uiImage: afterImage)
        }
        return Image(systemName: "photo.fill")
    }

    private var fullscreenUIImage: UIImage? {
        designCardImage ?? afterImage
    }

    private var designCardRenderKey: String {
        [
            visualization.id,
            visualization.colorHex,
            visualization.colorCode,
            beforeImage.map(Self.imageIdentity(for:)) ?? "no-before",
            afterImage.map(Self.imageIdentity(for:)) ?? "no-after",
        ].joined(separator: "|")
    }

    private func reopenPreviewInVisualizer() {
        Task { @MainActor in
            await visualizerVM.restoreDraft(from: visualization)
            tabRouter.openVisualizer(
                appState: appState,
                route: .visualizationDetail(visualization: visualization)
            )
        }
    }

    @ViewBuilder
    private var designCardHero: some View {
        if let designCardImage {
            designCardContainer {
                Image(uiImage: designCardImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
            }
        } else {
            designCardLoadingPlaceholder
        }
    }

    private var designCardLoadingPlaceholder: some View {
        VStack(spacing: theme.space12) {
            if isPreparingDesignCard || visualization.afterImageSource != nil {
                ProgressView()
            }

            Text(isPreparingDesignCard ? "Preparing design card..." : "Loading design card...")
                .font(theme.caption)
                .foregroundStyle(theme.mutedForeground)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 320)
        .background(theme.secondary)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusXL)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
        .padding(.horizontal, theme.spacingMD)
        .accessibilityIdentifier("savedPreviewDetail.designCard")
    }

    private func designCardContainer<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        Button {
            showFullscreen = true
        } label: {
            ZStack(alignment: .bottomTrailing) {
                content()

                Label("View Larger", systemImage: "arrow.up.left.and.arrow.down.right")
                    .font(theme.captionSmall.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Capsule())
                    .padding(theme.space12)
                    .allowsHitTesting(false)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("savedPreviewDetail.viewLarger")
        .frame(maxWidth: .infinity)
        .frame(minHeight: 320)
        .background(theme.secondary)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusXL)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
        .padding(.horizontal, theme.spacingMD)
        .accessibilityIdentifier("savedPreviewDetail.designCard")
    }

    private var colorSummaryCard: some View {
        VStack(alignment: .leading, spacing: theme.space20) {
            HStack(alignment: .top, spacing: theme.space16) {
                swatchTile

                VStack(alignment: .leading, spacing: theme.space8) {
                    summaryBadge

                    Text(visualization.colorName)
                        .font(theme.heading1)
                        .foregroundStyle(theme.foreground)

                    Text("\(visualization.inferredBrand.displayName) • \(visualization.colorCode)")
                        .font(theme.bodySmall)
                        .foregroundStyle(theme.mutedForeground)

                    Text("Saved \(visualization.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(theme.caption)
                        .foregroundStyle(theme.mutedForeground)
                }

                Spacer(minLength: 0)
            }

            summaryChip(text: visualization.surface, systemImage: "square.split.diagonal")

            Rectangle()
                .fill(theme.borderSubtle)
                .frame(height: 1)

            HStack(alignment: .bottom, spacing: theme.space16) {
                summaryShareCopy
                    .frame(maxWidth: .infinity, alignment: .leading)

                summaryShareButton
            }
        }
        .padding(theme.space20)
        .background {
            RoundedRectangle(cornerRadius: theme.radiusXL)
                .fill(theme.card)
                .shadow(color: .black.opacity(0.07), radius: 22, y: 10)
        }
        .overlay {
            RoundedRectangle(cornerRadius: theme.radiusXL)
                .stroke(theme.borderSubtle, lineWidth: 1)
        }
        .padding(.horizontal, theme.spacingMD)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("savedPreviewDetail.summaryCard")
    }

    private var swatchTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(hex: visualization.colorHex))

            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.18),
                            Color.white.opacity(0.05),
                            .clear,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .frame(width: 88, height: 88)
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.white.opacity(0.72), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.14), radius: 14, y: 8)
        .accessibilityHidden(true)
    }

    private var summaryBadge: some View {
        HStack(spacing: theme.space8) {
            Circle()
                .fill(theme.mutedForeground.opacity(0.5))
                .frame(width: 6, height: 6)

            Text("Saved Color Story")
                .font(theme.micro.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(theme.mutedForeground)
        }
        .padding(.horizontal, theme.space12)
        .padding(.vertical, 7)
        .background(theme.background.opacity(0.86))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(theme.borderSubtle, lineWidth: 1)
        }
    }

    private func summaryChip(text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(theme.caption.weight(.semibold))
            .foregroundStyle(theme.mutedForeground)
            .padding(.horizontal, theme.space12)
            .padding(.vertical, 10)
            .background(theme.secondary)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(theme.borderSubtle, lineWidth: 1)
            }
    }

    private var summaryShareCopy: some View {
        Text(summaryShareBody)
            .font(theme.caption)
            .foregroundStyle(theme.mutedForeground)
            .fixedSize(horizontal: false, vertical: true)
            .layoutPriority(1)
    }

    private var summaryShareButton: some View {
        Button {
            activeSheet = .share
        } label: {
            Label(primaryShareTitle, systemImage: "square.and.arrow.up")
                .font(theme.captionSmall.weight(.semibold))
                .foregroundStyle(theme.primary)
                .padding(.horizontal, theme.space12)
                .padding(.vertical, 10)
                .frame(minHeight: 40)
                .background(theme.primary.opacity(0.12))
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(theme.primary.opacity(0.18), lineWidth: 1)
                }
                .contentShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(primaryShareTitle)
        .accessibilityHint("Opens sharing options for this saved design card.")
        .accessibilityIdentifier("savedPreviewDetail.summaryShare")
    }

    private var summaryShareBody: String {
        if visualization.shareLinks() != nil {
            return "Share this saved color story as a polished design card."
        }
        return "Share this saved color story from this device."
    }

    private func loadSavedPreviewAssets() async {
        didAttemptImageLoad = false
        designCardImage = nil
        isPreparingDesignCard = false
        async let loadedBeforeImage = VisualizationImageRepository.shared.loadImage(
            for: visualization,
            role: .before,
            preset: .detail
        )
        async let loadedAfterImage = VisualizationImageRepository.shared.loadImage(
            for: visualization,
            role: .after,
            preset: .detail
        )

        beforeImage = await loadedBeforeImage
        afterImage = await loadedAfterImage
        didAttemptImageLoad = true
        await prepareDesignCardImage()
    }

    private func prepareDesignCardImage() async {
        guard let afterImage else {
            designCardImage = nil
            isPreparingDesignCard = false
            return
        }

        isPreparingDesignCard = true
        await Task.yield()

        if Task.isCancelled { return }

        let renderedImage = SavedPreviewDesignCardRenderer.render(
            theme: theme,
            visualization: visualization,
            beforeImage: beforeImage,
            afterImage: afterImage
        )

        if Task.isCancelled { return }
        designCardImage = renderedImage
        isPreparingDesignCard = false
    }

    private func saveDesignCardToPhotos() {
        guard let exportImage = designCardImage ?? afterImage else {
            toastMessage = "Preview image unavailable"
            showToast = true
            return
        }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    toastMessage = "Photo access denied"
                    showToast = true
                }
                return
            }

            UIImageWriteToSavedPhotosAlbum(exportImage, nil, nil, nil)
            DispatchQueue.main.async {
                toastMessage = "Saved to Photos"
                showToast = true
            }
        }
    }

    private static func imageIdentity(for image: UIImage) -> String {
        "\(Int(image.size.width))x\(Int(image.size.height))-\(image.imageOrientation.rawValue)"
    }
}

private struct SavedPreviewComparisonSheet: View {
    @Environment(Theme.self) private var theme
    @Environment(\.dismiss) private var dismiss

    let title: String
    let beforeImage: UIImage?
    let afterImage: UIImage?

    @State private var showBeforeAfter = true
    @State private var showFullscreen = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: theme.space16) {
                    comparisonModePicker
                    comparisonSection
                }
                .padding(.vertical, theme.spacingMD)
                .padding(.bottom, theme.spacingXL)
            }
            .background(theme.background.ignoresSafeArea())
            .navigationTitle("Before & After")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showFullscreen) {
            FullscreenImageViewer(
                image: displayAfterImage,
                title: title,
                uiImage: afterImage
            )
        }
    }

    private var comparisonModePicker: some View {
        HStack(spacing: 0) {
            toggleButton(
                "After Only",
                identifier: "savedPreviewComparison.mode.afterOnly",
                isActive: !showBeforeAfter
            ) {
                showBeforeAfter = false
            }
            toggleButton(
                "Before & After",
                identifier: "savedPreviewComparison.mode.beforeAfter",
                isActive: showBeforeAfter
            ) {
                showBeforeAfter = true
            }
        }
        .padding(4)
        .background(theme.muted)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))
        .padding(.horizontal, theme.spacingMD)
    }

    @ViewBuilder
    private var comparisonSection: some View {
        if showBeforeAfter {
            if let beforeImage, let afterImage {
                previewContainer {
                    ComparisonSliderView(
                        beforeImage: Image(uiImage: beforeImage),
                        afterImage: Image(uiImage: afterImage)
                    )
                    .aspectRatio(comparisonAspectRatio, contentMode: .fit)
                }
            } else {
                loadingImagePlaceholder
            }
        } else if let afterImage {
            previewContainer {
                Image(uiImage: afterImage)
                    .resizable()
                    .scaledToFit()
            }
        } else {
            loadingImagePlaceholder
        }
    }

    private var displayAfterImage: Image {
        if let afterImage {
            return Image(uiImage: afterImage)
        }
        return Image(systemName: "photo.fill")
    }

    private var loadingImagePlaceholder: some View {
        VStack(spacing: theme.space12) {
            ProgressView()
            Text("Loading preview...")
                .font(theme.caption)
                .foregroundStyle(theme.mutedForeground)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 320)
        .background(theme.secondary)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusXL)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
        .padding(.horizontal, theme.spacingMD)
        .accessibilityIdentifier("savedPreviewComparison.preview")
    }

    private func previewContainer<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        Button {
            showFullscreen = true
        } label: {
            ZStack(alignment: .bottomTrailing) {
                content()
                    .frame(maxWidth: .infinity)

                Label("View Larger", systemImage: "arrow.up.left.and.arrow.down.right")
                    .font(theme.captionSmall.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Capsule())
                    .padding(theme.space12)
                    .allowsHitTesting(false)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 320)
        .background(theme.secondary)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusXL)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
        .padding(.horizontal, theme.spacingMD)
        .accessibilityIdentifier("savedPreviewComparison.preview")
    }

    private var comparisonAspectRatio: CGFloat {
        if let afterImage {
            return afterImage.size.width / max(afterImage.size.height, 1)
        }
        if let beforeImage {
            return beforeImage.size.width / max(beforeImage.size.height, 1)
        }
        return 3.0 / 4.0
    }

    private func toggleButton(
        _ label: String,
        identifier: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(theme.subhead)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(isActive ? .white : theme.mutedForeground)
                .background(isActive ? theme.primary : .clear)
                .clipShape(RoundedRectangle(cornerRadius: theme.radiusSM))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isActive ? .isSelected : [])
        .accessibilityValue(isActive ? "selected" : "not selected")
        .accessibilityIdentifier(identifier)
    }
}

private struct SavedPreviewShareSheet: View {
    @Environment(Theme.self) private var theme
    @Environment(\.dismiss) private var dismiss

    let visualization: Visualization
    let beforeImage: UIImage?
    let afterImage: UIImage?
    let initialExportImage: UIImage?
    let onEdit: () -> Void

    @State private var exportImageState: SavedPreviewExportImageState = .idle
    @State private var showToast = false
    @State private var toastMessage = "Share link copied"
    @State private var activeShareSheet: ActivityShareSheetPayload?

    private var shareLinks: VisualizationShareLinks? {
        visualization.shareLinks()
    }

    private var exportDescriptor: SavedPreviewExportDescriptor {
        SavedPreviewExportResolver.resolve(
            imageState: exportImageState,
            afterImage: afterImage,
            colorName: visualization.colorName
        )
    }

    private var designCardRenderKey: String {
        [
            visualization.id,
            visualization.colorHex,
            visualization.colorCode,
            beforeImage.map(Self.imageIdentity(for:)) ?? "no-before",
            afterImage.map(Self.imageIdentity(for:)) ?? "no-after",
        ].joined(separator: "|")
    }

    init(
        visualization: Visualization,
        beforeImage: UIImage?,
        afterImage: UIImage?,
        initialExportImage: UIImage? = nil,
        onEdit: @escaping () -> Void
    ) {
        self.visualization = visualization
        self.beforeImage = beforeImage
        self.afterImage = afterImage
        self.initialExportImage = initialExportImage
        self.onEdit = onEdit
        _exportImageState = State(initialValue: initialExportImage.map(SavedPreviewExportImageState.ready) ?? .idle)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: theme.space20) {
                    shareCardPreview

                    VStack(alignment: .leading, spacing: theme.space12) {
                        Text("Export Options")
                            .font(theme.heading2)
                            .foregroundStyle(theme.foreground)

                        primaryShareAction
                            .accessibilityIdentifier("savedPreviewShareSheet.sharePrimary")

                        if let shareURL = shareLinks?.sharePageURL {
                            Button {
                                UIPasteboard.general.string = shareURL.absoluteString
                                toastMessage = "Share link copied"
                                showToast = true
                            } label: {
                                labelRow(
                                    title: "Copy Share Link",
                                    detail: shareURL.absoluteString,
                                    icon: "link"
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("savedPreviewShareSheet.copyLink")
                        }

                        Button {
                            saveExportImageToPhotos()
                        } label: {
                            labelRow(
                                title: exportDescriptor.saveTitle,
                                detail: exportDescriptor.saveDetail,
                                icon: "square.and.arrow.down"
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!exportDescriptor.canExport)
                        .opacity(exportDescriptor.canExport ? 1 : 0.6)
                        .accessibilityIdentifier("savedPreviewShareSheet.saveToPhotos")

                        Button {
                            dismiss()
                            onEdit()
                        } label: {
                            labelRow(
                                title: "Reopen Preview",
                                detail: "Reopen the editable detail flow for this room.",
                                icon: "slider.horizontal.3"
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("savedPreviewShareSheet.edit")
                    }
                }
                .padding(.horizontal, theme.spacingMD)
                .padding(.vertical, theme.spacingMD)
            }
            .background(theme.background.ignoresSafeArea())
            .navigationTitle(shareLinks == nil ? "Share Preview Image" : "Share Design Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .toast(isPresented: $showToast, message: toastMessage, icon: "checkmark.circle.fill")
        .task(id: designCardRenderKey) {
            if initialExportImage == nil {
                await prepareExportImage()
            }
        }
        .sheet(item: $activeShareSheet) { payload in
            ActivityShareSheet(payload: payload)
        }
    }

    @ViewBuilder
    private var primaryShareAction: some View {
        if let exportImage = exportDescriptor.image {
            Button {
                activeShareSheet = ActivityShareSheetPayload(
                    title: exportDescriptor.shareSheetTitle,
                    items: visualization.shareActivityItems(image: exportImage)
                )
            } label: {
                primaryShareLabel(
                    title: exportDescriptor.primaryTitle,
                    detail: exportDescriptor.primaryDetail
                )
            }
            .buttonStyle(.plain)
        } else if exportDescriptor.isLoading {
            primaryShareLabel(
                title: exportDescriptor.primaryTitle,
                detail: exportDescriptor.primaryDetail
            )
            .opacity(0.6)
        } else {
            primaryShareLabel(
                title: exportDescriptor.primaryTitle,
                detail: exportDescriptor.primaryDetail
            )
            .opacity(0.6)
        }
    }

    private var shareCardPreview: some View {
        VStack(alignment: .leading, spacing: theme.space12) {
            Text("Design Card Preview")
                .font(theme.heading2)
                .foregroundStyle(theme.foreground)

            ZStack {
                Group {
                    if let exportImage = exportDescriptor.image {
                        Image(uiImage: exportImage)
                            .resizable()
                            .scaledToFit()
                            .accessibilityIdentifier(
                                exportDescriptor.kind == .designCard
                                    ? "savedPreviewShareSheet.designCardReady"
                                    : "savedPreviewShareSheet.previewFallback"
                            )
                    } else if let afterImage {
                        SavedPreviewDesignCardView(
                            theme: theme,
                            visualization: visualization,
                            beforeImage: beforeImage,
                            afterImage: afterImage,
                            canvasSize: SavedPreviewDesignCardRenderer.canvasSize(for: afterImage)
                        )
                        .accessibilityIdentifier("savedPreviewShareSheet.designCardRendering")
                    } else {
                        RoundedRectangle(cornerRadius: theme.radiusXL)
                            .fill(theme.secondary)
                            .overlay(
                                ProgressView()
                            )
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 320)
                .background(theme.secondary)
                .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
            }
        }
    }

    private func primaryShareLabel(title: String, detail: String) -> some View {
        labelRow(
            title: title,
            detail: detail,
            icon: "square.and.arrow.up",
            isPrimary: true
        )
    }

    private func labelRow(
        title: String,
        detail: String,
        icon: String,
        isPrimary: Bool = false
    ) -> some View {
        HStack(alignment: .top, spacing: theme.space12) {
            Circle()
                .fill((isPrimary ? theme.primary : theme.secondary).opacity(isPrimary ? 0.16 : 1))
                .frame(width: 42, height: 42)
                .overlay(
                    Image(systemName: icon)
                        .foregroundStyle(isPrimary ? theme.primary : theme.foreground)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(theme.heading3)
                    .foregroundStyle(theme.foreground)
                Text(detail)
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(theme.mutedForeground)
        }
        .padding(theme.space16)
        .background(isPrimary ? theme.primary.opacity(0.08) : theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusXL)
                .stroke(isPrimary ? theme.primary.opacity(0.18) : theme.borderSubtle, lineWidth: 1)
        )
    }

    private func prepareExportImage() async {
        guard let afterImage else {
            exportImageState = .failed
            return
        }

        exportImageState = .rendering
        await Task.yield()

        if Task.isCancelled { return }

        let renderedImage = SavedPreviewDesignCardRenderer.render(
            theme: theme,
            visualization: visualization,
            beforeImage: beforeImage,
            afterImage: afterImage
        )

        if Task.isCancelled { return }
        exportImageState = renderedImage.map(SavedPreviewExportImageState.ready) ?? .failed
    }

    private func saveExportImageToPhotos() {
        guard let exportImage = exportDescriptor.image else {
            toastMessage = "Preview image unavailable"
            showToast = true
            return
        }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    toastMessage = "Photo access denied"
                    showToast = true
                }
                return
            }

            UIImageWriteToSavedPhotosAlbum(exportImage, nil, nil, nil)
            DispatchQueue.main.async {
                toastMessage = "Saved to Photos"
                showToast = true
            }
        }
    }

    private static func imageIdentity(for image: UIImage) -> String {
        "\(Int(image.size.width))x\(Int(image.size.height))-\(image.imageOrientation.rawValue)"
    }
}

private struct ActivityShareSheetPayload: Identifiable {
    let id = UUID()
    let title: String
    let items: [Any]
}

private struct ActivityShareSheet: UIViewControllerRepresentable {
    let payload: ActivityShareSheetPayload

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: payload.items,
            applicationActivities: nil
        )
        controller.setValue(payload.title, forKey: "subject")
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

enum SavedPreviewExportImageState {
    case idle
    case rendering
    case ready(UIImage)
    case failed

    var image: UIImage? {
        switch self {
        case .ready(let image):
            return image
        case .idle, .rendering, .failed:
            return nil
        }
    }
}

enum SavedPreviewExportKind {
    case designCard
    case preview
    case unavailable
}

struct SavedPreviewExportDescriptor {
    let kind: SavedPreviewExportKind
    let image: UIImage?
    let primaryTitle: String
    let primaryDetail: String
    let shareSheetTitle: String
    let saveTitle: String
    let saveDetail: String
    let isLoading: Bool

    var canExport: Bool {
        image != nil
    }
}

enum SavedPreviewExportResolver {
    static func resolve(
        imageState: SavedPreviewExportImageState,
        afterImage: UIImage?,
        colorName: String
    ) -> SavedPreviewExportDescriptor {
        switch imageState {
        case .ready(let image):
            return SavedPreviewExportDescriptor(
                kind: .designCard,
                image: image,
                primaryTitle: "Share Design Card",
                primaryDetail: "Includes the painted room, swatch, and before inset.",
                shareSheetTitle: "\(colorName) Design Card",
                saveTitle: "Save to Photos",
                saveDetail: "Save the branded design card to this device.",
                isLoading: false
            )
        case .failed:
            if let afterImage {
                return SavedPreviewExportDescriptor(
                    kind: .preview,
                    image: afterImage,
                    primaryTitle: "Share Preview Image",
                    primaryDetail: "Using the preview image while the design card is unavailable.",
                    shareSheetTitle: "\(colorName) Preview",
                    saveTitle: "Save to Photos",
                    saveDetail: "Save the preview image to this device.",
                    isLoading: false
                )
            }

            return SavedPreviewExportDescriptor(
                kind: .unavailable,
                image: nil,
                primaryTitle: "Preview unavailable",
                primaryDetail: "This image still needs to finish loading.",
                shareSheetTitle: "\(colorName) Preview",
                saveTitle: "Save to Photos",
                saveDetail: "This image still needs to finish loading.",
                isLoading: false
            )
        case .idle, .rendering:
            return SavedPreviewExportDescriptor(
                kind: .unavailable,
                image: nil,
                primaryTitle: afterImage == nil ? "Preview unavailable" : "Preparing Design Card…",
                primaryDetail: afterImage == nil
                    ? "This image still needs to finish loading."
                    : "Building the branded export on this device.",
                shareSheetTitle: "\(colorName) Design Card",
                saveTitle: "Save to Photos",
                saveDetail: afterImage == nil
                    ? "This image still needs to finish loading."
                    : "The branded export is still being prepared.",
                isLoading: afterImage != nil
            )
        }
    }
}

struct SavedPreviewDesignCardRenderer {
    private static let maximumEdge: CGFloat = 1_600
    private static let minimumEdge: CGFloat = 960

    @MainActor
    static func render(
        theme: Theme,
        visualization: Visualization,
        beforeImage: UIImage?,
        afterImage: UIImage,
        scale: CGFloat = 2
    ) -> UIImage? {
        let canvasSize = canvasSize(for: afterImage)
        let content = SavedPreviewDesignCardView(
            theme: theme,
            visualization: visualization,
            beforeImage: beforeImage,
            afterImage: afterImage,
            canvasSize: canvasSize
        )

        let renderer = ImageRenderer(content: content)
        renderer.proposedSize = ProposedViewSize(canvasSize)
        renderer.scale = scale
        renderer.isOpaque = true
        return renderer.uiImage
    }

    static func canvasSize(for image: UIImage) -> CGSize {
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else {
            return CGSize(width: minimumEdge, height: minimumEdge * 1.2)
        }

        if imageSize.width >= imageSize.height {
            let width = max(min(imageSize.width, maximumEdge), minimumEdge)
            return CGSize(width: width, height: width * (imageSize.height / imageSize.width))
        }

        let height = max(min(imageSize.height, maximumEdge), minimumEdge)
        return CGSize(width: height * (imageSize.width / imageSize.height), height: height)
    }
}

struct SavedPreviewDesignCardView: View {
    let theme: Theme
    let visualization: Visualization
    let beforeImage: UIImage?
    let afterImage: UIImage
    let canvasSize: CGSize

    private var outerRadius: CGFloat {
        min(canvasSize.width, canvasSize.height) * 0.055
    }

    private var panelRadius: CGFloat {
        min(canvasSize.width, canvasSize.height) * 0.04
    }

    private var horizontalPadding: CGFloat {
        min(canvasSize.width * 0.05, 52)
    }

    private var verticalPadding: CGFloat {
        min(canvasSize.height * 0.045, 52)
    }

    private var swatchSize: CGFloat {
        min(max(canvasSize.width * 0.12, 56), 96)
    }

    private var beforeInsetWidth: CGFloat {
        min(max(canvasSize.width * 0.2, 92), 168)
    }

    private var chipPadding: CGFloat {
        min(max(canvasSize.width * 0.014, 10), 18)
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(uiImage: afterImage)
                .resizable()
                .scaledToFill()
                .frame(width: canvasSize.width, height: canvasSize.height)
                .clipped()

            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.08),
                    Color.black.opacity(0.78),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: verticalPadding * 0.45) {
                HStack {
                    cardChip(
                        title: "Crain Painting",
                        systemImage: "paintpalette.fill"
                    )

                    Spacer()

                    cardChip(
                        title: visualization.surface,
                        systemImage: "square.split.diagonal"
                    )
                }

                Spacer()

                HStack(alignment: .bottom, spacing: horizontalPadding * 0.5) {
                    VStack(alignment: .leading, spacing: verticalPadding * 0.26) {
                        HStack(spacing: horizontalPadding * 0.34) {
                            RoundedRectangle(cornerRadius: swatchSize * 0.28, style: .continuous)
                                .fill(Color(hex: visualization.colorHex))
                                .frame(width: swatchSize, height: swatchSize)
                                .overlay(
                                    RoundedRectangle(cornerRadius: swatchSize * 0.28, style: .continuous)
                                        .stroke(Color.white.opacity(0.28), lineWidth: 1)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(visualization.colorName)
                                    .font(.system(size: swatchSize * 0.42, weight: .bold, design: .default))
                                    .foregroundStyle(.white)
                                    .lineLimit(2)

                                Text("\(visualization.inferredBrand.displayName) • \(visualization.colorCode)")
                                    .font(.system(size: swatchSize * 0.22, weight: .semibold, design: .default))
                                    .foregroundStyle(.white.opacity(0.86))
                            }
                        }

                        Text("Saved design card")
                            .font(.system(size: swatchSize * 0.2, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.72))
                    }

                    Spacer(minLength: horizontalPadding * 0.35)

                    if let beforeImage {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Before")
                                .font(.system(size: beforeInsetWidth * 0.18, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.84))

                            Image(uiImage: beforeImage)
                                .resizable()
                                .scaledToFill()
                                .frame(
                                    width: beforeInsetWidth,
                                    height: beforeInsetWidth * 0.82
                                )
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: beforeInsetWidth * 0.18, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: beforeInsetWidth * 0.18, style: .continuous)
                                        .stroke(Color.white.opacity(0.24), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding * 0.78)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: panelRadius, style: .continuous)
                        .fill(Color.black.opacity(0.24))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: panelRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .background(theme.secondary)
        .clipShape(RoundedRectangle(cornerRadius: outerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: outerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }

    private func cardChip(title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, chipPadding)
        .padding(.vertical, chipPadding * 0.72)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.28))
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }
}
