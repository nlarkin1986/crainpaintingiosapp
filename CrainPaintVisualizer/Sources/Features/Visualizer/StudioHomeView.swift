import SwiftUI

/// Studio Home View - The landing page for paint visualization creation
/// Renamed from BrandSelectorView to match new "Studio" tab naming
struct StudioHomeView: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @Environment(VisualizerViewModel.self) private var visualizerVM
    @Environment(NavigationState.self) private var navState

    @State private var showComingSoonToast = false
    @State private var showRecentVisualizations = false

    private let brands: [(PaintBrand?, String, String, String, Color)] = [
        (.benjaminMoore, "Benjamin Moore", "Premium quality since 1883", "paintbrush", Color(hex: "2E5090")),
        (.sherwinWilliams, "Sherwin-Williams", "Color for every vision", "globe", Color(hex: "E31837")),
        (.behr, "Behr", "Reliable color solutions", "paintpalette.fill", Color(hex: "FF6F00")),
        (nil, "Other Brand", "Coming soon", "chevron.right", Color(hex: "64748B")),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacingLG) {
                    
                    // ✅ Updated header for "Studio" concept
                    BrandedHeader(
                        title: "Your Studio",
                        subtitle: "Choose your preferred paint brand to start creating visualizations."
                    )
                    
                    // Show recent visualizations if available (future enhancement)
                    if showRecentVisualizations {
                        recentVisualizationsSection
                    }
                    
                    // Brand selection cards
                    VStack(spacing: theme.spacingSM) {
                        ForEach(Array(brands.enumerated()), id: \.offset) { index, brand in
                            BrandCard(
                                name: brand.1,
                                tagline: brand.2,
                                icon: brand.3,
                                accentColor: brand.4,
                                isSelected: visualizerVM.selectedBrand == brand.0,
                                isDashed: brand.0 == nil
                            ) {
                                if let paintBrand = brand.0 {
                                    visualizerVM.selectedBrand = paintBrand
                                } else {
                                    showComingSoonToast = true
                                }
                            }
                        }
                    }
                    .padding(.horizontal, theme.spacingLG)
                }
                .padding(.bottom, 100) // Space for footer
            }
            
            // ✅ Note: With AdaptiveNavigationBar, this would be removed
            // Keeping for backward compatibility
            FloatingActionBar {
                AppButton(
                    "Create Visualization",  // ✅ Clear action verb!
                    variant: .cta, 
                    icon: "wand.and.stars"
                ) {
                    // Enter focused mode
                    navState.beginVisualization()
                    router.navigate(to: .itemPicker)
                }
                .accessibilityIdentifier("studio.createVisualization")
                .accessibilityHint("Start creating a new paint color visualization")
            }
        }
        .navigationTitle("Studio")  // ✅ Updated from "Select Brand"
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: visualizerVM.selectedBrand)
        .toast(
            isPresented: $showComingSoonToast, 
            message: "Custom brands coming soon!", 
            icon: "clock"
        )
        .onAppear {
            navState.updateVisualizationStep(.brandSelection)
        }
    }
    
    // MARK: - Recent Visualizations Section (Future Enhancement)
    
    private var recentVisualizationsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacingMD) {
            HStack {
                Text("Recent Work")
                    .font(theme.heading3)
                    .foregroundStyle(theme.foreground)
                
                Spacer()
                
                Button("See All") {
                    // Navigate to full gallery
                }
                .font(theme.caption)
                .foregroundStyle(theme.primary)
            }
            .padding(.horizontal, theme.spacingLG)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacingMD) {
                    // Recent visualization thumbnails would go here
                    ForEach(0..<3) { index in
                        RecentVisualizationCard(index: index)
                    }
                }
                .padding(.horizontal, theme.spacingLG)
            }
        }
    }
}

// MARK: - Supporting Views

private struct BrandCard: View {
    @Environment(Theme.self) private var theme

