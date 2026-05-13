import SwiftUI

struct ResultsGalleryView: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @Environment(VisualizerViewModel.self) private var visualizerVM

    private let galleryViewModel = GalleryViewModel()

    private var sections: [GalleryViewModel.RoomSection] {
        galleryViewModel.sections(using: visualizerVM)
    }

    private var isUsingLiveSelections: Bool {
        !visualizerVM.generatedVisualizations.isEmpty || visualizerVM.isShowingGenerationPlaceholders
    }

    private var featuredVisualization: Visualization? {
        sections.first?.visualizations.first
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: theme.spacingLG) {
                    headerView

                    if case .failed(let message) = visualizerVM.generationState {
                        errorCard(message)
                    }

                    if visualizerVM.generationState == .gated {
                        limitCard
                    }

                    if let featuredVisualization {
                        Button {
                            router.navigate(to: .visualizationDetail(visualization: featuredVisualization))
                        } label: {
                            HStack(spacing: theme.spacingSM) {
                                Circle()
                                    .fill(theme.primary.opacity(0.1))
                                    .frame(width: 42, height: 42)
                                    .overlay(
                                        Image(systemName: "sparkles")
                                            .foregroundStyle(theme.primary)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Review Your Featured Result")
                                        .font(theme.subhead)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(theme.foreground)
                                    Text("Open the strongest concept first, then request Curt's expert report.")
                                        .font(theme.caption)
                                        .foregroundStyle(theme.mutedForeground)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(theme.mutedForeground)
                            }
                            .padding(theme.spacingMD)
                            .background(theme.primary.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
                            .overlay(
                                RoundedRectangle(cornerRadius: theme.radiusLG)
                                    .stroke(theme.primary.opacity(0.18), lineWidth: 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, theme.spacingMD)
                        .accessibilityIdentifier("gallery.reviewFeatured")
                    }

                    ForEach(sections) { section in
                        VStack(alignment: .leading, spacing: theme.spacingMD) {
                            // Section header
                            HStack {
                                Image(systemName: section.icon)
                                    .font(.system(size: 20))
                                    .foregroundStyle(theme.primary)
                                Text(section.name)
                                    .font(theme.headline)
                                AppBadge(text: "\(section.visualizations.count)", isFilled: false)
                                Spacer()
                                Text("\(section.visualizations.count) items")
                                    .font(theme.caption)
                                    .foregroundStyle(theme.mutedForeground)
                            }
                            .padding(.horizontal, theme.spacingMD)

                            // Horizontal scroll of cards with snap
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: theme.spacingMD) {
                                    ForEach(section.visualizations) { viz in
                                        VisualizationCard(visualization: viz) {
                                            router.navigate(to: .visualizationDetail(visualization: viz))
                                        }
                                    }
                                }
                                .padding(.horizontal, theme.spacingMD)
                                .scrollTargetLayout()
                            }
                            .scrollTargetBehavior(.viewAligned)
                        }
                    }
                }
                .padding(.vertical, theme.spacingMD)
                .padding(.bottom, featuredVisualization == nil ? 0 : 88)
            }

            if let featuredVisualization {
                FloatingActionBar {
                    AppButton("Review Featured Result", variant: .cta, icon: "sparkles") {
                        router.navigate(to: .visualizationDetail(visualization: featuredVisualization))
                    }
                    .accessibilityIdentifier("gallery.reviewFeatured.primary")
                }
            }
        }
        .navigationTitle("Gallery")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await visualizerVM.generateVisualizationsIfNeeded()
        }
        .sheet(isPresented: Bindable(visualizerVM).showPaywall) {
            VisualizerPaywallView()
                .environment(theme)
                .environment(visualizerVM)
        }
    }

    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: theme.spacingSM) {
            switch visualizerVM.generationState {
            case .preparing:
                ProgressView()
                    .tint(theme.primary)
                Text("Preparing your room photo")
                    .font(theme.title)
                    .foregroundStyle(theme.foreground)
                Text("We are preserving the room layout, light, and texture before applying paint.")
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
                    .multilineTextAlignment(.center)
            case .generating(let current, let total, let colorName):
                ProgressView(value: Double(current - 1), total: Double(total))
                    .tint(theme.primary)
                    .padding(.horizontal, theme.spacingLG)
                Text("Generating \(colorName)")
                    .font(theme.title)
                    .foregroundStyle(theme.foreground)
                Text("AI render \(current) of \(total). Only completed renders count against your free uses.")
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
                    .multilineTextAlignment(.center)
            case .gated:
                Image(systemName: "lock.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(theme.primary)
                Text("Visualizer Pro required")
                    .font(theme.title)
                    .foregroundStyle(theme.foreground)
                Text("Your 5 free AI paint visualizations are complete.")
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
            case .failed:
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(ColorTokens.feedbackWarning)
                Text("Render paused")
                    .font(theme.title)
                    .foregroundStyle(theme.foreground)
                Text("Your free renders were not charged.")
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(theme.primary)
                Text("Your AI Visualizations Are Ready")
                    .font(theme.title)
                    .foregroundStyle(theme.foreground)
                Text("Compare the real generated result, save colors, and request expert guidance.")
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
                    .multilineTextAlignment(.center)
            case .idle:
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 32))
                    .foregroundStyle(theme.primary)
                Text("Visualization Gallery")
                    .font(theme.title)
                    .foregroundStyle(theme.foreground)
                Text(isUsingLiveSelections ? "Swipe through your latest room studies" : "Swipe through saved inspirations below")
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
            }

            if !visualizerVM.hasVisualizerEntitlement {
                Text("\(visualizerVM.remainingFreeRenders) free AI renders left")
                    .font(theme.micro)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.mutedForeground)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(theme.muted)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, theme.spacingMD)
        .padding(.vertical, theme.spacingMD)
    }

    private func errorCard(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: theme.spacingSM) {
            Text(message)
                .font(theme.subhead)
                .foregroundStyle(theme.foreground)
            AppButton("Retry Render", variant: .outline, icon: "arrow.clockwise") {
                Task { await visualizerVM.generateVisualizations() }
            }
        }
        .padding(theme.spacingMD)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
        .overlay(RoundedRectangle(cornerRadius: theme.radiusLG).stroke(theme.border, lineWidth: 1))
        .padding(.horizontal, theme.spacingMD)
    }

    private var limitCard: some View {
        VStack(alignment: .leading, spacing: theme.spacingSM) {
            Text("Free renders used")
                .font(theme.headline)
            Text("Browse colors and saved results freely. Upgrade only when you want more AI room renders.")
                .font(theme.caption)
                .foregroundStyle(theme.mutedForeground)
            AppButton("View Visualizer Pro", variant: .cta, icon: "sparkles") {
                visualizerVM.showPaywall = true
            }
        }
        .padding(theme.spacingMD)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
        .overlay(RoundedRectangle(cornerRadius: theme.radiusLG).stroke(theme.border, lineWidth: 1))
        .padding(.horizontal, theme.spacingMD)
    }
}

