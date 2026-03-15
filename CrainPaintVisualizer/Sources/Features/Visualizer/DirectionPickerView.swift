import SwiftUI

struct DirectionPickerView: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @Environment(VisualizerViewModel.self) private var visualizerVM
    @Environment(FavoritesViewModel.self) private var favoritesVM

    @State private var suggestionCatalog = ColorCatalogViewModel()
    @State private var browseCatalog = ColorCatalogViewModel()
    @State private var isShowingBrandSheet = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: theme.space24) {
                    WizardHeader(
                        steps: ["Color", "Photo", "Surface"],
                        currentStep: 1,
                        helper: "Build a focused shortlist before you render the room."
                    )

                    header

                    if !visualizerVM.selectedColors.isEmpty {
                        selectedDirectionsSection
                    }

                    suggestedDirectionsSection

                    savedColorsSection

                    browseBrandSection
                }
                .padding(.horizontal, theme.spacingMD)
                .padding(.top, theme.space20)
                .padding(.bottom, 140)
            }

            FloatingActionBar {
                AppButton(primaryButtonTitle, variant: .cta, icon: primaryButtonIcon, isDisabled: visualizerVM.selectedColors.isEmpty) {
                    router.navigate(to: primaryContinueRoute)
                }
                .accessibilityIdentifier("directionPicker.continue")
            }
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle("Pick Colors")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadCatalogs()
        }
        .onChange(of: visualizerVM.selectedBrand, initial: true) { _, brand in
            suggestionCatalog.selectedBrand = brand
            browseCatalog.selectedBrand = brand
            Task(priority: .utility) {
                await SharedColorCatalogStore.shared.prewarm(brand: brand)
            }
        }
        .sheet(isPresented: $isShowingBrandSheet) {
            BrandBrowseSheet(
                theme: theme,
                browseCatalog: browseCatalog,
                onSelectBrand: { brand in
                    visualizerVM.setSelectedBrand(brand)
                },
                onSelectColor: { color in
                    selectColor(color)
                    isShowingBrandSheet = false
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: theme.space12) {
            Text("Colors")
                .font(theme.captionSmall)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .tracking(1.2)
                .foregroundStyle(theme.textTertiary)

            Text("Pick a tight set of colors before you render.")
                .font(theme.displayMedium)
                .foregroundStyle(theme.foreground)

            Text("Start with suggested colors, pull from your saved favorites, or browse by brand. You can keep up to five options in the batch.")
                .font(theme.bodyDefault)
                .foregroundStyle(theme.mutedForeground)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var selectedDirectionsSection: some View {
        VStack(alignment: .leading, spacing: theme.space12) {
            Text("Current shortlist")
                .font(theme.heading3)
                .foregroundStyle(theme.foreground)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.space12) {
                    ForEach(visualizerVM.selectedColors) { color in
                        SelectedDirectionCard(color: color) {
                            visualizerVM.toggleColor(color)
                        }
                    }
                }
            }
        }
    }

    private var suggestedDirectionsSection: some View {
        VStack(alignment: .leading, spacing: theme.space12) {
            sectionTitle(
                title: "Suggested colors",
                detail: visualizerVM.selectedBrand.displayName
            )

            if suggestionCatalog.filteredColors.isEmpty && suggestionCatalog.isLoading {
                loadingPanel(message: "Loading popular colors…")
            } else {
                LazyVGrid(columns: directionColumns, spacing: theme.space12) {
                    ForEach(Array(suggestionCatalog.filteredColors.prefix(8))) { color in
                        DirectionColorCard(
                            color: color,
                            subtitle: color.number,
                            isSelected: visualizerVM.isSelected(color),
                            canSelect: visualizerVM.isSelected(color) || visualizerVM.canAddColor
                        ) {
                            selectColor(color)
                        }
                    }
                }
            }
        }
    }

    private var savedColorsSection: some View {
        VStack(alignment: .leading, spacing: theme.space12) {
            sectionTitle(title: "Saved colors", detail: "Favorites")

            if favoritesVM.favorites.isEmpty {
                emptyPanel(
                    title: "No saved colors yet",
                    detail: "Use the matcher or preview screens to build a reusable shortlist."
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: theme.space12) {
                        ForEach(Array(favoritesVM.favorites.prefix(8))) { color in
                            DirectionColorCard(
                                color: color,
                                subtitle: color.brand.displayName,
                                isSelected: visualizerVM.isSelected(color),
                                canSelect: visualizerVM.isSelected(color) || visualizerVM.canAddColor
                            ) {
                                selectColor(color)
                            }
                            .frame(width: 184)
                        }
                    }
                }
            }
        }
    }

    private var browseBrandSection: some View {
        VStack(alignment: .leading, spacing: theme.space12) {
            sectionTitle(title: "Browse brand catalog", detail: "Sheet")

            Button {
                browseCatalog.selectedBrand = visualizerVM.selectedBrand
                browseCatalog.selectedFilter = .popular
                browseCatalog.searchText = ""
                isShowingBrandSheet = true
            } label: {
                HStack(spacing: theme.space16) {
                    RoundedRectangle(cornerRadius: theme.radiusMD)
                        .fill(theme.primary.opacity(0.12))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: "paintpalette")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(theme.primary)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Browse \(visualizerVM.selectedBrand.displayName)")
                            .font(theme.heading3)
                            .foregroundStyle(theme.foreground)
                        Text("Search the catalog, switch brands, and add colors without leaving this step.")
                            .font(theme.bodySmall)
                            .foregroundStyle(theme.mutedForeground)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.textTertiary)
                }
                .padding(theme.space16)
                .background(theme.card)
                .clipShape(RoundedRectangle(cornerRadius: theme.radiusLarge))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radiusLarge)
                        .stroke(theme.borderSubtle, lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    private func sectionTitle(title: String, detail: String) -> some View {
        HStack {
            Text(title)
                .font(theme.heading3)
                .foregroundStyle(theme.foreground)
            Spacer(minLength: 0)
            Text(detail)
                .font(theme.captionSmall)
                .foregroundStyle(theme.textTertiary)
        }
    }

    private func loadingPanel(message: String) -> some View {
        HStack(spacing: theme.space12) {
            ProgressView()
            Text(message)
                .font(theme.bodySmall)
                .foregroundStyle(theme.mutedForeground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.space16)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusLarge)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
    }

    private func emptyPanel(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: theme.space8) {
            Text(title)
                .font(theme.heading3)
                .foregroundStyle(theme.foreground)
            Text(detail)
                .font(theme.bodySmall)
                .foregroundStyle(theme.mutedForeground)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.space16)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusLarge)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
    }

    private func selectColor(_ color: PaintColor) {
        if visualizerVM.isSelected(color) {
            visualizerVM.toggleColor(color)
            return
        }

        visualizerVM.setSelectedBrand(color.brand)
        _ = visualizerVM.addColor(color)
    }

    private func loadCatalogs() async {
        suggestionCatalog.selectedBrand = visualizerVM.selectedBrand
        suggestionCatalog.selectedFilter = .popular
        browseCatalog.selectedBrand = visualizerVM.selectedBrand
        browseCatalog.selectedFilter = .popular
        await SharedColorCatalogStore.shared.prewarm(brand: visualizerVM.selectedBrand)
    }

    private var directionColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: theme.space12),
            GridItem(.flexible(), spacing: theme.space12),
        ]
    }

    private var primaryContinueRoute: AppRoute {
        if !visualizerVM.hasPhoto {
            return .photoUpload
        }
        if !visualizerVM.isSurfaceSelectionValid {
            return .surfacePicker
        }
        return .projectReview
    }

    private var primaryButtonTitle: String {
        if !visualizerVM.hasPhoto {
            return "Add room photo"
        }
        if !visualizerVM.isSurfaceSelectionValid {
            return "Choose surface"
        }
        return "Review project"
    }

    private var primaryButtonIcon: String {
        if !visualizerVM.hasPhoto {
            return "photo.badge.plus"
        }
        if !visualizerVM.isSurfaceSelectionValid {
            return "square.on.square.badge.person.crop"
        }
        return "arrow.right.circle.fill"
    }
}

