import SwiftUI

/// Refined "Pick Colors" interface based on expert design critique
/// Implements best practices for iOS UI/UX design
/// Date: March 6, 2026

struct ItemPickerView_Refined: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @Environment(VisualizerViewModel.self) private var visualizerVM
    @State private var viewModel = ColorCatalogViewModel()
    @State private var showLimitToast = false
    @State private var searchText = ""
    
    // Create a bindable wrapper for the visualizer view model
    private var bindableVisualizerVM: Bindable<VisualizerViewModel> {
        Bindable(visualizerVM)
    }

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16) // Increased from 12pt
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) { // Consistent 24pt spacing (was variable)
                    
                    // IMPROVED: Simplified header with clear hierarchy
                    refinedHeader
                    
                    // IMPROVED: Prominent search bar (moved up)
                    refinedSearchBar
                    
                    // IMPROVED: iOS-style segmented control for brands
                    refinedBrandSelector
                    
                    // IMPROVED: Filter chips with clear actions
                    refinedFilterChips
                    
                    // IMPROVED: Proactive selection counter
                    selectionCounter
                    
                    // Color grid with improved cards
                    LazyVGrid(columns: columns, spacing: 16) { // Increased from 12pt
                        ForEach(viewModel.filteredColors) { color in
                            RefinedColorSwatchCard(
                                color: color,
                                isSelected: visualizerVM.isSelected(color)
                            ) {
                                handleColorSelection(color)
                            }
                        }
                    }
                    .padding(.horizontal, theme.spacingLG)
                    .padding(.bottom, 120) // Extra space for toolbar
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .sensoryFeedback(.error, trigger: showLimitToast)
            .toast(isPresented: $showLimitToast, message: "Maximum 5 colors. Deselect one to add another.", icon: "exclamationmark.triangle.fill")
            
            // IMPROVED: Native toolbar instead of floating bar
            if !visualizerVM.selectedColors.isEmpty {
                refinedSelectionToolbar
            }
        }
        .searchable(text: $searchText, prompt: "Search by color name or number")
        .navigationTitle("Pick Colors")
        .navigationBarTitleDisplayMode(.large) // iOS standard
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.navigate(to: .colorMatcher)
                } label: {
                    Label("Match", systemImage: "camera.fill")
                }
            }
        }
        .onAppear {
            viewModel.selectedBrand = visualizerVM.selectedBrand
        }
        .onChange(of: visualizerVM.selectedBrand) { _, newValue in
            viewModel.selectedBrand = newValue
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.searchText = newValue
        }
    }
    
    // MARK: - Refined Header
    
    private var refinedHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(theme.primary)
                
                Text("Crain Painting")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.foreground)
            }
            
            Text("Pick Your Colors")
                .font(.system(size: 28, weight: .bold)) // Increased from ~18pt
                .foregroundStyle(theme.foreground)
            
            Text("Select up to 5 paint colors to visualize")
                .font(.system(size: 15))
                .foregroundStyle(theme.mutedForeground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, theme.spacingLG)
        .padding(.top, 8)
    }
    
    // MARK: - Refined Search Bar
    
    private var refinedSearchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.mutedForeground)
            
            TextField("Search colors...", text: $searchText)
                .font(.system(size: 17)) // iOS standard body size
                .foregroundStyle(theme.foreground)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(theme.mutedForeground)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, theme.spacingLG)
    }
    
    // MARK: - Refined Brand Selector
    
    private var refinedBrandSelector: some View {
        Picker("Brand", selection: bindableVisualizerVM.selectedBrand) {
            ForEach(ColorCatalogViewModel.availableBrands, id: \.self) { brand in
                Text(brand.displayName)
                    .tag(brand)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, theme.spacingLG)
        .sensoryFeedback(.selection, trigger: visualizerVM.selectedBrand)
        .onChange(of: visualizerVM.selectedBrand) { _, newValue in
            viewModel.selectedBrand = newValue
        }
    }
    
    // MARK: - Refined Filter Chips
    
    private var refinedFilterChips: some View {
        HStack(spacing: 12) {
            ForEach(ColorCatalogViewModel.ColorFilter.allCases, id: \.self) { filter in
                if filter != .match { // Moved Match to toolbar
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        viewModel.selectedFilter = filter
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, theme.spacingLG)
    }
    
    // MARK: - Selection Counter
    
    private var selectionCounter: some View {
        HStack(spacing: 8) {
            Text("Colors Selected")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(theme.foreground)
            
            Spacer()
            
            Text("\(visualizerVM.selectedColors.count)/5")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(
                    visualizerVM.selectedColors.count >= 5 ? .red : theme.primary
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(visualizerVM.selectedColors.count >= 5 ? Color.red.opacity(0.1) : theme.primary.opacity(0.1))
                )
        }
        .padding(.horizontal, theme.spacingLG)
        .padding(.vertical, 8)
        .background(theme.muted)
        .opacity(visualizerVM.selectedColors.isEmpty ? 0 : 1)
        .animation(.easeInOut(duration: 0.2), value: visualizerVM.selectedColors.isEmpty)
    }
    
    // MARK: - Refined Selection Toolbar
    
    private var refinedSelectionToolbar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                // Color preview circles
                HStack(spacing: -8) {
                    ForEach(visualizerVM.selectedColors.prefix(5)) { color in
                        Circle()
                            .fill(color.color)
                            .frame(width: 32, height: 32) // Larger than before (was 28)
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: 2.5)
                            )
                            .overlay(
                                Circle()
                                    .stroke(theme.border, lineWidth: 1)
                            )
                    }
                }
                
                Text("\(visualizerVM.selectedColors.count) Selected")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.foreground)
                
                Spacer()
                
                // Next button
                Button {
                    router.navigate(to: .photoUpload)
                } label: {
                    HStack(spacing: 8) {
                        Text("Next Step")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "arrow.right")
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(theme.primary)
                    .clipShape(Capsule())
                }
                .sensoryFeedback(.success, trigger: visualizerVM.selectedColors.count)
            }
            .padding(.horizontal, theme.spacingLG)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
    }
    
    // MARK: - Actions
    
    private func handleColorSelection(_ color: PaintColor) {
        if visualizerVM.isSelected(color) {
            visualizerVM.toggleColor(color)
        } else if visualizerVM.canAddColor {
            visualizerVM.toggleColor(color)
        } else {
            showLimitToast = true
        }
    }
}

