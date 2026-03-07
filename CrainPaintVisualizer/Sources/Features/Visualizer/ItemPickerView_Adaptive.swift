import SwiftUI

/// Updated ItemPickerView that integrates with the new adaptive navigation system
/// 
/// Key changes from original:
/// 1. Removed redundant bottom toolbar (now handled by AdaptiveNavigationBar)
/// 2. Added NavigationState environment
/// 3. Updates visualization step on appear/changes
/// 4. Gains ~80pt of vertical space for content
struct ItemPickerView_Adaptive: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @Environment(VisualizerViewModel.self) private var visualizerVM
    @Environment(NavigationState.self) private var navState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var viewModel = ColorCatalogViewModel()
    @State private var showLimitToast = false

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Modern step header
            modernStepHeader
            
            ScrollView {
                VStack(spacing: 24) {
                    // Search bar
                    refinedSearchBar
                    
                    // Brand selector
                    refinedBrandSelector
                    
                    // Filter chips
                    refinedFilterChips
                    
                    // Selection counter (only show if colors selected)
                    selectionCounter
                    
                    // Empty state or color grid
                    if viewModel.filteredColors.isEmpty {
                        emptyStateView
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
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
                        // NOTE: Reduced bottom padding since tab bar is gone!
                        // Was: 120pt for tab bar + toolbar
                        // Now: 80pt for just the compact footer
                        .padding(.bottom, 80)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .sensoryFeedback(.error, trigger: showLimitToast)
            .toast(
                isPresented: $showLimitToast, 
                message: "Maximum 5 colors. Deselect one to add another.", 
                icon: "exclamationmark.triangle.fill"
            )
            
            // ✅ NO MORE BOTTOM TOOLBAR HERE!
            // AdaptiveNavigationBar handles it contextually
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
            }
        }
        .onAppear {
            viewModel.selectedBrand = visualizerVM.selectedBrand
            // Update navigation state to reflect current step
            navState.updateVisualizationStep(.colorPicking(selectedCount: visualizerVM.selectedColors.count))
        }
        .onChange(of: visualizerVM.selectedBrand) { _, newValue in
            viewModel.selectedBrand = newValue
        }
        // Update footer when selection changes
        .onChange(of: visualizerVM.selectedColors.count) { _, newCount in
            navState.updateVisualizationStep(.colorPicking(selectedCount: newCount))
        }
    }
    
    // MARK: - Helper Views
    
    private var modernStepHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: theme.spacingSM) {
                StepIndicator(number: 1, isActive: true, isComplete: false)
                Text("Pick Your Colors")
                    .font(theme.heading2)
                Spacer()
            }
            .padding(.horizontal, theme.spacingLG)
            .padding(.vertical, theme.spacingMD)
            
            Divider()
        }
    }
    
    private var refinedSearchBar: some View {
        HStack(spacing: theme.spacingSM) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.mutedForeground)
            
            TextField("Search colors...", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
            
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(theme.mutedForeground)
                }
            }
        }
        .padding(.horizontal, theme.spacingMD)
        .padding(.vertical, 12)
        .background(theme.muted)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))
        .padding(.horizontal, theme.spacingLG)
    }
    
    private var refinedBrandSelector: some View {
        Picker("Brand", selection: $viewModel.selectedBrand) {
            ForEach(PaintBrand.allCases) { brand in
                Text(brand.displayName).tag(brand)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, theme.spacingLG)
    }
    
    private var refinedFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacingSM) {
                ForEach(ColorCatalogViewModel.ColorFilter.allCases, id: \.rawValue) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: viewModel.selectedFilter == filter,
                        action: {
                            viewModel.selectedFilter = viewModel.selectedFilter == filter ? .all : filter
                        }
                    )
                }
            }
            .padding(.horizontal, theme.spacingLG)
        }
    }
    
    private var selectionCounter: some View {
        Group {
            if !visualizerVM.selectedColors.isEmpty {
                HStack {
                    HStack(spacing: -8) {
                        ForEach(visualizerVM.selectedColors.prefix(5)) { color in
                            Circle()
                                .fill(color.color)
                                .frame(width: 24, height: 24)
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                        }
                    }
                    Text("\(visualizerVM.selectedColors.count) of 5 selected")
                        .font(theme.caption)
                        .foregroundStyle(theme.mutedForeground)
                    Spacer()
                }
                .padding(.horizontal, theme.spacingLG)
            }
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "No colors found",
            systemImage: "paintpalette",
            description: Text("Try adjusting your search or filters")
        )
        .padding(.top, 60)
    }
    
    // MARK: - Helper Methods
    
    private func handleColorSelection(_ color: PaintColor) {
        if visualizerVM.isSelected(color) {
            visualizerVM.toggleColor(color)
        } else {
            if visualizerVM.selectedColors.count >= 5 {
                showLimitToast = true
            } else {
                visualizerVM.addColor(color)
            }
        }
    }
}