private struct VisualizationCard: View {
    @Environment(Theme.self) private var theme
    @Environment(VisualizerViewModel.self) private var visualizerVM
    let visualization: Visualization
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: theme.spacingSM) {
                // Image placeholder
                ZStack(alignment: .topTrailing) {
                    previewCard
                        .aspectRatio(3/4, contentMode: .fit)

                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(.black.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(12)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radiusLG)
                        .stroke(theme.border, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)

                // Color info card
                HStack(spacing: theme.spacingSM) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: visualization.colorHex))
                        .frame(width: 40, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(theme.border, lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(visualization.colorName)
                            .font(theme.subhead)
                            .fontWeight(.bold)
                            .lineLimit(1)
                        Text(visualization.colorCode)
                            .font(theme.micro)
                            .foregroundStyle(theme.mutedForeground)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(theme.spacingSM)
                .background(theme.card)
                .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radiusMD)
                        .stroke(theme.border, lineWidth: 1)
                )
            }
            .frame(width: UIScreen.main.bounds.width * 0.72)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityIdentifier("gallery.visualization.\(visualization.id)")
    }

    @ViewBuilder
    private var previewCard: some View {
        if let resultURL = visualization.resultImageURL {
            AsyncImage(url: resultURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    unavailablePreview
                default:
                    loadingPreview
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
        } else if visualization.hasReferenceImages {
            Image(visualization.afterImageName)
                .resizable()
                .scaledToFill()
                .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
        } else if let photo = visualizerVM.photo {
            Image(uiImage: photo)
                .resizable()
                .scaledToFit()
                .background(theme.muted.opacity(0.25))
                .overlay(Color(hex: visualization.colorHex).opacity(0.28))
                .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
        } else {
            RoundedRectangle(cornerRadius: theme.radiusLG)
                .fill(Color(hex: visualization.colorHex).opacity(0.3))
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .foregroundStyle(theme.mutedForeground.opacity(0.5))
                )
        }
    }

    private var loadingPreview: some View {
        ZStack {
            if let photo = visualizerVM.photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 1)
                    .overlay(Color.white.opacity(0.45))
            } else {
                theme.muted
            }
            ProgressView()
                .tint(theme.primary)
        }
    }

    private var unavailablePreview: some View {
        RoundedRectangle(cornerRadius: theme.radiusLG)
            .fill(theme.muted)
            .overlay(
                Label("Preview unavailable", systemImage: "wifi.exclamationmark")
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
            )
    }
}

