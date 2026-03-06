import SwiftUI

// MARK: - Semantic Color Tokens

enum ColorTokens {

    static let teal = Color(hex: "13D4D4")
    static let tealStrong = Color(hex: "0A8080")
    static let tealPressed = Color(hex: "0FBDBD")
    static let tealSubtle = Color(hex: "E8FBFB")
    static let tealInk = Color(hex: "0F172A")

    // MARK: - Brand / Accent

    static let accent = tealStrong
    static let accentLight = teal
    static let accentSubtle = tealSubtle
    static let accentContrast = Color.white

    // MARK: - Action / CTA

    static let actionPrimary = teal
    static let actionPrimaryPressed = tealPressed
    static let actionPrimaryText = tealInk
    static let actionCTAText = Color.white
    static let actionSecondary = Color(hex: "F4F1EB")
    static let actionSecondaryText = Color(hex: "2D2A26")
    static let actionDestructive = Color(hex: "B5332E")
    static let actionDestructiveText = Color.white

    // MARK: - Feedback / Status

    static let feedbackSuccess = Color(hex: "3A7D44")
    static let feedbackSuccessSubtle = Color(hex: "E8F5EA")
    static let feedbackWarning = Color(hex: "C4841D")
    static let feedbackWarningSubtle = Color(hex: "FDF3E3")
    static let feedbackError = Color(hex: "B5332E")
    static let feedbackErrorSubtle = Color(hex: "FBEAEA")
    static let feedbackInfo = tealStrong
    static let feedbackInfoSubtle = tealSubtle

    // MARK: - Specialized / Feature-Specific

    static let visualizerCanvas = Color.white
    static let visualizerSliderHandle = Color(hex: "1C1A17")
    static let visualizerSliderLine = Color.white
    static let swatchBorder = Color.black.opacity(0.08)
    static let swatchSelected = teal
    static let expertBadge = Color(hex: "8B6914")
    static let expertBadgeSubtle = Color(hex: "F8F3E6")
    static let stepComplete = Color(hex: "3A7D44")
    static let stepCurrent = tealStrong
    static let stepUpcoming = Color(hex: "D9D4CB")

    // MARK: - Adaptive Colors (Light / Dark)

    static let backgroundPrimary = Color("backgroundPrimary")
    static let backgroundSecondary = Color("backgroundSecondary")
    static let backgroundTertiary = Color("backgroundTertiary")
    static let backgroundElevated = Color("backgroundElevated")
    static let surfaceMuted = Color("surfaceMuted")

    static let borderDefault = Color("borderDefault")
    static let borderSubtle = Color("borderSubtle")
    static let borderStrong = Color("borderStrong")

    static let textPrimary = Color("textPrimary")
    static let textSecondary = Color("textSecondary")
    static let textTertiary = Color("textTertiary")
    static let textDisabled = Color("textDisabled")
    static let textOnAccent = Color.white
    static let textOnAction = tealInk
    static let textLink = Color("textLink")
}

// MARK: - Adaptive Color Resolver

extension ColorTokens {
    /// Creates adaptive colors that resolve correctly in light/dark mode
    /// without requiring an Asset Catalog. Call `registerAdaptiveColors()` once at app launch.
    static func registerAdaptiveColors() {
        // Colors are registered via the AdaptiveColor asset catalog entries.
        // If asset catalog entries are missing, these fallback initializers handle it.
    }
}

// MARK: - Programmatic Adaptive Colors (No Asset Catalog Required)

extension Color {
    static let cBackground = Color(light: Color(hex: "FAFAF8"), dark: Color(hex: "1A1917"))
    static let cBackgroundSecondary = Color(light: Color(hex: "F4F1EB"), dark: Color(hex: "242320"))
    static let cBackgroundTertiary = Color(light: Color(hex: "EAE6DD"), dark: Color(hex: "2E2D29"))
    static let cBackgroundElevated = Color(light: Color(hex: "FFFFFF"), dark: Color(hex: "302F2B"))
    static let cSurfaceMuted = Color(light: Color(hex: "F0EDE6"), dark: Color(hex: "3A3935"))

    static let cBorderDefault = Color(light: Color(hex: "D9D4CB"), dark: Color(hex: "4A4843"))
    static let cBorderSubtle = Color(light: Color(hex: "E8E4DC"), dark: Color(hex: "3D3B37"))
    static let cBorderStrong = Color(light: Color(hex: "B5B0A6"), dark: Color(hex: "5E5B55"))

    static let cTextPrimary = Color(light: Color(hex: "1C1A17"), dark: Color(hex: "F5F3EF"))
    static let cTextSecondary = Color(light: Color(hex: "5C5850"), dark: Color(hex: "A8A49C"))
    static let cTextTertiary = Color(light: Color(hex: "8A8580"), dark: Color(hex: "706C66"))
    static let cTextDisabled = Color(light: Color(hex: "B5B0A6"), dark: Color(hex: "4A4843"))
    static let cTextLink = Color(light: ColorTokens.tealStrong, dark: ColorTokens.teal)

    /// Creates an adaptive color from light and dark variants
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}