// MARK: - Migration Guide Comment Block
/*
 
 MIGRATION GUIDE: Converting Your Views to Adaptive Navigation
 ==============================================================
 
 Step 1: Add NavigationState Environment
 ----------------------------------------
 @Environment(NavigationState.self) private var navState
 
 
 Step 2: Remove Bottom Toolbars
 -------------------------------
 Delete any custom bottom navigation UI from your view.
 AdaptiveNavigationBar will handle it automatically.
 
 Before:
 ```
 var body: some View {
     VStack {
         // Content
         if !selectedItems.isEmpty {
             MyCustomBottomBar()  // ❌ Remove this
         }
     }
 }
 ```
 
 After:
 ```
 var body: some View {
     VStack {
         // Content
         // ✅ That's it! AdaptiveNavigationBar shows appropriate footer
     }
 }
 ```
 
 
 Step 3: Update Navigation State on Changes
 -------------------------------------------
 Call navState.updateVisualizationStep() when your view's state changes.
 
 ```
 .onChange(of: selectedColors.count) { _, newCount in
     navState.updateVisualizationStep(.colorPicking(selectedCount: newCount))
 }
 ```
 
 
 Step 4: Set Initial State on Appear
 ------------------------------------
 ```
 .onAppear {
     navState.updateVisualizationStep(.colorPicking(selectedCount: selectedColors.count))
 }
 ```
 
 
 Step 5: Adjust Bottom Padding
 ------------------------------
 Reduce bottom padding since tab bar is gone.
 
 Before: .padding(.bottom, 120)  // 80pt tab bar + 40pt buffer
 After:  .padding(.bottom, 80)   // 52pt footer + 28pt buffer
 
 
 Step 6: Test Navigation Flow
 -----------------------------
 - Verify footer appears/disappears correctly
 - Check smooth transitions between steps
 - Ensure back button behavior is correct
 
 
 EXAMPLE: Full Before/After
 ===========================
 
 BEFORE:
 -------
 struct MyView: View {
     @Environment(RouterPath.self) private var router
     @State private var items: [Item] = []
     
     var body: some View {
         VStack {
             ScrollView {
                 // Content
             }
             
             if !items.isEmpty {
                 MyCustomFooter {
                     Button("Continue") {
                         router.navigate(to: .next)
                     }
                 }
             }
         }
     }
 }
 
 AFTER:
 ------
 struct MyView: View {
     @Environment(RouterPath.self) private var router
     @Environment(NavigationState.self) private var navState  // ✅ Add
     @State private var items: [Item] = []
     
     var body: some View {
         VStack {
             ScrollView {
                 // Content
             }
             // ✅ Remove custom footer - AdaptiveNavigationBar handles it
         }
         .onAppear {
             navState.updateVisualizationStep(.myStep)  // ✅ Set state
         }
         .onChange(of: items.count) { _, count in
             navState.updateVisualizationStep(.myStep(count: count))  // ✅ Update
         }
     }
 }
 
 */

// MARK: - Side-by-Side Comparison

/*
 
 SPACE COMPARISON
 ================
 
 OLD DESIGN:
 ┌─────────────────────────┐
 │ Nav Bar         44pt    │
 ├─────────────────────────┤
 │                         │
 │                         │
 │   Content Area          │
 │                         │  ~600pt
 │                         │
 ├─────────────────────────┤
 │ Custom Footer   76pt    │
 ├─────────────────────────┤
 │ Tab Bar         80pt    │
 └─────────────────────────┘
   Navigation UI: 156pt (20.6% of screen)
   Content: 600pt (79.4%)
 
 
 NEW DESIGN:
 ┌─────────────────────────┐
 │ Nav Bar         44pt    │
 ├─────────────────────────┤
 │                         │
 │                         │
 │                         │
 │   Content Area          │  ~704pt
 │                         │
 │                         │
 ├─────────────────────────┤
 │ Adaptive Footer 52pt    │
 └─────────────────────────┘
   Navigation UI: 52pt (6.9% of screen)
   Content: 704pt (93.1%)
 
 RESULT: +104pt content space (17.3% more!)
 
 */

// MARK: - Supporting Views

private struct StepIndicator: View {
    @Environment(Theme.self) private var theme
    let number: Int
    let isActive: Bool
    let isComplete: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isActive ? theme.actionPrimary : theme.muted)
                .frame(width: 32, height: 32)

            if isComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isActive ? .white : theme.mutedForeground)
            }
        }
    }
}

private struct FilterChip: View {
    @Environment(Theme.self) private var theme
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(theme.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? theme.actionPrimaryText : theme.foreground)
                .padding(.horizontal, theme.spacingMD)
                .padding(.vertical, 8)
                .background(isSelected ? theme.actionPrimary : theme.muted)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct RefinedColorSwatchCard: View {
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

#Preview("Color Picking - Empty") {
    NavigationStack {
        ItemPickerView_Adaptive()
    }
    .environment(Theme())
    .environment(RouterPath())
    .environment(VisualizerViewModel())
    .environment(NavigationState())
}

#Preview("Color Picking - With Selection") {
    @Previewable @State var vm = VisualizerViewModel()
    
    NavigationStack {
        ItemPickerView_Adaptive()
    }
    .environment(Theme())
    .environment(RouterPath())
    .environment(vm)
    .environment(NavigationState())
    .onAppear {
        // Add some mock colors for preview
        // vm.selectedColors = [mockColor1, mockColor2, mockColor3]
    }
}
