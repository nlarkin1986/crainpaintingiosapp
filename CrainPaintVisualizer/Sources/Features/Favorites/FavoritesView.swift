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
            VStack(spacing: 20) {
                // Search bar promoted to top position
                AppInput(
                    placeholder: "Search your favorites...", 
                    text: Bindable(viewModel).searchText, 
                    icon: "magnifyingglass"
                )
                .padding(.horizontal, theme.spacingMD)
                
                // Refined header with better hierarchy
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(viewModel.filteredFavorites.count) Colors")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(theme.foreground)
                        Text("Your curated collection")
                            .font(.system(size: 14))
                            .foregroundStyle(theme.mutedForeground)
                    }
                    Spacer()
                    HStack(spacing: 8) {
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
                        ForEach(Array(viewModel.filteredFavorites.enumerated()), id: \.element.id) { index, color in
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
                            .staggeredAppearance(index: index, delay: 0.04)
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
        VStack(spacing: 20) {
            // Larger, animated icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [theme.muted.opacity(0.5), theme.muted],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "heart")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(theme.mutedForeground)
            }
            .pulse(isActive: true)
            
            VStack(spacing: 10) {
                Text("Start Your Color Story")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(theme.foreground)
                
                Text("Save colors from the color matcher or visualizer to build your personal palette.")
                    .font(.system(size: 16))
                    .foregroundStyle(theme.mutedForeground)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Suggested actions
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.primary)
                    Text("Match colors from photos")
                        .font(.system(size: 15))
                        .foregroundStyle(theme.foreground)
                    Spacer()
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.primary)
                    Text("Browse paint catalogs")
                        .font(.system(size: 15))
                        .foregroundStyle(theme.foreground)
                    Spacer()
                }
            }
            .padding(16)
            .background(theme.muted.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
        .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
    }
}

private struct FavoriteColorCard: View {
    @Environment(Theme.self) private var theme
    let color: PaintColor
    let onTap: () -> Void
    let onUnfavorite: () -> Void
    
    @State private var isPressed = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                // Color swatch with better aspect ratio
                Rectangle()
                    .fill(color.color)
                    .aspectRatio(1.4, contentMode: .fill)
                    .overlay(
                        // Subtle gradient for depth
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Refined info section with better spacing
                VStack(alignment: .leading, spacing: 6) {
                    Text(color.brand.displayName)
                        .font(.system(size: 10, weight: .semibold))
                        .textCase(.uppercase)
                        .tracking(1)
                        .foregroundStyle(theme.mutedForeground)
                    
                    Text(color.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(theme.foreground)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                    
                    Text(color.number)
                        .font(.system(size: 12))
                        .foregroundStyle(theme.mutedForeground)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(theme.border, lineWidth: 1)
            )
            .shadow(color: color.color.opacity(0.25), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.97 : 1.0)

            // Refined favorite button
            Button(action: {
                onUnfavorite()
            }) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(.red)
                            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    )
            }
            .padding(10)
            .contentShape(Circle())
        }
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
                onTap()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(color.name), \(color.brand.displayName) \(color.number)")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to visualize this color")
    }
}

private struct BrandMenuChip: View {
    @Environment(Theme.self) private var theme
    let selectedBrand: PaintBrand?
    let onSelect: (PaintBrand?) -> Void

    var body: some View {
        Menu {
            Button("All Brands") { onSelect(nil) }
            Divider()
            ForEach(PaintBrand.allCases, id: \.self) { brand in
                Button(brand.displayName) { onSelect(brand) }
            }
        } label: {
            HStack(spacing: 6) {
                Text(selectedBrand?.displayName ?? "All Brands")
                    .font(.system(size: 14, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(theme.foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(theme.muted)
            .clipShape(Capsule())
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
                Button {
                    onSelect(option)
                } label: {
                    HStack {
                        Text(option.rawValue)
                        if option == selectedSort {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 11, weight: .semibold))
                Text(selectedSort.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(theme.foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(theme.muted)
            .clipShape(Capsule())
        }
    }
}
