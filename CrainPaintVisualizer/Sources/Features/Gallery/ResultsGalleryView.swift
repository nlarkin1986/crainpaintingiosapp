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
        !visualizerVM.selectedColors.isEmpty
    }

    private var featuredVisualization: Visualization? {
        sections.first?.visualizations.first
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: theme.spacingLG) {
                    // Congratulatory header
                    VStack(spacing: theme.spacingSM) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(theme.primary)
                        Text("Your Visualizations Are Ready!")
                            .font(theme.title)
                            .foregroundStyle(theme.foreground)
                        Text(isUsingLiveSelections ? "Swipe through your latest room studies" : "Swipe through saved inspirations below")
                            .font(theme.caption)
                            .foregroundStyle(theme.mutedForeground)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, theme.spacingMD)

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
        if visualization.hasReferenceImages {
            Image(visualization.afterImageName)
                .resizable()
                .scaledToFill()
                .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
        } else if let photo = visualizerVM.photo {
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
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
}