private struct DirectionColorCard: View {
    @Environment(Theme.self) private var theme

    let color: PaintColor
    let subtitle: String
    let isSelected: Bool
    let canSelect: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: theme.space12) {
                RoundedRectangle(cornerRadius: theme.radiusLarge)
                    .fill(color.color)
                    .frame(height: 112)
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(isSelected ? .white : theme.foreground.opacity(canSelect ? 0.9 : 0.35))
                            .padding(10)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(color.name)
                        .font(theme.heading3)
                        .foregroundStyle(theme.foreground)
                        .lineLimit(2)
                    Text(subtitle)
                        .font(theme.captionSmall)
                        .foregroundStyle(theme.mutedForeground)
                        .lineLimit(1)
                }
            }
            .padding(theme.space12)
            .background(isSelected ? theme.primary.opacity(0.08) : theme.card)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radiusXL)
                    .stroke(isSelected ? theme.primary : theme.borderSubtle, lineWidth: isSelected ? 2 : 1)
            )
            .opacity(canSelect ? 1 : 0.55)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!canSelect)
        .accessibilityIdentifier("colorSwatch.\(color.id)")
    }
}

private struct SelectedDirectionCard: View {
    @Environment(Theme.self) private var theme

    let color: PaintColor
    let remove: () -> Void

