import SwiftUI

struct MasterReportView: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @Environment(FavoritesViewModel.self) private var favoritesVM
    @Environment(ReportsViewModel.self) private var reportsVM
    @Environment(VisualizerViewModel.self) private var visualizerVM

    let reportId: String

    @State private var showSavedToast = false
    @State private var toastMessage = "Added to favorites"
    @State private var activeRecommendation: RoomRecommendation?

    private var report: MasterReport? {
        reportsVM.report(for: reportId)
    }

    var body: some View {
        Group {
            if let report {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        profileHeader(report: report)
                            .padding(.horizontal, theme.spacingMD)
                            .padding(.bottom, theme.spacingXL)

                        videoSection(report: report)
                            .padding(.horizontal, theme.spacingMD)
                            .padding(.bottom, theme.spacingXL)

                        sectionHeader(report: report)
                            .padding(.horizontal, theme.spacingMD)
                            .padding(.bottom, theme.spacingMD)

                        VStack(spacing: theme.spacingMD) {
                            ForEach(Array(report.recommendations.enumerated()), id: \.element.id) { index, recommendation in
                                RecommendationCard(
                                    recommendation: recommendation,
                                    beforeImage: beforeImage(for: recommendation),
                                    afterImage: afterImage(for: recommendation),
                                    isFavorite: favoritesVM.isFavorite(recommendation.suggestedColor),
                                    onToggleFavorite: {
                                        let added = favoritesVM.addFavorite(recommendation.suggestedColor)
                                        if !added {
                                            _ = favoritesVM.removeFavorite(recommendation.suggestedColor)
                                        }
                                        toastMessage = added ? "Added to favorites" : "Removed from favorites"
                                        showSavedToast = true
                                    },
                                    onOpenComparison: {
                                        activeRecommendation = recommendation
                                    }
                                )
                                .staggeredAppearance(index: index, delay: 0.08)
                            }
                        }
                        .padding(.horizontal, theme.spacingMD)
                        .padding(.bottom, theme.spacing2XL)
                    }
                    .padding(.top, theme.spacingSM)
                }
            } else {
                ContentUnavailableView("Report unavailable", systemImage: "doc.text.magnifyingglass")
            }
        }
        .navigationTitle("Master Report")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $activeRecommendation) { recommendation in
            MasterReportComparisonViewer(
                recommendation: recommendation,
                beforeImage: beforeImage(for: recommendation),
                afterImage: afterImage(for: recommendation),
                onTryAnotherColor: { color, targetSurface in
                    applySurfaceSelection(targetSurface)
                    let alreadyInGallery = visualizerVM.isSelected(color)
                    let addedToGallery = alreadyInGallery ? false : visualizerVM.addColor(color)
                    let addedToReport = reportsVM.addColorVariant(
                        reportId: reportId,
                        basedOn: recommendation.id,
                        color: color,
                        targetSurface: targetSurface
                    ) != nil

                    if addedToReport {
                        if alreadyInGallery || addedToGallery {
                            toastMessage = "\(color.name) added to report and gallery"
                        } else {
                            toastMessage = "\(color.name) added to report"
                        }
                    } else {
                        toastMessage = "\(color.name) is already in this report"
                    }

                    showSavedToast = true
                }
            )
        }
        .toast(isPresented: $showSavedToast, message: toastMessage, icon: "sparkles")
    }

    // MARK: - Profile Header

    private func profileHeader(report: MasterReport) -> some View {
        VStack(alignment: .leading, spacing: theme.spacingSM) {
            HStack(spacing: theme.spacingSM) {
                // Avatar
                if let photoName = report.curatorPhotoName {
                    Image(photoName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.actionPrimary, theme.actionPrimaryPressed],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text("CC")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(theme.actionPrimaryText)
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(report.title)
                        .font(theme.editorialTitle)
                    Text(report.curatorSubtitle.uppercased())
                        .font(theme.micro)
                        .tracking(0.8)
                        .foregroundStyle(theme.primary)
                }

                Spacer()

                ShareLink(item: shareText(for: report)) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.foreground)
                        .frame(width: 44, height: 44)
                        .background(theme.muted)
                        .clipShape(Circle())
                }
            }

            Rectangle()
                .fill(theme.primary)
                .frame(height: 2)
        }
    }

    // MARK: - Video Section

    private func videoSection(report: MasterReport) -> some View {
        VStack(alignment: .leading, spacing: theme.spacingSM) {
            Text("Your Personalized Video")
                .font(theme.editorialSubtitle)

            Button {
                router.navigate(to: .sampleOutput(reportId: report.id, chapterId: "living-room"))
            } label: {
                ZStack {
                    Group {
                        if let thumbName = report.videoThumbnailName {
                            Image(thumbName)
                                .resizable()
                                .scaledToFill()
                        } else {
                            LinearGradient(
                                colors: [
                                    Color(hex: "4A7C8A"),
                                    Color(hex: "2B5264"),
                                    Color(hex: "1A3140")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    }
                    .aspectRatio(16.0 / 9.0, contentMode: .fill)
                    .clipped()

                    LinearGradient(
                        colors: [.black.opacity(0.1), .black.opacity(0.45)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    VStack(spacing: theme.spacingSM) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 80, height: 80)
                            Circle()
                                .stroke(.white.opacity(0.4), lineWidth: 1.5)
                                .frame(width: 80, height: 80)
                            Image(systemName: "play.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        Text(report.videoTitle)
                            .font(theme.heading3)
                            .foregroundStyle(.white)

                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(timeText(report.videoDuration))
                                .font(theme.captionSmall)
                        }
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
                .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityIdentifier("masterReport.videoButton")
        }
    }

    // MARK: - Section Header

    private func sectionHeader(report: MasterReport) -> some View {
        HStack {
            Text("Recommended Rooms")
                .font(theme.editorialSubtitle)
            Spacer()
            AppBadge(text: "\(report.recommendations.count) COLOR OPTIONS", isFilled: true)
        }
    }

    private func beforeImage(for recommendation: RoomRecommendation) -> Image {
        if let assetName = recommendation.beforeImageName, !assetName.isEmpty {
            return Image(assetName)
        }
        if let photo = visualizerVM.photo {
            return Image(uiImage: photo)
        }
        return Image(systemName: "photo")
    }

    private func afterImage(for recommendation: RoomRecommendation) -> Image {
        if let assetName = recommendation.afterImageName, !assetName.isEmpty {
            return Image(assetName)
        }
        if let photo = visualizerVM.photo {
            return Image(uiImage: tintedPreviewImage(from: photo, hex: recommendation.suggestedColor.hex))
        }
        return Image(systemName: "photo.fill")
    }

    private func applySurfaceSelection(_ surface: String) {
        if let preset = SurfaceType.allCases.first(where: { $0.rawValue == surface && $0 != .custom }) {
            visualizerVM.selectedSurface = preset
            visualizerVM.customSurfaceText = ""
            return
        }
        visualizerVM.selectedSurface = .custom
        visualizerVM.customSurfaceText = surface
    }

    private func tintedPreviewImage(from image: UIImage, hex: String) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        let overlayColor = UIColor(Color(hex: hex))

        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: image.size)
            image.draw(in: rect)
            context.cgContext.setBlendMode(.sourceAtop)
            context.cgContext.setFillColor(overlayColor.withAlphaComponent(0.3).cgColor)
            context.cgContext.fill(rect)
        }
    }

    private func timeText(_ duration: TimeInterval) -> String {
        let total = Int(duration.rounded())
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d Walkthrough", mins, secs)
    }

    private func shareText(for report: MasterReport) -> String {
        "Review my Crain Paint Visualizer report: \(report.title) with \(report.recommendations.count) curated room recommendation\(report.recommendations.count == 1 ? "" : "s")."
    }
}

// MARK: - Recommendation Card

private struct RecommendationCard: View {
    @Environment(Theme.self) private var theme

    let recommendation: RoomRecommendation
    let beforeImage: Image
    let afterImage: Image
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    let onOpenComparison: () -> Void

    var body: some View {
        AppCard(elevation: .raised) {
            VStack(alignment: .leading, spacing: theme.spacingMD) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.roomName)
                        .font(theme.heading2)
                    if let surface = recommendation.targetSurface {
                        Label(surface, systemImage: "square.split.diagonal")
                            .font(theme.caption)
                            .foregroundStyle(theme.mutedForeground)
                    }
                }

                ComparisonSliderView(beforeImage: beforeImage, afterImage: afterImage)
                    .aspectRatio(4.0 / 3.0, contentMode: .fit)
                    .onTapGesture {
                        onOpenComparison()
                    }
                    .overlay(alignment: .bottomTrailing) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 10, weight: .semibold))
                            Text("Tap to expand")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.45))
                        .clipShape(Capsule())
                        .padding(10)
                    }

                HStack(spacing: theme.spacingSM) {
                    Circle()
                        .fill(recommendation.suggestedColor.color)
                        .frame(width: 56, height: 56)
                        .shadow(
                            color: recommendation.suggestedColor.color.opacity(0.35),
                            radius: 6,
                            y: 3
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(recommendation.suggestedColor.name)
                            .font(theme.heading3)
                        Text("\(recommendation.suggestedColor.brand.displayName) • \(recommendation.suggestedColor.number)")
                            .font(theme.captionSmall)
                            .foregroundStyle(theme.mutedForeground)
                    }

                    Spacer()

                    Button(action: onToggleFavorite) {
                        AnimatedHeart(isFavorite: isFavorite)
                            .frame(width: 44, height: 44)
                            .background(theme.muted)
                            .clipShape(Circle())
                    }
                    .buttonStyle(EnhancedButtonStyle(scaleAmount: 0.9))
                }

                HStack(alignment: .top, spacing: theme.spacingSM) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(theme.primary)
                        .frame(width: 3)

                    Text("\"\(recommendation.rationale)\"")
                        .font(theme.editorialQuote)
                        .foregroundStyle(theme.mutedForeground)
                        .lineSpacing(3)
                }
            }
            .padding(theme.spacingMD)
        }
    }
}

