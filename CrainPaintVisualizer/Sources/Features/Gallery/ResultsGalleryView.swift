import SwiftUI

struct ResultsGalleryView: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @State private var viewModel = GalleryViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacingLG) {
                ForEach(viewModel.sections) { section in
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
                            Button("View All") {}
                                .font(theme.subhead)
                                .fontWeight(.semibold)
                                .foregroundStyle(theme.primary)
                        }
                        .padding(.horizontal, theme.spacingMD)

                        // Horizontal scroll of cards
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: theme.spacingMD) {
                                ForEach(section.visualizations) { viz in
                                    VisualizationCard(visualization: viz) {
                                        router.navigate(to: .visualizationDetail(id: viz.id))
                                    }
                                }
                            }
                            .padding(.horizontal, theme.spacingMD)
                        }
                    }
                }
            }
            .padding(.vertical, theme.spacingMD)
        }
        .navigationTitle("Gallery")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {} label: {
                    Image(systemName: "folder.badge.plus")
                        .foregroundStyle(theme.primary)
                }
                Button {} label: {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
    }
}

private struct VisualizationCard: View {
    @Environment(Theme.self) private var theme
    let visualization: Visualization
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: theme.spacingSM) {
                // Image placeholder
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: theme.radiusXL)
                        .fill(Color(hex: visualization.colorHex).opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 32))
                                .foregroundStyle(theme.mutedForeground.opacity(0.5))
                        )
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
                    RoundedRectangle(cornerRadius: theme.radiusXL)
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
            .frame(width: 240)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
