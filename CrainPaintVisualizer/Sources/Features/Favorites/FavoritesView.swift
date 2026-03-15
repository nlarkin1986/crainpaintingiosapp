import SwiftUI

struct FavoritesView: View {
    @Environment(Theme.self) private var theme
    @Environment(AppState.self) private var appState
    @Environment(TabRouter.self) private var tabRouter
    @Environment(VisualizerViewModel.self) private var visualizerVM
    @Environment(FavoritesViewModel.self) private var viewModel

    @State private var showVisualizeToast = false
    @State private var showRemovedToast = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: theme.space24) {
                header

                searchPanel

                if viewModel.filteredFavorites.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.filteredFavorites) { color in
                            FavoriteColorCard(
                                color: color,
                                onTap: {
                                    visualizerVM.startFlow(with: color)
                                    tabRouter.openVisualizer(appState: appState, route: .photoUpload)
                                    showVisualizeToast = true
                                },
                                onUnfavorite: {
                                    _ = viewModel.removeFavorite(color)
                                    showRemovedToast = true
                                }
                            )
                            .contextMenu {
                                Button {
                                    visualizerVM.startFlow(with: color)
                                    tabRouter.openVisualizer(appState: appState, route: .photoUpload)
                                    showVisualizeToast = true
                                } label: {
                                    Label("Visualize", systemImage: "wand.and.stars")
                                }
                                Button {
                                    UIPasteboard.general.string = "#\(color.hex)"
                                } label: {
                                    Label("Copy Hex", systemImage: "doc.on.clipboard")
                                }
                                Button(role: .destructive) {
                                    _ = viewModel.removeFavorite(color)
                                    showRemovedToast = true
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, theme.spacingMD)
            .padding(.top, theme.space16)
            .padding(.bottom, theme.spacingXL)
        }
        .background(theme.background.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.success, trigger: showVisualizeToast)
        .toast(isPresented: $showVisualizeToast, message: "Opened in Visualize", icon: "paintbrush")
        .toast(isPresented: $showRemovedToast, message: "Color removed", icon: "trash")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: theme.space12) {
            Text("Favorite Colors")
                .font(theme.displayMedium)
                .foregroundStyle(theme.foreground)

            Text("Your curated collection of inspiration, organized for quick comparison and one-tap visualization.")
                .font(theme.bodyDefault)
                .foregroundStyle(theme.mutedForeground)

            HStack(spacing: theme.space8) {
                statPill(
                    icon: "heart.fill",
                    text: "\(viewModel.filteredFavorites.count) Colors Saved",
                    foreground: theme.primary,
                    background: theme.primary.opacity(0.12)
                )

                if let selectedBrand = viewModel.selectedBrandFilter {
                    statPill(
                        icon: "paintpalette.fill",
                        text: selectedBrand.displayName,
                        foreground: theme.foreground,
                        background: theme.secondary
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var searchPanel: some View {
        VStack(alignment: .leading, spacing: theme.space16) {
            AppInput(
                placeholder: "Search your favorites...",
                text: Bindable(viewModel).searchText,
                icon: "magnifyingglass"
            )

            HStack(alignment: .center) {
                Text(viewModel.filteredFavorites.isEmpty ? "No matching colors" : "Quick filters")
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)

                Spacer()

                HStack(spacing: theme.space8) {
                    BrandMenuChip(selectedBrand: viewModel.selectedBrandFilter) { brand in
                        viewModel.selectedBrandFilter = brand
                    }
                    SortMenuChip(selectedSort: viewModel.sort) { sort in
                        viewModel.sort = sort
                    }
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
        .shadow(color: .black.opacity(0.05), radius: 16, y: 6)
    }

    private var emptyState: some View {
        VStack(spacing: theme.space16) {
            Circle()
                .fill(theme.primary.opacity(0.08))
                .frame(width: 72, height: 72)
                .overlay(
                    Image(systemName: "heart.slash")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(theme.primary)
                )

            VStack(spacing: theme.space8) {
                Text("No favorites match your filters")
                    .font(theme.heading2)
                    .foregroundStyle(theme.foreground)
                Text("Save colors from the matcher, reports, or detail screens to build a palette you can compare in seconds.")
                    .font(theme.bodySmall)
                    .foregroundStyle(theme.mutedForeground)
                    .multilineTextAlignment(.center)
            }

            AppButton("Start Visualizing", variant: .outline, icon: "wand.and.stars") {
                tabRouter.openVisualizer(appState: appState, route: .photoUpload)
            }
        }
        .padding(theme.space24)
        .frame(maxWidth: .infinity)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusXL)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
    }

    private func statPill(icon: String, text: String, foreground: Color, background: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(theme.captionSmall)
                .fontWeight(.semibold)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(background)
        .clipShape(Capsule())
    }
}

private struct FavoriteColorCard: View {
    @Environment(Theme.self) private var theme
    let color: PaintColor
    let onTap: () -> Void
    let onUnfavorite: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 0) {
                    RoundedRectangle(cornerRadius: theme.radiusLG)
                        .fill(color.color)
                        .frame(height: 150)
                        .overlay(alignment: .bottomLeading) {
                            Text(color.family.uppercased())
                                .font(theme.micro)
                                .fontWeight(.bold)
                                .tracking(1)
                                .foregroundStyle(.white.opacity(0.92))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.black.opacity(0.18))
                                .clipShape(Capsule())
                                .padding(12)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(color.brand.displayName.uppercased())
                            .font(theme.micro)
                            .tracking(0.9)
                            .foregroundStyle(theme.mutedForeground)
                        Text(color.name)
                            .font(theme.heading3)
                            .foregroundStyle(theme.foreground)
                            .lineLimit(2)
                        Text(color.number)
                            .font(theme.caption)
                            .foregroundStyle(theme.mutedForeground)
                    }
                    .padding(theme.space12)
                }
                .background(theme.card)
                .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radiusXL)
                        .stroke(theme.borderSubtle, lineWidth: 1)
                )
                .shadow(color: color.color.opacity(0.22), radius: 14, y: 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(color.name), \(color.brand.displayName) \(color.number)")

            Button(action: onUnfavorite) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.red)
                    .frame(width: 44, height: 44)
                    .background(Color.cBackgroundElevated.opacity(0.96))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
            }
            .padding(10)
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(color.name) from favorites")
        }
    }
}