    var body: some View {
        HStack(spacing: theme.space12) {
            RoundedRectangle(cornerRadius: theme.radiusMD)
                .fill(color.color)
                .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text(color.name)
                    .font(theme.heading3)
                    .foregroundStyle(theme.foreground)
                    .lineLimit(1)
                Text(color.number)
                    .font(theme.captionSmall)
                    .foregroundStyle(theme.mutedForeground)
            }

            Button(action: remove) {
                Label("Remove \(color.name)", systemImage: "xmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 18))
                    .foregroundStyle(theme.textTertiary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(color.name)")
        }
        .padding(theme.space12)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusXL)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
    }
}

private struct BrandBrowseSheet: View {
    let theme: Theme
    @Bindable var browseCatalog: ColorCatalogViewModel
    let onSelectBrand: (PaintBrand) -> Void
    let onSelectColor: (PaintColor) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: theme.space20) {
                    AppInput(
                        placeholder: "Search color name or number",
                        text: $browseCatalog.searchText,
                        icon: "magnifyingglass"
                    )

                    brandChips

                    LazyVStack(spacing: theme.space12) {
                        ForEach(Array(browseCatalog.filteredColors.prefix(24))) { color in
                            Button {
                                onSelectColor(color)
                            } label: {
                                HStack(spacing: theme.space12) {
                                    RoundedRectangle(cornerRadius: theme.radiusMD)
                                        .fill(color.color)
                                        .frame(width: 52, height: 52)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(color.name)
                                            .font(theme.heading3)
                                            .foregroundStyle(theme.foreground)
                                        Text("\(color.number) • \(color.family)")
                                            .font(theme.captionSmall)
                                            .foregroundStyle(theme.mutedForeground)
                                    }

                                    Spacer(minLength: 0)

                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(theme.primary)
                                }
                                .padding(theme.space12)
                                .background(theme.card)
                                .clipShape(RoundedRectangle(cornerRadius: theme.radiusLarge))
                                .overlay(
                                    RoundedRectangle(cornerRadius: theme.radiusLarge)
                                        .stroke(theme.borderSubtle, lineWidth: 1)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, theme.spacingMD)
                .padding(.top, theme.space20)
                .padding(.bottom, theme.space32)
            }
            .background(theme.background.ignoresSafeArea())
            .navigationTitle("Browse by Brand")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var brandChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.space8) {
                ForEach(PaintBrand.supportedCases, id: \.self) { brand in
                    Button {
                        browseCatalog.selectedBrand = brand
                        browseCatalog.selectedFilter = .popular
                        onSelectBrand(brand)
                    } label: {
                        Text(brand.displayName)
                            .font(theme.captionSmall)
                            .fontWeight(.semibold)
                            .foregroundStyle(browseCatalog.selectedBrand == brand ? theme.actionPrimaryText : theme.foreground)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(browseCatalog.selectedBrand == brand ? theme.actionPrimary : theme.card)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(browseCatalog.selectedBrand == brand ? theme.actionPrimary : theme.borderSubtle, lineWidth: 1)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }
}
