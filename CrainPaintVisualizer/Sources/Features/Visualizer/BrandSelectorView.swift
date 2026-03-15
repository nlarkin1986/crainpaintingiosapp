import SwiftUI

struct BrandSelectorView: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @Environment(VisualizerViewModel.self) private var visualizerVM

    private let brands: [BrandSelectionOption] = [
        .init(brand: .benjaminMoore, name: "Benjamin Moore", tagline: "Premium quality since 1883", accentColor: Color(hex: "2E5090")),
        .init(brand: .sherwinWilliams, name: "Sherwin-Williams", tagline: "Color for every vision", accentColor: Color(hex: "E31837")),
        .init(brand: .farrowBall, name: "Farrow & Ball", tagline: "Heritage colour, handcrafted depth", accentColor: Color(hex: "7A7468")),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: theme.space16) {
                    WizardHeader(
                        steps: wizardSteps,
                        currentStep: 0,
                        helper: "Choose the catalog you want to start from."
                    )

                    VStack(spacing: theme.space12) {
                        ForEach(brands) { brand in
                            BrandCard(
                                option: brand,
                                isSelected: visualizerVM.selectedBrand == brand.brand
                            ) {
                                guard let paintBrand = brand.brand else { return }
                                visualizerVM.setSelectedBrand(paintBrand)
                                Task(priority: .utility) {
                                    await SharedColorCatalogStore.shared.prewarm(brand: paintBrand)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, theme.spacingMD)
                    .padding(.bottom, 120)
                }
            }

            FloatingActionBar {
                AppButton("Continue", variant: .cta, icon: "arrow.right") {
                    router.navigate(to: .itemPicker)
                }
                .accessibilityIdentifier("brandSelector.continue")
            }
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle("Choose Brand")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: visualizerVM.selectedBrand)
    }

    private var wizardSteps: [String] {
        ["Brand", "Colors", "Photo", "Surface"]
    }
}

private struct BrandSelectionOption: Identifiable {
    let brand: PaintBrand?
    let name: String
    let tagline: String
    let accentColor: Color

    var id: String {
        brand?.rawValue ?? name
    }
}

private struct BrandCard: View {
    @Environment(Theme.self) private var theme

    let option: BrandSelectionOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: theme.space16) {
                if let brand = option.brand {
                    ZStack {
                        RoundedRectangle(cornerRadius: theme.radiusMD)
                            .fill(theme.background)
                            .overlay(
                                RoundedRectangle(cornerRadius: theme.radiusMD)
                                    .stroke(option.accentColor.opacity(isSelected ? 0.28 : 0.12), lineWidth: 1)
                            )

                        BrandLogoView(brand: brand, style: .card)
                            .frame(width: 118, height: 48)
                    }
                    .frame(width: 132, height: 82)
                    .shadow(color: .black.opacity(isSelected ? 0.06 : 0.03), radius: isSelected ? 14 : 10, y: isSelected ? 6 : 4)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: theme.radiusMD)
                            .fill(option.accentColor.opacity(isSelected ? 0.12 : 0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: theme.radiusMD)
                                    .stroke(option.accentColor.opacity(isSelected ? 0.32 : 0.16), lineWidth: 1)
                            )

                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(option.accentColor)
                    }
                    .frame(width: 82, height: 82)
                }

                VStack(alignment: .leading, spacing: theme.space4) {
                    Text(option.name)
                        .font(theme.heading2)
                        .foregroundStyle(theme.foreground)
                    Text(option.tagline)
                        .font(theme.bodySmall)
                        .foregroundStyle(theme.mutedForeground)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: theme.space12)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? theme.primary : theme.borderStrong)
            }
            .padding(theme.spacingMD)
            .background(isSelected ? theme.accentSubtle.opacity(0.7) : theme.card)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radiusLG)
                    .stroke(isSelected ? theme.primary.opacity(0.72) : theme.borderSubtle, lineWidth: isSelected ? 1.5 : 1)
            )
            .shadow(color: .black.opacity(isSelected ? 0.05 : 0.03), radius: isSelected ? 16 : 10, y: isSelected ? 6 : 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(option.name), \(option.tagline)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Double tap to select")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("brandSelector.option.\(option.id)")
    }
}

struct CompactBrandSelectorView: View {
    @Environment(Theme.self) private var theme

