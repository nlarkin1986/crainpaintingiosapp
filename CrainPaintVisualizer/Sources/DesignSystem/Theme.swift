import SwiftUI

@MainActor
@Observable
final class Theme {
    // MARK: - Colors

    var primary: Color = Color(hex: "0D9488")
    var accent: Color = Color(hex: "14B8A6")
    var foreground: Color = Color(hex: "0F172A")
    var background: Color = .white
    var card: Color = .white
    var muted: Color = Color(hex: "F1F5F9")
    var mutedForeground: Color = Color(hex: "64748B")
    var border: Color = Color(hex: "E2E8F0")
    var destructive: Color = Color(hex: "EF4444")
    var input: Color = Color(hex: "F8FAFC")

    var ctaGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "F6653C"), Color(hex: "27CCC0")],
            startPoint: .leading, endPoint: .trailing
        )
    }

    // MARK: - Typography

    var largeTitle: Font { .custom("MerriweatherSans-Bold", size: 28, relativeTo: .largeTitle) }
    var title: Font { .custom("MerriweatherSans-Bold", size: 22, relativeTo: .title2) }
    var headline: Font { .custom("MerriweatherSans-Bold", size: 18, relativeTo: .headline) }
    var body: Font { .custom("OpenSans-Regular", size: 16, relativeTo: .body) }
    var bodyMedium: Font { .custom("OpenSans-SemiBold", size: 16, relativeTo: .body) }
    var subhead: Font { .custom("OpenSans-Medium", size: 14, relativeTo: .subheadline) }
    var caption: Font { .custom("OpenSans-Regular", size: 12, relativeTo: .caption) }
    var micro: Font { .custom("OpenSans-Medium", size: 11, relativeTo: .caption2) }

    // MARK: - Spacing (4pt grid)

    let spacingXS: CGFloat = 4
    let spacingSM: CGFloat = 8
    let spacingMD: CGFloat = 16
    let spacingLG: CGFloat = 24
    let spacingXL: CGFloat = 32
    let spacing2XL: CGFloat = 48

    // MARK: - Corner Radii

    let radiusSM: CGFloat = 8
    let radiusMD: CGFloat = 12
    let radiusLG: CGFloat = 16
    let radiusXL: CGFloat = 20
}