    let name: String
    let tagline: String
    let icon: String
    let accentColor: Color
    let isSelected: Bool
    let isDashed: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: theme.spacingMD) {

                ZStack {
                    RoundedRectangle(cornerRadius: theme.radiusSM)
                        .fill(.white)
                        .frame(width: 56, height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.radiusSM)
                                .stroke(theme.border, lineWidth: 1)
                        )
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(theme.headline)
                        .foregroundStyle(theme.foreground)
                    Text(tagline)
                        .font(theme.caption)
                        .foregroundStyle(theme.mutedForeground)
                }
                Spacer()
            }
            .padding(theme.spacingMD)
            .background(isSelected ? theme.primary.opacity(0.05) : theme.card)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(theme.primary)
                        .font(.system(size: 22))
                        .padding(12)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: theme.radiusLG)
                    .stroke(
                        isSelected ? theme.primary : (isDashed ? theme.border : .clear),
                        style: isDashed ? StrokeStyle(lineWidth: 1.5, dash: [6]) : StrokeStyle(lineWidth: 2)
                    )
            )
            .shadow(color: .black.opacity(isSelected ? 0 : 0.05), radius: 4, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(tagline)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isDashed ? "Coming soon" : "Double tap to select")
    }
}

private struct RecentVisualizationCard: View {
    @Environment(Theme.self) private var theme
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacingSM) {
            // Thumbnail placeholder
            RoundedRectangle(cornerRadius: theme.radiusMD)
                .fill(theme.muted)
                .frame(width: 120, height: 160)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundStyle(theme.mutedForeground.opacity(0.3))
                )
            
            Text("Project \(index + 1)")
                .font(theme.caption)
                .foregroundStyle(theme.foreground)
            
            Text("2 days ago")
                .font(.system(size: 11))
                .foregroundStyle(theme.mutedForeground)
        }
    }
}

// MARK: - Empty State

extension StudioHomeView {
    /// Empty state shown when user has no visualizations yet
    var emptyStudioState: some View {
        ContentUnavailableView {
            Label("Welcome to Your Studio", systemImage: "paintpalette.fill")
        } description: {
            Text("Create beautiful paint visualizations to see how colors look in real spaces")
        } actions: {
            Button {
                navState.beginVisualization()
                router.navigate(to: .itemPicker)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("Create Your First Visualization")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}

// MARK: - Preview

#Preview("Studio Home - Brand Selection") {
    NavigationStack {
        StudioHomeView()
    }
    .environment(Theme())
    .environment(RouterPath())
    .environment(VisualizerViewModel())
    .environment(NavigationState())
}

#Preview("Studio Home - Empty State") {
    NavigationStack {
        StudioHomeView()
            .emptyStudioState
    }
    .environment(Theme())
    .environment(RouterPath())
    .environment(VisualizerViewModel())
    .environment(NavigationState())
}

// MARK: - Migration Notes
/*
 
 CHANGES FROM BrandSelectorView:
 ================================
 
 1. File renamed: BrandSelectorView.swift → StudioHomeView.swift
 2. Struct renamed: BrandSelectorView → StudioHomeView
 3. Navigation title: "Select a Paint Brand" → "Studio"
 4. Header title: "Select a Paint Brand" → "Your Studio"
 5. Header subtitle: Updated to mention "Studio"
 6. Button text: "Continue" → "Create Visualization"
 7. Added empty state for first-time users
 8. Added (commented out) recent visualizations section for future
 9. Integrated with NavigationState for focused mode
 
 
 LANGUAGE IMPROVEMENTS:
 ======================
 
 OLD:
 - "Select a Paint Brand" → Generic, transactional
 - "Continue" → Where to? Why?
 - No sense of ownership or creation
 
 NEW:
 - "Your Studio" → Personal, professional
 - "Create Visualization" → Clear action, clear outcome
 - Sense of creative workspace
 
 
 USER FLOW:
 ==========
 
 1. User opens app → Studio tab selected by default
 2. Sees "Your Studio" with brand options
 3. Selects brand (e.g., Benjamin Moore)
 4. Taps "Create Visualization" button
 5. Enters focused mode (tabs hide, adaptive footer appears)
 6. Proceeds through color picking → photo → results
 7. Returns to Studio tab to see saved work
 
 
 ACCESSIBILITY IMPROVEMENTS:
 ===========================
 
 - Button has clear accessibility hint
 - Brand cards have combined labels
 - Empty state is properly structured
 - VoiceOver reads: "Studio tab, selected" (not "Visualize tab")
 
 */