private struct MasterReportComparisonViewer: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(Theme.self) private var theme

    let recommendation: RoomRecommendation
    let beforeImage: Image
    let afterImage: Image
    let onTryAnotherColor: (PaintColor, String) -> Void

    @State private var showBeforeAfter = true
    @State private var showColorPicker = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            theme.background
                .ignoresSafeArea()

            VStack(spacing: theme.spacingMD) {
                HStack(spacing: theme.spacingSM) {
                    modeButton(title: "After Only", isActive: !showBeforeAfter) {
                        showBeforeAfter = false
                    }
                    modeButton(title: "Before & After", isActive: showBeforeAfter) {
                        showBeforeAfter = true
                    }
                }
                .padding(4)
                .background(theme.muted)
                .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))
                .padding(.horizontal, theme.spacingMD)
                .padding(.top, 64)

                Group {
                    if showBeforeAfter {
                        ComparisonSliderView(beforeImage: beforeImage, afterImage: afterImage)
                            .aspectRatio(3.0 / 4.0, contentMode: .fit)
                    } else {
                        afterImage
                            .resizable()
                            .scaledToFit()
                            .background(theme.muted.opacity(0.25))
                            .frame(maxWidth: .infinity)
                            .aspectRatio(3.0 / 4.0, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
                    }
                }
                .padding(.horizontal, theme.spacingMD)

                HStack(spacing: theme.spacingSM) {
                    RoundedRectangle(cornerRadius: theme.radiusMD)
                        .fill(recommendation.suggestedColor.color)
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.radiusMD)
                                .stroke(theme.border, lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(recommendation.suggestedColor.name)
                            .font(theme.headline)
                        Text("\(recommendation.suggestedColor.brand.displayName) • \(recommendation.suggestedColor.number)")
                            .font(theme.caption)
                            .foregroundStyle(theme.mutedForeground)
                    }

                    Spacer()
                }
                .padding(.horizontal, theme.spacingMD)

                AppButton("Try Another Color", variant: .outline, icon: "paintpalette.fill") {
                    showColorPicker = true
                }
                .padding(.horizontal, theme.spacingMD)

                Text("Choose another color and optionally switch to a different surface without re-uploading.")
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, theme.spacingLG)

                Spacer()
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .white.opacity(0.3))
            }
            .padding(20)
            .accessibilityLabel("Close full screen preview")
        }
        .sheet(isPresented: $showColorPicker) {
            QuickColorPickerSheet(
                initialBrand: recommendation.suggestedColor.brand,
                initialSurface: recommendation.targetSurface ?? SurfaceType.walls.rawValue
            ) { color, surface in
                onTryAnotherColor(color, surface)
            }
        }
        .statusBarHidden()
    }

    private func modeButton(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(theme.subhead)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(isActive ? .white : theme.mutedForeground)
                .background(isActive ? theme.primary : .clear)
                .clipShape(RoundedRectangle(cornerRadius: theme.radiusSM))
        }
    }
}

