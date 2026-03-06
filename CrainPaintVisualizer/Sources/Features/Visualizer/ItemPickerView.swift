import SwiftUI

struct ItemPickerView: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @Environment(VisualizerViewModel.self) private var visualizerVM
    @State private var viewModel = ColorCatalogViewModel()
    @State private var showLimitToast = false

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: theme.spacingMD) {
                    BrandedHeader(title: "Pick Colors")

                    StepProgressView(steps: ["Color", "Photo", "Surface"], currentStep: 0, icons: ["paintpalette", "camera", "sofa"])

                    // Brand toggle — custom rounded
                    HStack(spacing: 0) {
                        ForEach(ColorCatalogViewModel.availableBrands, id: \.self) { brand in
                            Button {
                                visualizerVM.selectedBrand = brand
                                viewModel.selectedBrand = brand
                            } label: {
                                Text(brand.displayName)
                                    .font(theme.subhead)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .foregroundStyle(visualizerVM.selectedBrand == brand ? .white : theme.mutedForeground)
                                    .background(visualizerVM.selectedBrand == brand ? theme.primary : .clear)
                                    .clipShape(RoundedRectangle(cornerRadius: theme.radiusSM))
                            }
                            .sensoryFeedback(.selection, trigger: visualizerVM.selectedBrand)
                        }
                    }
                    .padding(4)
                    .background(theme.muted)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))
                    .padding(.horizontal, theme.spacingLG)

                    // Underline-style filter tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: theme.spacingLG) {
                            ForEach(ColorCatalogViewModel.ColorFilter.allCases, id: \.self) { filter in
                                Button {
                                    if filter == .match {
                                        router.navigate(to: .colorMatcher)
                                    } else {
                                        viewModel.selectedFilter = filter
                                    }
                                } label: {
                                    VStack(spacing: 6) {
                                        HStack(spacing: 4) {
                                            if filter == .match {
                                                Image(systemName: "camera")
                                                    .font(.system(size: 12))
                                            }
                                            Text(filter.rawValue)
                                                .font(theme.subhead)
                                        }
                                        .foregroundStyle(viewModel.selectedFilter == filter && filter != .match ? theme.primary : theme.mutedForeground)

                                        Rectangle()
                                            .fill(viewModel.selectedFilter == filter && filter != .match ? theme.primary : .clear)
                                            .frame(height: 2)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, theme.spacingLG)
                    }

                    // Search bar
                    AppInput(placeholder: "Search colors...", text: $viewModel.searchText, icon: "magnifyingglass")
                        .padding(.horizontal, theme.spacingLG)

                    // Results counter
                    Text("Showing \(viewModel.filteredColors.count) results")
                        .font(theme.caption)
                        .foregroundStyle(theme.mutedForeground)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, theme.spacingLG)

                    // Color grid
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.filteredColors) { color in
                            ColorSwatchCard(
                                color: color,
                                isSelected: visualizerVM.isSelected(color)
                            ) {
                                if visualizerVM.isSelected(color) || visualizerVM.canAddColor {
                                    visualizerVM.toggleColor(color)
                                } else {
                                    showLimitToast = true
                                }
                            }
                        }
                    }
                    .padding(.horizontal, theme.spacingLG)
                    .padding(.bottom, 100)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .sensoryFeedback(.error, trigger: showLimitToast)
            .toast(isPresented: $showLimitToast, message: "Maximum 5 colors. Deselect one to add another.", icon: "exclamationmark.triangle")

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
                        AppButton("Next Step", variant: .cta, icon: "arrow.right") {
                            router.navigate(to: .photoUpload)
                        }
                        .frame(width: 160)
                        .accessibilityIdentifier("itemPicker.nextStep")
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.selectedBrand = visualizerVM.selectedBrand
        }
        .onChange(of: visualizerVM.selectedBrand) { _, newValue in
            viewModel.selectedBrand = newValue
        }
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
                UnevenRoundedRectangle(topLeadingRadius: theme.radiusLG, topTrailingRadius: theme.radiusLG)
                    .fill(color.color)
                    .frame(height: 96)
                    .overlay(alignment: .topTrailing) {
                        if isSelected {
                            ZStack {
                                Circle()
                                    .fill(theme.actionPrimary)
                                    .frame(width: 24, height: 24)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(theme.actionPrimaryText)
                            }
                            .padding(6)
                        }
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(color.brand.displayName.uppercased())
                        .font(theme.micro)
                        .tracking(0.5)
                        .foregroundStyle(theme.mutedForeground)
                    Text(color.name)
                        .font(theme.subhead)
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.foreground)
                        .lineLimit(1)
                    Text(color.number)
                        .font(theme.caption)
                        .foregroundStyle(theme.mutedForeground)
                }
                .padding(12)
            }
            .background(theme.card)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radiusLG)
                    .stroke(isSelected ? theme.primary : theme.border, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: color.color.opacity(0.3), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .sensoryFeedback(.selection, trigger: isSelected)
        .accessibilityLabel("\(color.name), \(color.brand.displayName) \(color.number)")
        .accessibilityIdentifier("colorSwatch.\(color.id)")
    }
}