struct VisualizerPaywallView: View {
    @Environment(Theme.self) private var theme
    @Environment(VisualizerViewModel.self) private var visualizerVM
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacingLG) {
                    VStack(alignment: .leading, spacing: theme.spacingSM) {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundStyle(theme.primary)
                        Text("Unlock unlimited AI paint visualizations")
                            .font(theme.heading1)
                            .foregroundStyle(theme.foreground)
                        Text("You used all 5 free completed renders. Keep browsing colors and saved results for free, or unlock more realistic AI room previews.")
                            .font(theme.body)
                            .foregroundStyle(theme.mutedForeground)
                    }

                    VStack(alignment: .leading, spacing: theme.spacingSM) {
                        benefit("Real AI repainting from your room photos")
                        benefit("Before/after comparison and share links")
                        benefit("No charge for failed or canceled renders")
                        benefit("Expert consultation remains optional and separate")
                    }
                    .padding(theme.spacingMD)
                    .background(theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
                    .overlay(RoundedRectangle(cornerRadius: theme.radiusLG).stroke(theme.border, lineWidth: 1))

                    VStack(spacing: theme.spacingSM) {
                        AppButton(
                            visualizerVM.isPurchasing
                                ? "Purchasing..."
                                : (visualizerVM.visualizerProductDisplayPrice.map { "Unlock Visualizer Pro - \($0)" } ?? "Unlock Visualizer Pro"),
                            variant: .cta,
                            icon: "lock.open",
                            isDisabled: visualizerVM.isPurchasing
                        ) {
                            Task { await visualizerVM.purchaseVisualizerUnlock() }
                        }

                        Button("Restore Purchase") {
                            Task { await visualizerVM.restorePurchases() }
                        }
                        .font(theme.subhead)
                        .foregroundStyle(theme.primary)

                        if let message = visualizerVM.purchaseMessage {
                            Text(message)
                                .font(theme.caption)
                                .foregroundStyle(theme.mutedForeground)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }

                    Text("Payment is handled by Apple In-App Purchase. Manage or cancel purchases in your Apple account settings. Privacy Policy and Terms are available from Crain Painting.")
                        .font(theme.micro)
                        .foregroundStyle(theme.mutedForeground)
                }
                .padding(theme.spacingLG)
            }
            .navigationTitle("Visualizer Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func benefit(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .font(theme.subhead)
            .foregroundStyle(theme.foreground)
            .labelStyle(.titleAndIcon)
    }
}