private struct QuickColorPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(Theme.self) private var theme

    @State private var viewModel: ColorCatalogViewModel
    @State private var selectedSurface: SurfaceType
    @State private var customSurfaceText: String

    let onSelect: (PaintColor, String) -> Void

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]
    private let surfaceChoices: [SurfaceType] = [.walls, .trimBase, .accentWall, .doors, .cabinets, .ceiling, .custom]

    init(initialBrand: PaintBrand, initialSurface: String, onSelect: @escaping (PaintColor, String) -> Void) {
        self.onSelect = onSelect

        let vm = ColorCatalogViewModel()
        vm.selectedBrand = initialBrand
        vm.selectedFilter = .all
        _viewModel = State(initialValue: vm)

        if let matchedSurface = SurfaceType.allCases.first(where: { $0.rawValue == initialSurface }) {
            _selectedSurface = State(initialValue: matchedSurface)
            _customSurfaceText = State(initialValue: "")
        } else {
            _selectedSurface = State(initialValue: .custom)
            _customSurfaceText = State(initialValue: initialSurface)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: theme.spacingSM) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(theme.mutedForeground)
                        TextField("Search by color name or number", text: $viewModel.searchText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(theme.muted)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))

                    Picker("Brand", selection: $viewModel.selectedBrand) {
                        ForEach(ColorCatalogViewModel.availableBrands, id: \.self) { brand in
                            Text(brand.displayName).tag(brand)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Scope", selection: $viewModel.selectedFilter) {
                        Text("Popular").tag(ColorCatalogViewModel.ColorFilter.popular)
                        Text("All Colors").tag(ColorCatalogViewModel.ColorFilter.all)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, theme.spacingMD)
                .padding(.top, theme.spacingMD)

                VStack(alignment: .leading, spacing: theme.spacingSM) {
                    Text("Paint Target")
                        .font(theme.captionSmall)
                        .foregroundStyle(theme.mutedForeground)
                        .textCase(.uppercase)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: theme.spacingSM) {
                            ForEach(surfaceChoices, id: \.self) { surface in
                                Button {
                                    selectedSurface = surface
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: surface.iconName)
                                        Text(surface.rawValue)
                                    }
                                    .font(theme.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .foregroundStyle(selectedSurface == surface ? .white : theme.foreground)
                                    .background(selectedSurface == surface ? theme.primary : theme.muted)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if selectedSurface == .custom {
                        TextField("Describe the part to paint (e.g., fireplace mantel)", text: $customSurfaceText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(theme.muted)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))
                    }
                }
                .padding(.horizontal, theme.spacingMD)
                .padding(.top, theme.spacingMD)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.filteredColors) { color in
                            Button {
                                onSelect(color, selectedSurfaceText)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    RoundedRectangle(cornerRadius: theme.radiusSM)
                                        .fill(color.color)
                                        .frame(height: 68)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: theme.radiusSM)
                                                .stroke(theme.border, lineWidth: 1)
                                        )

                                    Text(color.name)
                                        .font(theme.subhead)
                                        .foregroundStyle(theme.foreground)
                                        .lineLimit(1)

                                    Text("\(color.brand.displayName) • \(color.number)")
                                        .font(theme.micro)
                                        .foregroundStyle(theme.mutedForeground)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .background(theme.card)
                                .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))
                                .overlay(
                                    RoundedRectangle(cornerRadius: theme.radiusMD)
                                        .stroke(theme.border, lineWidth: 1)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, theme.spacingMD)
                    .padding(.vertical, theme.spacingMD)
                }
            }
            .navigationTitle("Try Another Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var selectedSurfaceText: String {
        if selectedSurface == .custom {
            let trimmed = customSurfaceText.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? SurfaceType.custom.rawValue : trimmed
        }
        return selectedSurface.rawValue
    }
}
