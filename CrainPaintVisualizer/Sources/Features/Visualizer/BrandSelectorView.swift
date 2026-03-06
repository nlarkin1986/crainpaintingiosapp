import SwiftUI

struct BrandSelectorView: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @State private var selectedBrand: PaintBrand? = .benjaminMoore

    private let brands: [(PaintBrand?, String, String, String, Color)] = [
        (.benjaminMoore, "Benjamin Moore", "Quality you can trust", "paintbrush", Color(hex: "2E5090")),
        (.sherwinWilliams, "Sherwin-Williams", "Color for every vision", "globe", Color(hex: "E31837")),
        (.behr, "Behr", "Reliable color", "paintpalette", Color(hex: "FF6F00")),
        (nil, "Other Brand", "Enter custom brand", "chevron.right", Color(hex: "64748B")),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacingMD) {
                    Text("Select a Paint Brand")
                        .font(theme.title)
                        .foregroundStyle(theme.foreground)

                    Text("Choose your preferred manufacturer to browse their color catalog.")
                        .font(theme.body)
                        .foregroundStyle(theme.mutedForeground)

                    VStack(spacing: theme.spacingSM) {
                        ForEach(Array(brands.enumerated()), id: \.offset) { index, brand in
                            BrandCard(
                                name: brand.1,
                                tagline: brand.2,
                                icon: brand.3,
                                accentColor: brand.4,
                                isSelected: selectedBrand == brand.0,
                                isDashed: brand.0 == nil
                            ) {
                                selectedBrand = brand.0
                            }
                        }
                    }
                }
                .padding(theme.spacingMD)
            }

            FloatingActionBar {
                AppButton("Continue", variant: .cta, icon: "arrow.right") {
                    router.navigate(to: .itemPicker)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
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
                        .fill(accentColor.opacity(0.1))
                        .frame(width: 48, height: 48)
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

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(theme.primary)
                        .font(.system(size: 22))
                }
            }
            .padding(theme.spacingMD)
            .background(isSelected ? theme.primary.opacity(0.05) : theme.card)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
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
    }
}
