import SwiftUI

/// **Apple Design Award-Level Color Picker**
/// Complete redesign with delightful animations and celebrations
/// Date: March 6, 2026

struct ItemPickerViewModern: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @Environment(VisualizerViewModel.self) private var visualizerVM
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel = ColorCatalogViewModel()
    @State private var showLimitToast = false
    @State private var showCelebration = false
    @State private var previousColorCount = 0

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
    ]

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // ✅ NEW: Clean, spacious step header
                modernStepHeader
                
                ScrollView {
                    VStack(spacing: 24) {
                        // ✅ Prominent search
                        refinedSearchBar
                        
                        // ✅ Native segmented control
                        refinedBrandSelector
                        
                        // ✅ Filter chips
                        refinedFilterChips
                        
                        // ✅ Proactive counter
                        selectionCounter
                        
                        // Grid or empty state
                        if viewModel.filteredColors.isEmpty {
                            emptyStateView
                        } else {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(Array(viewModel.filteredColors.enumerated()), id: \.element.id) { index, color in
                                    RefinedColorSwatchCard(
                                        color: color,
                                        isSelected: visualizerVM.isSelected(color)
                                    ) {
                                        handleColorSelection(color)
                                    }
                                    .staggeredAppearance(index: index, delay: 0.03)
                                }
                            }
                            .padding(.horizontal, theme.spacingLG)
                            .padding(.bottom, 120)
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .sensoryFeedback(.error, trigger: showLimitToast)
                .sensoryFeedback(.success, trigger: showCelebration)
                .toast(isPresented: $showLimitToast, message: "Maximum 5 colors. Deselect one to add another.", icon: "exclamationmark.triangle.fill")
                
                // ✅ Native toolbar
                if !visualizerVM.selectedColors.isEmpty {
                    refinedSelectionToolbar
                }
            }
            
            // 🎉 Celebration overlay when 5 colors selected
            if showCelebration {
                celebrationOverlay
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.navigate(to: .colorMatcher)
                } label: {
                    Label("Match", systemImage: "camera.fill")
                }
                .buttonStyle(EnhancedButtonStyle())
            }
        }
        .onAppear {
            viewModel.selectedBrand = visualizerVM.selectedBrand
            previousColorCount = visualizerVM.selectedColors.count
        }
        .onChange(of: visualizerVM.selectedBrand) { _, newValue in
            viewModel.selectedBrand = newValue
        }
        .onChange(of: visualizerVM.selectedColors.count) { oldCount, newCount in
            // Celebrate when reaching exactly 5 colors
            if newCount == 5 && oldCount == 4 {
                triggerCelebration()
            }
            previousColorCount = newCount
        }
    }
    
    // MARK: - Modern Step Header
    
    private var modernStepHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                stepIndicator(title: "Colors", icon: "paintpalette.fill", step: 0, current: 0)
                connector(isActive: false)
                stepIndicator(title: "Photo", icon: "photo.fill", step: 1, current: 0)
                connector(isActive: false)
                stepIndicator(title: "Surface", icon: "sofa.fill", step: 2, current: 0)
            }
            .padding(.horizontal, theme.spacingLG)
            .padding(.vertical, 20)
            
            Divider()
        }
        .background(.ultraThinMaterial)
    }
    
    private func stepIndicator(title: String, icon: String, step: Int, current: Int) -> some View {
        let isActive = step == current
        let isComplete = step < current
        
        return VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(isActive ? theme.primary : isComplete ? theme.stepComplete : theme.muted)
                    .frame(width: 48, height: 48)
                
                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isActive ? .white : theme.mutedForeground)
                }
            }
            
            Text(title)
                .font(.system(size: 14, weight: isActive ? .semibold : .medium))
                .foregroundStyle(isActive ? theme.primary : theme.mutedForeground)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func connector(isActive: Bool) -> some View {
        Rectangle()
            .fill(isActive ? theme.primary : theme.border)
            .frame(height: 2)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 30)
    }
    
    // MARK: - Search Bar
    
    private var refinedSearchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.mutedForeground)
                .font(.system(size: 17))
            
            TextField("Search by color name or number", text: $viewModel.searchText)
                .font(.system(size: 17))
                .foregroundStyle(theme.foreground)
                .autocorrectionDisabled()
            
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(theme.mutedForeground)
                        .font(.system(size: 17))
                }
                .buttonStyle(.plain)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, theme.spacingLG)
    }
    
    // MARK: - Brand Selector
    
    private var refinedBrandSelector: some View {
        Picker(
            "Paint brand",
            selection: Binding(
                get: { visualizerVM.selectedBrand },
                set: { newValue in
                    visualizerVM.selectedBrand = newValue
                    viewModel.selectedBrand = newValue
                }
            )
        ) {
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
    
    // MARK: - Filter Chips
    
    private var refinedFilterChips: some View {
        HStack(spacing: 12) {
            ForEach(ColorCatalogViewModel.ColorFilter.allCases, id: \.self) { filter in
                if filter != .match {
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
                        .fill(visualizerVM.selectedColors.count >= 5
                              ? Color.red.opacity(0.1)
                              : theme.primary.opacity(0.1))
                )
        }
        .padding(.horizontal, theme.spacingLG)
        .padding(.vertical, 8)
        .background(theme.muted)
        .opacity(visualizerVM.selectedColors.isEmpty ? 0 : 1)
        .animation(.easeInOut(duration: 0.2), value: visualizerVM.selectedColors.isEmpty)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Colors selected")
        .accessibilityValue("\(visualizerVM.selectedColors.count) of 5 colors selected")
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(theme.mutedForeground)
            
            Text("No colors found")
                .font(.title3.weight(.semibold))
                .foregroundStyle(theme.foreground)
            
            Text("Try adjusting your search or filters")
                .font(.body)
                .foregroundStyle(theme.mutedForeground)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Toolbar
    
    private var refinedSelectionToolbar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                HStack(spacing: -8) {
                    ForEach(visualizerVM.selectedColors.prefix(5)) { color in
                        Circle()
                            .fill(color.color)
                            .frame(width: 32, height: 32)
                            .overlay(Circle().stroke(.white, lineWidth: 2.5))
                            .overlay(Circle().stroke(theme.border, lineWidth: 1))
                    }
                }
                
                Text("\(visualizerVM.selectedColors.count) Selected")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.foreground)
                
                Spacer()
                
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
                .accessibilityIdentifier("itemPicker.nextStep")
            }
            .padding(.horizontal, theme.spacingLG)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
        .opacity(visualizerVM.selectedColors.isEmpty ? 0 : 1)
        .animation(.easeInOut(duration: 0.2), value: visualizerVM.selectedColors.isEmpty)
    }
    
    // MARK: - Celebration Overlay
    
    private var celebrationOverlay: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissCelebration()
                }
            
            // Confetti
            ConfettiView()
                .ignoresSafeArea()
            
            // Message card
            VStack(spacing: 20) {
                // Animated checkmark
                ZStack {
                    Circle()
                        .fill(ColorTokens.feedbackSuccess)
                        .frame(width: 80, height: 80)
                        .shadow(color: ColorTokens.feedbackSuccess.opacity(0.3), radius: 16, y: 8)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                }
                .bounce(trigger: showCelebration ? 1 : 0)
                
                VStack(spacing: 8) {
                    Text("Perfect Palette!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(theme.foreground)
                    
                    Text("You've selected 5 beautiful colors.\nReady to see them come to life?")
                        .font(.system(size: 17))
                        .foregroundStyle(theme.mutedForeground)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
                // CTA Button
                Button {
                    dismissCelebration()
                    router.navigate(to: .photoUpload)
                } label: {
                    HStack(spacing: 8) {
                        Text("Continue to Photo")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "arrow.right")
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [ColorTokens.aqua, ColorTokens.aquaDark],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: ColorTokens.aqua.opacity(0.4), radius: 12, y: 6)
                }
                .buttonStyle(EnhancedButtonStyle())
                
                // Dismiss button
                Button("Keep Exploring") {
                    dismissCelebration()
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(theme.mutedForeground)
            }
            .padding(32)
            .background(theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.2), radius: 24, y: 12)
            .padding(.horizontal, 24)
        }
    }
    
    private func triggerCelebration() {
        guard !reduceMotion else { return }
        showCelebration = true
        
        // Auto-dismiss after 5 seconds if user doesn't interact
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if showCelebration {
                dismissCelebration()
            }
        }
    }
    
    private func dismissCelebration() {
        withAnimation(.springDefault) {
            showCelebration = false
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
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .sensoryFeedback(.selection, trigger: isSelected)
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to filter by \(title.lowercased())")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Refined Color Swatch Card with Enhanced Animations

private struct RefinedColorSwatchCard: View {
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    let color: PaintColor
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var showRipple = false
    
    var body: some View {
        Button(action: {
            // Trigger ripple effect
            if !isSelected && !reduceMotion {
                showRipple = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showRipple = false
                }
            }
            
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: isSelected ? .light : .medium)
            generator.impactOccurred()
            
            // Perform action
            action()
        }) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    // Color swatch
                    UnevenRoundedRectangle(
                        topLeadingRadius: theme.radiusLG,
                        topTrailingRadius: theme.radiusLG
                    )
                    .fill(color.color)
                    .frame(height: 110)
                    
                    // Ripple effect overlay
                    if showRipple {
                        RippleEffect(color: .white)
                            .frame(height: 110)
                            .clipShape(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: theme.radiusLG,
                                    topTrailingRadius: theme.radiusLG
                                )
                            )
                    }
                    
                    // Selection indicator
                    if isSelected {
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 48, height: 48)
                                .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
                            
                            Circle()
                                .fill(theme.primary)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                        .bounce(trigger: isSelected ? 1 : 0)
                    }
                }
                
                // Info section
                VStack(alignment: .leading, spacing: 4) {
                    Text(color.name)
                        .font(.system(size: 16, weight: .semibold))
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
                .padding(14)
            }
            .background(theme.card)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radiusLG)
                    .stroke(
                        isSelected ? theme.primary : theme.border,
                        lineWidth: isSelected ? 3 : 1.5
                    )
                    .animation(.springFast, value: isSelected)
            )
            .background(
                RoundedRectangle(cornerRadius: theme.radiusLG)
                    .fill(isSelected ? theme.primary.opacity(0.05) : Color.clear)
                    .padding(-4)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .shadow(
                color: color.color.opacity(isSelected ? 0.3 : 0.15),
                radius: isSelected ? 12 : 6,
                y: isSelected ? 6 : 3
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in 
                    withAnimation(.springFast) {
                        isPressed = true
                    }
                }
                .onEnded { _ in 
                    withAnimation(.springFast) {
                        isPressed = false
                    }
                }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(color.name), \(color.brand.displayName), \(color.number)")
        .accessibilityHint(isSelected ? "Selected. Double tap to deselect." : "Double tap to select this color.")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("colorSwatch.\(color.id)")
    }
}

// MARK: - Preview

#Preview("Pick Colors - Modern") {
    NavigationStack {
        ItemPickerViewModern()
            .environment(Theme())
            .environment(RouterPath())
            .environment(VisualizerViewModel())
    }
}
