import SwiftUI

struct VisualizationDetailView: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @Environment(FavoritesViewModel.self) private var favoritesVM
    @Environment(ReportsViewModel.self) private var reportsVM
    @Environment(VisualizerViewModel.self) private var visualizerVM
    let visualizationId: String

    @State private var showBeforeAfter = true
    @State private var showToast = false
    @State private var toastMessage = "Saved to favorites"
    @State private var showFullscreen = false

    private let galleryViewModel = GalleryViewModel()

    private var visualization: Visualization? {
        galleryViewModel.visualization(for: visualizationId, using: visualizerVM)
    }

    var body: some View {
        Group {
            if let visualization {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: theme.spacingMD) {
                            HStack(spacing: 0) {
                                toggleButton("After Only", isActive: !showBeforeAfter) { showBeforeAfter = false }
                                toggleButton("Before & After", isActive: showBeforeAfter) { showBeforeAfter = true }
                            }
                            .padding(4)
                            .background(theme.muted)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))
                            .padding(.horizontal, theme.spacingMD)

                            if showBeforeAfter {
                                ComparisonSliderView(
                                    beforeImage: beforeImage(for: visualization),
                                    afterImage: afterImage(for: visualization)
                                )
                                .aspectRatio(3/4, contentMode: .fit)
                                .padding(.horizontal, theme.spacingMD)
                                .onTapGesture { showFullscreen = true }
                            } else {
                                afterOnlyPreview(for: visualization)
                                    .padding(.horizontal, theme.spacingMD)
                                    .onTapGesture { showFullscreen = true }
                            }

                            VStack(spacing: theme.spacingMD) {
                                HStack(alignment: .top) {
                                    RoundedRectangle(cornerRadius: theme.radiusMD)
                                        .fill(Color(hex: visualization.colorHex))
                                        .frame(width: 56, height: 56)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: theme.radiusMD)
                                                .stroke(theme.border, lineWidth: 1)
                                        )

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Selected Color")
                                            .font(theme.micro)
                                            .textCase(.uppercase)
                                            .tracking(0.5)
                                            .foregroundStyle(theme.mutedForeground)
                                        Text(visualization.colorName)
                                            .font(theme.headline)
                                        Text("\(visualization.inferredBrand.displayName) \u{00B7} \(visualization.colorCode)")
                                            .font(theme.caption)
                                            .foregroundStyle(theme.mutedForeground)
                                    }

                                    Spacer()

                                    Button {
                                        saveColor(visualization.asPaintColor)
                                    } label: {
                                        Image(systemName: favoritesVM.isFavorite(visualization.asPaintColor) ? "heart.fill" : "heart")
                                            .font(.system(size: 24))
                                            .foregroundStyle(favoritesVM.isFavorite(visualization.asPaintColor) ? .red : theme.primary)
                                            .frame(width: 44, height: 44)
                                            .background(theme.primary.opacity(0.1))
                                            .clipShape(Circle())
                                    }
                                }

                                Divider()

                                HStack {
                                    Label("Target: \(visualization.surface)", systemImage: "square.split.diagonal")
                                        .font(theme.caption)
                                        .foregroundStyle(theme.mutedForeground)
                                    Spacer()
                                    Label(previewLightingLabel(for: visualization), systemImage: "sun.max")
                                        .font(theme.caption)
                                        .foregroundStyle(theme.mutedForeground)
                                }
                            }
                            .padding(20)
                            .background(theme.card)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
                            .overlay(
                                RoundedRectangle(cornerRadius: theme.radiusLG)
                                    .stroke(theme.border, lineWidth: 1)
                            )
                            .padding(.horizontal, theme.spacingMD)

                            HStack(spacing: theme.spacingSM) {
                                ActionTile(icon: "heart.fill", label: "Save Color") {
                                    saveColor(visualization.asPaintColor)
                                }
                                ActionTile(icon: "doc.on.doc", label: "Copy Color") {
                                    UIPasteboard.general.string = "\(visualization.colorName) (\(visualization.colorCode)) #\(visualization.colorHex)"
                                    toastMessage = "Color copied"
                                    showToast = true
                                }
                            }
                            .padding(.horizontal, theme.spacingMD)

                            Button {
                                let report = reportsVM.createReport(from: visualization)
                                router.navigate(to: .masterReport(reportId: report.id))
                            } label: {
                                HStack(spacing: theme.spacingSM) {
                                    Circle()
                                        .fill(theme.primary.opacity(0.1))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Image(systemName: "person.crop.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundStyle(theme.primary)
                                        )
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("What Would Curt Say?")
                                            .font(theme.subhead)
                                            .fontWeight(.bold)
                                            .foregroundStyle(theme.foreground)
                                        Text("Get Curt's take on \(visualization.colorName) — From $49")
                                            .font(theme.caption)
                                            .foregroundStyle(theme.mutedForeground)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundStyle(theme.mutedForeground)
                                }
                                .padding(theme.spacingMD)
                                .background(theme.primary.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
                                .overlay(
                                    RoundedRectangle(cornerRadius: theme.radiusLG)
                                        .stroke(theme.primary.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .padding(.horizontal, theme.spacingMD)
                            .padding(.bottom, theme.spacingLG)
                        }
                    }

                    FloatingActionBar {
                        AppButton("Get Curt's Expert Take — From $49", variant: .cta, icon: "person.crop.circle") {
                            let report = reportsVM.createReport(from: visualization)
                            router.navigate(to: .masterReport(reportId: report.id))
                        }
                        .accessibilityIdentifier("visualizationDetail.expertTake")
                    }
                }
            } else {
                ContentUnavailableView("Visualization unavailable", systemImage: "photo.on.rectangle.angled")
            }
        }
        .navigationTitle(visualization?.roomName ?? "Visualization")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.success, trigger: showToast)
        .toast(isPresented: $showToast, message: toastMessage, icon: "checkmark.circle.fill")
        .fullScreenCover(isPresented: $showFullscreen) {
            if let visualization {
                FullscreenImageViewer(
                    image: afterImage(for: visualization),
                    colorName: visualization.colorName
                )
            }
        }
    }
}

