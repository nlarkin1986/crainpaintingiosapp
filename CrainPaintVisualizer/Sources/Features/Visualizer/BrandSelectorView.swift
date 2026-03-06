import SwiftUI

struct BrandSelectorView: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @Environment(VisualizerViewModel.self) private var visualizerVM

    @State private var showComingSoonToast = false

    private let brands: [(PaintBrand?, String, String, String, Color)] = [
        (.benjaminMoore, "Benjamin Moore", "Premium quality since 1883", "paintbrush", Color(hex: "2E5090")),
        (.sherwinWilliams, "Sherwin-Williams", "Color for every vision", "globe", Color(hex: "E31837")),
        (.behr, "Behr", "Reliable color solutions", "paintpalette.fill", Color(hex: "FF6F00")),
        (nil, "Other Brand", "Coming soon", "chevron.right", Color(hex: "64748B")),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacingMD) {
                    BrandedHeader(
                        title: "Select a Paint Brand",
                        subtitle: "Choose your preferred manufacturer to browse their color catalog."
                    )

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
            }

            FloatingActionBar {
                AppButton("Continue", variant: .cta, icon: "arrow.right") {
                    router.navigate(to: .itemPicker)
                }
                .accessibilityIdentifier("brandSelector.continue")
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: visualizerVM.selectedBrand)
        .toast(isPresented: $showComingSoonToast, message: "Custom brands coming soon!", icon: "clock")
    }
}

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
