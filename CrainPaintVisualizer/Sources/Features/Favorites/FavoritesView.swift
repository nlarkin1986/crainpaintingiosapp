import SwiftUI

struct FavoritesView: View {
    @Environment(Theme.self) private var theme
    @State private var viewModel = FavoritesViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacingMD) {
                // Header text
                VStack(alignment: .leading, spacing: 4) {
                    Text("Favorite Colors")
                        .font(theme.title)
                    Text("Your curated collection of inspiration")
                        .font(theme.caption)
                        .foregroundStyle(theme.mutedForeground)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, theme.spacingMD)

                // Search
                AppInput(placeholder: "Search your favorites...", text: $viewModel.searchText, icon: "magnifyingglass")
                    .padding(.horizontal, theme.spacingMD)

                // Results count + sort
                HStack {
                    Text("\(viewModel.filteredFavorites.count) Colors Saved")
                        .font(theme.caption)
                        .foregroundStyle(theme.mutedForeground)
                    Spacer()
                    HStack(spacing: theme.spacingSM) {
                        SortChip(label: "Brand", icon: "chevron.down")
                        SortChip(label: "Latest", icon: "arrow.up.arrow.down")
                    }
                }
                .padding(.horizontal, theme.spacingMD)

                // Color grid
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.filteredFavorites) { color in
                        FavoriteColorCard(color: color) {
                            viewModel.toggleFavorite(color)
                        }
                    }
                }
                .padding(.horizontal, theme.spacingMD)
                .padding(.bottom, theme.spacingLG)
            }
            .padding(.top, theme.spacingSM)
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct FavoriteColorCard: View {
    @Environment(Theme.self) private var theme
    let color: PaintColor
    let onUnfavorite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Color swatch
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(color.color)
                    .frame(height: 96)

                Button(action: onUnfavorite) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.red)
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.9))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.05), radius: 2)
                }
                .padding(8)
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(color.brand.displayName)
                    .font(.system(size: 10, weight: .bold))
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
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
        .contentShape(Rectangle())
    }
}

private struct SortChip: View {
    @Environment(Theme.self) private var theme
    let label: String
    let icon: String

    var body: some View {
        Button {} label: {
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                Image(systemName: icon)
                    .font(.system(size: 10))
            }
            .foregroundStyle(theme.foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(theme.muted)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
