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
            VStack(spacing: theme.spacingMD) {
                Text("Your curated collection of inspiration")
                    .font(theme.body)
                    .foregroundStyle(theme.mutedForeground)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, theme.spacingMD)

                AppInput(placeholder: "Search your favorites...", text: Bindable(viewModel).searchText, icon: "magnifyingglass")
                    .padding(.horizontal, theme.spacingMD)

                HStack {
                    Text("\(viewModel.filteredFavorites.count) Colors Saved")
                        .font(theme.caption)
                        .foregroundStyle(theme.mutedForeground)
                    Spacer()
                    HStack(spacing: theme.spacingSM) {
                        BrandMenuChip(selectedBrand: viewModel.selectedBrandFilter) { brand in
                            viewModel.selectedBrandFilter = brand
                        }
                        SortMenuChip(selectedSort: viewModel.sort) { sort in
                            viewModel.sort = sort
                        }
                    }
                }
                .padding(.horizontal, theme.spacingMD)

                if viewModel.filteredFavorites.isEmpty {
                    emptyState
                        .padding(.horizontal, theme.spacingMD)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.filteredFavorites) { color in
                            FavoriteColorCard(
                                color: color,
                                onTap: {
                                    visualizerVM.startFlow(with: color)
                                    tabRouter.openVisualizer(appState: appState, route: .itemPicker)
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
                                    tabRouter.openVisualizer(appState: appState, route: .itemPicker)
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
                    .padding(.horizontal, theme.spacingMD)
                    .padding(.bottom, theme.spacingLG)
                }
            }
            .padding(.top, theme.spacingSM)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Favorite Colors")
        .navigationBarTitleDisplayMode(.large)
        .sensoryFeedback(.success, trigger: showVisualizeToast)
        .toast(isPresented: $showVisualizeToast, message: "Opened in Visualize", icon: "paintbrush")
        .toast(isPresented: $showRemovedToast, message: "Color removed", icon: "trash")
    }

    private var emptyState: some View {
        VStack(spacing: theme.spacingSM) {
            Image(systemName: "heart.slash")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(theme.mutedForeground)
            Text("No favorites match your filters")
                .font(theme.subhead)
                .foregroundStyle(theme.foreground)
            Text("Save colors from the matcher, reports, or detail screens to build your palette.")
                .font(theme.caption)
                .foregroundStyle(theme.mutedForeground)
                .multilineTextAlignment(.center)
        }
        .padding(theme.spacingLG)
        .frame(maxWidth: .infinity)
        .background(theme.muted)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
    }
}

private struct FavoriteColorCard: View {
    @Environment(Theme.self) private var theme
    let color: PaintColor
    let onTap: () -> Void
    let onUnfavorite: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                Rectangle()
                    .fill(color.color)
                    .frame(height: 140)

                VStack(alignment: .leading, spacing: 2) {
                    Text(color.brand.displayName)
                        .font(theme.micro)
                        .textCase(.uppercase)
                        .tracking(0.8)
                        .foregroundStyle(theme.mutedForeground)
                    Text(color.name)
                        .font(theme.subhead)
                        .fontWeight(.bold)
                        .foregroundStyle(theme.foreground)
                        .lineLimit(1)
                    Text(color.number)
                        .font(theme.micro)
                        .foregroundStyle(theme.mutedForeground)
                }
                .padding(theme.spacingSM)
            }
            .background(theme.card)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radiusLG)
                    .stroke(theme.border, lineWidth: 1)
            )
            .shadow(color: color.color.opacity(0.3), radius: 6, y: 3)

            Button(action: onUnfavorite) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.red)
                    .frame(width: 44, height: 44)
                    .background(Color.cBackgroundElevated.opacity(0.92))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.05), radius: 2)
            }
            .padding(8)
        }
        .contentShape(RoundedRectangle(cornerRadius: theme.radiusLG))
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(color.name), \(color.brand.displayName) \(color.number)")
        .accessibilityAddTraits(.isButton)
    }
}

private struct BrandMenuChip: View {
    @Environment(Theme.self) private var theme
    let selectedBrand: PaintBrand?
    let onSelect: (PaintBrand?) -> Void

    var body: some View {
        Menu {
            Button("All Brands") { onSelect(nil) }
            ForEach(PaintBrand.allCases, id: \.self) { brand in
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
            .padding(.vertical, 6)
            .background(theme.muted)
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
            .padding(.vertical, 6)
            .background(theme.muted)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusMedium))
        }
    }
}