extension VisualizationDetailView {
    func toggleButton(_ label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(theme.subhead)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(isActive ? .white : theme.mutedForeground)
                .background(isActive ? theme.primary : .clear)
                .clipShape(RoundedRectangle(cornerRadius: theme.radiusSM))
        }
        .sensoryFeedback(.selection, trigger: isActive)
    }

    private func saveColor(_ color: PaintColor) {
        let added = favoritesVM.addFavorite(color)
        toastMessage = added ? "Saved to favorites" : "Already in favorites"
        showToast = true
    }

    private func previewLightingLabel(for visualization: Visualization) -> String {
        visualization.hasReferenceImages ? "Lighting: Afternoon Sun" : "Lighting: Photo sample"
    }

    private func beforeImage(for visualization: Visualization) -> Image {
        if let photo = visualizerVM.photo {
            return Image(uiImage: photo)
        }
        if !visualization.beforeImageName.isEmpty {
            return Image(visualization.beforeImageName)
        }
        return Image(systemName: "photo")
    }

    private func afterImage(for visualization: Visualization) -> Image {
        if let photo = visualizerVM.photo {
            return Image(uiImage: tintedPreviewImage(from: photo, hex: visualization.colorHex))
        }
        if !visualization.afterImageName.isEmpty {
            return Image(visualization.afterImageName)
        }
        return Image(systemName: "photo.fill")
    }

    private func afterOnlyPreview(for visualization: Visualization) -> some View {
        Group {
            if let photo = visualizerVM.photo {
                Image(uiImage: tintedPreviewImage(from: photo, hex: visualization.colorHex))
                    .resizable()
                    .scaledToFill()
            } else if !visualization.afterImageName.isEmpty {
                Image(visualization.afterImageName)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: theme.radiusXL)
                    .fill(Color(hex: visualization.colorHex).opacity(0.3))
                    .overlay(
                        Image(systemName: "photo.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(theme.mutedForeground.opacity(0.5))
                    )
            }
        }
        .aspectRatio(3/4, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
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

private struct FullscreenImageViewer: View {
    @Environment(\.dismiss) private var dismiss
    let image: Image
    let colorName: String

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            image
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnifyGesture()
                        .onChanged { value in
                            scale = lastScale * value.magnification
                        }
                        .onEnded { value in
                            lastScale = max(scale, 1.0)
                            scale = max(scale, 1.0)
                            if scale == 1.0 {
                                offset = .zero
                                lastOffset = .zero
                            }
                        }
                        .simultaneously(with:
                            DragGesture()
                                .onChanged { value in
                                    guard scale > 1.0 else { return }
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                )
                .onTapGesture(count: 2) {
                    withAnimation(.spring(duration: 0.3)) {
                        if scale > 1.0 {
                            scale = 1.0
                            lastScale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        } else {
                            scale = 3.0
                            lastScale = 3.0
                        }
                    }
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
            .accessibilityLabel("Close fullscreen preview")
            .accessibilityHint("Dismiss the full screen visualization")
        }
        .statusBarHidden()
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
