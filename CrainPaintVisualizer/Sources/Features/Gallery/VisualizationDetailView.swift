import SwiftUI

struct VisualizationDetailView: View {
    @Environment(Theme.self) private var theme
    @Environment(AppState.self) private var appState
    @Environment(TabRouter.self) private var tabRouter
    @Environment(RouterPath.self) private var router
    @Environment(FavoritesViewModel.self) private var favoritesVM
    @Environment(VisualizerViewModel.self) private var visualizerVM

    let visualization: Visualization

    @State private var showBeforeAfter = true
    @State private var showToast = false
    @State private var toastMessage = "Saved to favorites"
    @State private var showFullscreen = false
    @State private var beforeImage: UIImage?
    @State private var afterImage: UIImage?
    @State private var didAttemptImageLoad = false

    private var paintColor: PaintColor { visualization.asPaintColor }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: theme.space20) {
                    comparisonModePicker

                    comparisonSection

                    saveConfirmationCard

                    colorSummaryCard

                    editActions

                    expertBridgeCard
                }
                .padding(.vertical, theme.spacingMD)
                .padding(.bottom, 120)
            }

            FloatingActionBar {
                HStack(spacing: theme.space12) {
                    AppButton("Open Design Card", variant: .cta, icon: "bookmark.fill") {
                        openSavedPreview()
                    }
                    .accessibilityIdentifier("visualizationDetail.openSaved")

                    AppButton("Try Another Color", variant: .outline, icon: "arrow.clockwise") {
                        router.navigate(to: .itemPicker)
                    }
                    .accessibilityIdentifier("visualizationDetail.tryAnother")
                }
            }
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle(visualization.roomName)
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.success, trigger: showToast)
        .toast(isPresented: $showToast, message: toastMessage, icon: "checkmark.circle.fill")
        .task(id: visualization.id) {
            await loadReferenceImages()
        }
        .fullScreenCover(isPresented: $showFullscreen) {
            FullscreenImageViewer(
                image: displayAfterImage,
                title: visualization.colorName,
                uiImage: afterImage
            )
        }
    }

    private var comparisonModePicker: some View {
        HStack(spacing: 0) {
            toggleButton("After Only", identifier: "visualizationDetail.mode.afterOnly", isActive: !showBeforeAfter) {
                showBeforeAfter = false
            }
            toggleButton("Before & After", identifier: "visualizationDetail.mode.beforeAfter", isActive: showBeforeAfter) {
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
                previewContainer(canExpand: true) {
                    ComparisonSliderView(
                        beforeImage: Image(uiImage: beforeImage),
                        afterImage: Image(uiImage: afterImage)
                    )
                    .aspectRatio(comparisonAspectRatio, contentMode: .fit)
                }
            } else if visualization.hasReferenceImages && !didAttemptImageLoad {
                loadingImagePlaceholder
            } else {
                singleImageSection
            }
        } else {
            singleImageSection
        }
    }

    private var displayAfterImage: Image {
        if let afterImage {
            return Image(uiImage: afterImage)
        }
        if let referencePhoto = visualizerVM.photo {
            return Image(uiImage: tintedPreviewImage(from: referencePhoto, hex: visualization.colorHex))
        }
        return Image(systemName: "photo.fill")
    }

    @ViewBuilder
    private var singleImageSection: some View {
        if let afterImage {
            previewContainer(canExpand: true) {
                Image(uiImage: afterImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
            }
        } else if visualization.afterImageSource != nil && !didAttemptImageLoad {
            loadingImagePlaceholder
        } else {
            previewContainer(canExpand: true) {
                displayAfterImage
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
            }
        }
    }

    private var loadingImagePlaceholder: some View {
        VStack(spacing: theme.space12) {
            ProgressView()
            Text("Loading preview...")
                .font(theme.caption)
                .foregroundStyle(theme.mutedForeground)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(comparisonAspectRatio, contentMode: .fit)
        .background(theme.secondary)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
        .padding(.horizontal, theme.spacingMD)
    }

    private func previewContainer<Content: View>(
        canExpand: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Group {
            if canExpand {
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
                .accessibilityIdentifier("visualizationDetail.viewLarger")
            } else {
                content()
            }
        }
        .padding(.horizontal, theme.spacingMD)
    }

    private var comparisonAspectRatio: CGFloat {
        if let afterImage {
            return afterImage.size.width / max(afterImage.size.height, 1)
        }
        if let beforeImage {
            return beforeImage.size.width / max(beforeImage.size.height, 1)
        }
        if let referencePhoto = visualizerVM.photo {
            return referencePhoto.size.width / max(referencePhoto.size.height, 1)
        }
        return 3.0 / 4.0
    }

    private var saveConfirmationCard: some View {
        HStack(alignment: .top, spacing: theme.space12) {
            Circle()
                .fill(theme.primary.opacity(0.12))
                .frame(width: 42, height: 42)
                .overlay(
                    Image(systemName: "bookmark.fill")
                        .foregroundStyle(theme.primary)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Design card ready")
                    .font(theme.heading3)
                    .foregroundStyle(theme.foreground)
                    .accessibilityIdentifier("visualizationDetail.savedStatus")
                Text("This preview is already saved in Saved > Design Cards. Open it to see the full design card, share it, save to Photos, or reopen later.")
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button("Open Design Card") {
                openSavedPreview()
            }
            .font(theme.captionSmall.weight(.semibold))
            .foregroundStyle(theme.primary)
        }
        .padding(theme.space16)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusXL)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
        .padding(.horizontal, theme.spacingMD)
    }

    private var colorSummaryCard: some View {
        VStack(alignment: .leading, spacing: theme.space16) {
            HStack(alignment: .top) {
                RoundedRectangle(cornerRadius: theme.radiusMD)
                    .fill(Color(hex: visualization.colorHex))
                    .frame(width: 56, height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radiusMD)
                            .stroke(theme.border, lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Selected Color")
                        .font(theme.micro)
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .foregroundStyle(theme.mutedForeground)
                    Text(visualization.colorName)
                        .font(theme.headline)
                        .foregroundStyle(theme.foreground)
                    Text("\(visualization.inferredBrand.displayName) / \(visualization.colorCode)")
                        .font(theme.caption)
                        .foregroundStyle(theme.mutedForeground)
                }

                Spacer()

                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: favoritesVM.isFavorite(paintColor) ? "heart.fill" : "heart")
                        .font(.system(size: 24))
                        .foregroundStyle(favoritesVM.isFavorite(paintColor) ? .red : theme.primary)
                        .frame(width: 44, height: 44)
                        .background(theme.primary.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(favoritesVM.isFavorite(paintColor) ? "Remove saved color" : "Save color")
            }

            Divider()

            VStack(alignment: .leading, spacing: theme.space8) {
                metaRow(icon: "square.split.diagonal", text: "Surface: \(visualization.surface)")
                metaRow(icon: "clock.arrow.circlepath", text: "Saved \(visualization.createdAt.formatted(date: .abbreviated, time: .shortened))")
                if let remoteID = visualization.remoteVisualizationID ?? visualization.shareID {
                    metaRow(icon: "link", text: "Preview ID \(remoteID)")
                }
            }

            HStack(spacing: theme.space12) {
                ActionTile(icon: favoritesVM.isFavorite(paintColor) ? "heart.slash.fill" : "heart.fill", label: favoritesVM.isFavorite(paintColor) ? "Remove Saved" : "Save Color") {
                    toggleFavorite()
                }
                ActionTile(icon: "doc.on.doc", label: "Copy Color") {
                    UIPasteboard.general.string = "\(visualization.colorName) (\(visualization.colorCode)) #\(visualization.colorHex)"
                    toastMessage = "Color copied"
                    showToast = true
                }
            }
        }
        .padding(theme.space16)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusXL)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
        .padding(.horizontal, theme.spacingMD)
    }

    private var editActions: some View {
        VStack(alignment: .leading, spacing: theme.space12) {
            Text("Adjust This Project")
                .font(theme.heading2)
                .foregroundStyle(theme.foreground)
                .padding(.horizontal, theme.spacingMD)

            HStack(spacing: theme.space12) {
                editCard(title: "Colors", body: "Swap or remove finalists", icon: "paintpalette") {
                    router.navigate(to: .itemPicker)
                }
                editCard(title: "Photo", body: "Update the room image", icon: "photo") {
                    router.navigate(to: .photoUpload)
                }
                editCard(title: "Surface", body: "Change what gets painted", icon: "square.split.diagonal") {
                    router.navigate(to: .surfacePicker)
                }
            }
            .padding(.horizontal, theme.spacingMD)
        }
    }

    private var expertBridgeCard: some View {
        Button {
            router.navigate(to: .sampleOutput(reportId: visualization.id, chapterId: nil))
        } label: {
            HStack(spacing: theme.space12) {
                Circle()
                    .fill(theme.primary.opacity(0.12))
                    .frame(width: 46, height: 46)
                    .overlay(
                        Image(systemName: "play.fill")
                            .foregroundStyle(theme.primary)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Want a pro to make the final call?")
                        .font(theme.heading3)
                        .foregroundStyle(theme.foreground)
                    Text("Preview Curt's walkthrough, then add expert guidance only if you want a lighting-aware recommendation on this shortlist.")
                        .font(theme.caption)
                        .foregroundStyle(theme.mutedForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.mutedForeground)
            }
            .padding(theme.space16)
            .background(theme.primary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radiusXL)
                    .stroke(theme.primary.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, theme.spacingMD)
        .accessibilityIdentifier("visualizationDetail.expertTake")
    }

    private func metaRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(theme.primary)
            Text(text)
                .font(theme.caption)
                .foregroundStyle(theme.mutedForeground)
                .lineLimit(2)
        }
    }

    private func editCard(title: String, body: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: theme.space8) {
                Circle()
                    .fill(theme.secondary)
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: icon)
                            .foregroundStyle(theme.primary)
                    )
                Text(title)
                    .font(theme.subhead)
                    .foregroundStyle(theme.foreground)
                Text(body)
                    .font(theme.captionSmall)
                    .foregroundStyle(theme.mutedForeground)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
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
        .sensoryFeedback(.selection, trigger: isActive)
    }

    private func toggleFavorite() {
        if favoritesVM.isFavorite(paintColor) {
            _ = favoritesVM.removeFavorite(paintColor)
            toastMessage = "Removed from favorites"
        } else {
            _ = favoritesVM.addFavorite(paintColor)
            toastMessage = "Saved to favorites"
        }
        showToast = true
    }

    private func openSavedPreview() {
        tabRouter.openSaved(
            appState: appState,
            section: .previews,
            route: .savedPreviewDetail(visualization: visualization)
        )
    }

    private func loadReferenceImages() async {
        didAttemptImageLoad = false
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
}

private struct ActionTile: View {
    @Environment(Theme.self) private var theme
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: theme.spacingSM) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(theme.primary)
                Text(label)
                    .font(theme.micro)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.foreground)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacingMD)
            .background(theme.muted)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radiusLG)
                    .stroke(theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(label)
    }
}