    let brands: [PaintBrand]
    let selectedBrand: PaintBrand
    let onSelect: (PaintBrand) -> Void

    var body: some View {
        HStack(spacing: theme.space4) {
            ForEach(brands, id: \.self) { brand in
                CompactBrandSegmentButton(
                    brand: brand,
                    isSelected: selectedBrand == brand,
                    action: { onSelect(brand) }
                )
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: theme.radiusXL)
                .fill(theme.secondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusXL)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 10, y: 4)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("itemPicker.brandSelector")
    }
}

private struct CompactBrandSegmentButton: View {
    @Environment(Theme.self) private var theme

    let brand: PaintBrand
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            BrandLogoView(brand: brand, style: .compact)
                .frame(maxWidth: .infinity, minHeight: 48, maxHeight: 48)
                .background(
                    RoundedRectangle(cornerRadius: theme.radiusLG)
                        .fill(isSelected ? theme.card : .clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radiusLG)
                        .stroke(isSelected ? theme.primary.opacity(0.7) : .clear, lineWidth: 1)
                )
                .shadow(color: isSelected ? theme.primary.opacity(0.14) : .clear, radius: 10, y: 4)
                .contentShape(RoundedRectangle(cornerRadius: theme.radiusLG))
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityIdentifier("itemPicker.brand.\(brand.rawValue)")
        .accessibilityLabel(brand.displayName)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint(isSelected ? "Current brand" : "Double tap to switch brand")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

enum BrandWordmarkStyle {
    case compact
    case card
}

struct BrandWordmarkMetrics {
    let scale: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let verticalOffset: CGFloat
    let maxHeight: CGFloat
}

struct BrandLogoView: View {
    let brand: PaintBrand
    var style: BrandWordmarkStyle = .card

    var body: some View {
        let metrics = brand.wordmarkMetrics(for: style)

        Image(brand.logoAssetName)
            .resizable()
            .interpolation(.high)
            .antialiased(true)
            .aspectRatio(contentMode: .fit)
            .frame(maxHeight: metrics.maxHeight)
            .scaleEffect(metrics.scale)
            .offset(y: metrics.verticalOffset)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, metrics.horizontalPadding)
            .padding(.vertical, metrics.verticalPadding)
            .accessibilityHidden(true)
    }
}

extension PaintBrand {
    var logoAssetName: String {
        switch self {
        case .benjaminMoore:
            "BenjaminMooreLogo"
        case .sherwinWilliams:
            "SherwinWilliamsLogo"
        case .farrowBall:
            "FarrowBallLogo"
        case .behr:
            "BehrLogo"
        }
    }

    func wordmarkMetrics(for style: BrandWordmarkStyle) -> BrandWordmarkMetrics {
        switch (self, style) {
        case (.benjaminMoore, .compact):
            BrandWordmarkMetrics(scale: 0.92, horizontalPadding: 12, verticalPadding: 10, verticalOffset: 0, maxHeight: 17)
        case (.sherwinWilliams, .compact):
            BrandWordmarkMetrics(scale: 1.08, horizontalPadding: 10, verticalPadding: 8, verticalOffset: -0.5, maxHeight: 20)
        case (.farrowBall, .compact):
            BrandWordmarkMetrics(scale: 0.9, horizontalPadding: 16, verticalPadding: 10, verticalOffset: -1, maxHeight: 17)
        case (.behr, .compact):
            BrandWordmarkMetrics(scale: 0.96, horizontalPadding: 12, verticalPadding: 10, verticalOffset: 0, maxHeight: 18)
        case (.benjaminMoore, .card):
            BrandWordmarkMetrics(scale: 0.98, horizontalPadding: 18, verticalPadding: 14, verticalOffset: 0, maxHeight: 26)
        case (.sherwinWilliams, .card):
            BrandWordmarkMetrics(scale: 1.05, horizontalPadding: 16, verticalPadding: 14, verticalOffset: -0.5, maxHeight: 30)
        case (.farrowBall, .card):
            BrandWordmarkMetrics(scale: 0.88, horizontalPadding: 22, verticalPadding: 15, verticalOffset: -1, maxHeight: 24)
        case (.behr, .card):
            BrandWordmarkMetrics(scale: 0.98, horizontalPadding: 18, verticalPadding: 14, verticalOffset: 0, maxHeight: 26)
        }
    }
}