// MARK: - Filter Chip Component

private struct FilterChip: View {
    @Environment(Theme.self) private var theme
    
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : theme.foreground)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? theme.primary : Color.clear)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : theme.border, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Refined Color Swatch Card

private struct RefinedColorSwatchCard: View {
    @Environment(Theme.self) private var theme
    
    let color: PaintColor
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            action()
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Color preview area
                UnevenRoundedRectangle(
                    topLeadingRadius: theme.radiusLG,
                    topTrailingRadius: theme.radiusLG
                )
                .fill(color.color)
                .frame(height: 110) // Increased from 96pt
                .overlay(alignment: .center) {
                    // IMPROVED: Larger, centered checkmark with animation
                    if isSelected {
                        ZStack {
                            Circle()
                                .fill(theme.primary)
                                .frame(width: 44, height: 44) // Increased from 24
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 20, weight: .bold)) // Increased from 12
                                .foregroundStyle(.white)
                        }
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 2)
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                    }
                }
                
                // Info area with improved hierarchy
                VStack(alignment: .leading, spacing: 4) {
                    Text(color.name)
                        .font(.system(size: 16, weight: .semibold)) // Increased from 15pt
                        .foregroundStyle(theme.foreground)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Text(color.brand.displayName)
                            .font(.system(size: 13))
                            .foregroundStyle(theme.mutedForeground)
                        
                        Text("•")
                            .foregroundStyle(theme.mutedForeground)
                        
                        Text(color.number)
                            .font(.system(size: 13))
                            .foregroundStyle(theme.mutedForeground)
                    }
                }
                .padding(14) // Increased from 12pt
            }
            .background(theme.card)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radiusLG)
                    .stroke(
                        isSelected ? theme.primary : theme.border,
                        lineWidth: isSelected ? 3 : 1.5 // Increased from 2:1
                    )
            )
            .background(
                // Subtle selected background
                RoundedRectangle(cornerRadius: theme.radiusLG)
                    .fill(isSelected ? theme.primary.opacity(0.05) : Color.clear)
                    .padding(-4)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .sensoryFeedback(.selection, trigger: isSelected)
        
        // IMPROVED: Enhanced accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(color.name), \(color.brand.displayName), \(color.number)")
        .accessibilityHint(isSelected ? "Selected. Double tap to deselect." : "Double tap to select this color.")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("colorSwatch.\(color.id)")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ItemPickerView_Refined()
            .environment(Theme())
            .environment(RouterPath())
            .environment(VisualizerViewModel())
    }
}
