import SwiftUI

struct ItemPickerView: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @State private var viewModel = ColorCatalogViewModel()
    @State private var visualizerVM = VisualizerViewModel()

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: theme.spacingMD) {
                    StepProgressView(steps: ["Color", "Photo", "Surface"], currentStep: 0)

                    // Brand toggle
                    Picker("Brand", selection: $viewModel.selectedBrand) {
                        Text("Benjamin Moore").tag(PaintBrand.benjaminMoore)
                        Text("Sherwin-Williams").tag(PaintBrand.sherwinWilliams)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, theme.spacingMD)

                    // Filter tabs
                    HStack(spacing: theme.spacingSM) {
                        ForEach(ColorCatalogViewModel.ColorFilter.allCases, id: \.self) { filter in
                            Button {
                                viewModel.selectedFilter = filter
                            } label: {
                                HStack(spacing: 4) {
                                    if filter == .match {
                                        Image(systemName: "camera")
                                            .font(.system(size: 12))
                                    }
                                    Text(filter.rawValue)
                                        .font(theme.subhead)
                                }
                                .padding(.horizontal, theme.spacingSM)
                                .padding(.vertical, theme.spacingXS)
                                .background(viewModel.selectedFilter == filter ? theme.primary : .clear)
                                .foregroundStyle(viewModel.selectedFilter == filter ? .white : theme.mutedForeground)
                                .clipShape(Capsule())
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, theme.spacingMD)

                    // Search bar
                    AppInput(placeholder: "Search colors...", text: $viewModel.searchText, icon: "magnifyingglass")
                        .padding(.horizontal, theme.spacingMD)

                    // Results counter
                    Text("Showing \(viewModel.filteredColors.count) results")
                        .font(theme.caption)
                        .foregroundStyle(theme.mutedForeground)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, theme.spacingMD)

                    // Color grid
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.filteredColors) { color in
                            ColorSwatchCard(
                                color: color,
                                isSelected: visualizerVM.isSelected(color)
                            ) {
                                visualizerVM.toggleColor(color)
                            }
                        }
                    }
                    .padding(.horizontal, theme.spacingMD)
                    .padding(.bottom, 100) // Space for floating bar
                }
            }

            // Floating action bar
            if !visualizerVM.selectedColors.isEmpty {
                FloatingActionBar {
                    HStack {
                        HStack(spacing: -8) {
                            ForEach(visualizerVM.selectedColors) { color in
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 28, height: 28)
                                    .overlay(Circle().stroke(.white, lineWidth: 2))
                            }
                        }
                        Text("\(visualizerVM.selectedColors.count) Selected")
                            .font(theme.subhead)
                            .foregroundStyle(theme.foreground)
                        Spacer()
                        AppButton("Next Step", variant: .primary, icon: "arrow.right") {
                            router.navigate(to: .photoUpload)
                        }
                        .frame(width: 140)
                    }
                }
            }
        }
        .navigationTitle("Pick Colors")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ColorSwatchCard: View {
    @Environment(Theme.self) private var theme
    let color: PaintColor
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                Rectangle()
                    .fill(color.color)
                    .frame(height: 64)
                    .overlay(alignment: .topTrailing) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.white)
                                .font(.system(size: 18))
                                .padding(6)
                        }
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(color.name)
                        .font(theme.subhead)
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.foreground)
                        .lineLimit(1)
                    Text(color.number)
                        .font(theme.caption)
                        .foregroundStyle(theme.mutedForeground)
                }
                .padding(theme.spacingSM)
            }
            .background(theme.card)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radiusMD)
                    .stroke(isSelected ? theme.primary : theme.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityLabel("\(color.name), \(color.brand.displayName) \(color.number)")
    }
}