private struct BrandMenuChip: View {
    @Environment(Theme.self) private var theme
    let selectedBrand: PaintBrand?
    let onSelect: (PaintBrand?) -> Void

    var body: some View {
        Menu {
            Button("All Brands") { onSelect(nil) }
            ForEach(PaintBrand.supportedCases, id: \.self) { brand in
                Button(brand.displayName) { onSelect(brand) }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedBrand?.displayName ?? "Brand")
                    .font(theme.caption)
                Image(systemName: "chevron.down")
                    .font(theme.micro)
            }
            .foregroundStyle(theme.foreground)
            .padding(.horizontal, theme.space12)
            .padding(.vertical, 8)
            .background(theme.secondary)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusMedium))
        }
    }
}

private struct SortMenuChip: View {
    @Environment(Theme.self) private var theme
    let selectedSort: FavoritesViewModel.FavoriteSort
    let onSelect: (FavoritesViewModel.FavoriteSort) -> Void

    var body: some View {
        Menu {
            ForEach(FavoritesViewModel.FavoriteSort.allCases, id: \.self) { option in
                Button(option.rawValue) { onSelect(option) }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedSort.rawValue)
                    .font(theme.caption)
                Image(systemName: "arrow.up.arrow.down")
                    .font(theme.micro)
            }
            .foregroundStyle(theme.foreground)
            .padding(.horizontal, theme.space12)
            .padding(.vertical, 8)
            .background(theme.secondary)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusMedium))
        }
    }
}
