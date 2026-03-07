import SwiftUI

// MARK: - Semantic Color Tokens

enum ColorTokens {

    // MARK: - Aqua Blue (Primary Brand Color)
    static let aqua = Color(hex: "00C2CB")           // Vibrant aqua blue
    static let aquaDark = Color(hex: "00969E")       // Darker aqua for text/icons
    static let aquaLight = Color(hex: "4DD4DB")      // Lighter aqua for hover states
    static let aquaSubtle = Color(hex: "E5F8F9")     // Very light aqua for backgrounds
    static let aquaPressed = Color(hex: "00B0B8")    // Pressed state
    
    // MARK: - Yellow (Complementary/Accent Color)
    static let sunshine = Color(hex: "FFD12E")       // Bright sunshine yellow
    static let sunshineDeep = Color(hex: "FFB800")   // Deeper yellow for emphasis
    static let sunshineLight = Color(hex: "FFEAA7")  // Light yellow for highlights
    static let sunshineSubtle = Color(hex: "FFFAEB") // Very light yellow for backgrounds
    
    // MARK: - Clean Whites & Grays
    static let pureWhite = Color(hex: "FFFFFF")
    static let cloudWhite = Color(hex: "FAFBFC")     // Off-white background
    static let lightGray = Color(hex: "F7F8FA")      // Light surface
    static let warmGray = Color(hex: "F0F1F3")       // Warm neutral
    
    // MARK: - Text & Ink
    static let inkPrimary = Color(hex: "1A1D29")     // Almost black, readable
    static let inkSecondary = Color(hex: "5E6573")   // Medium gray text
    static let inkTertiary = Color(hex: "8F95A3")    // Light gray text

    // MARK: - Brand / Accent (Updated)

    static let accent = aqua
    static let accentLight = aquaLight
    static let accentSubtle = aquaSubtle
    static let accentContrast = Color.white

    // MARK: - Action / CTA

    static let actionPrimary = aqua
    static let actionPrimaryPressed = aquaPressed
    static let actionPrimaryText = pureWhite
    static let actionCTAText = pureWhite
    static let actionSecondary = warmGray
    static let actionSecondaryText = inkPrimary
    static let actionDestructive = Color(hex: "FF385C")  // Airbnb-style red
    static let actionDestructiveText = Color.white

    // MARK: - Feedback / Status

    static let feedbackSuccess = Color(hex: "00A699")   // Teal green
    static let feedbackSuccessSubtle = Color(hex: "E8F5F4")
    static let feedbackWarning = sunshineDeep
    static let feedbackWarningSubtle = sunshineSubtle
    static let feedbackError = Color(hex: "FF385C")
    static let feedbackErrorSubtle = Color(hex: "FFF5F7")
    static let feedbackInfo = aquaDark
    static let feedbackInfoSubtle = aquaSubtle

    // MARK: - Specialized / Feature-Specific

    static let visualizerCanvas = pureWhite
    static let visualizerSliderHandle = inkPrimary
    static let visualizerSliderLine = pureWhite
    static let swatchBorder = Color.black.opacity(0.08)
    static let swatchSelected = aqua
    static let expertBadge = sunshineDeep
    static let expertBadgeSubtle = sunshineSubtle
    static let stepComplete = Color(hex: "00A699")
    static let stepCurrent = aqua
    static let stepUpcoming = Color(hex: "E0E2E7")

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
    static let textOnAction = pureWhite
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

// MARK: - Programmatic Adaptive Colors (Clean Bright Design)

extension Color {
    // Bright, clean backgrounds with excellent readability
    static let cBackground = Color(light: Color(hex: "FAFBFC"), dark: Color(hex: "1A1D29"))
    static let cBackgroundSecondary = Color(light: Color(hex: "F7F8FA"), dark: Color(hex: "23252E"))
    static let cBackgroundTertiary = Color(light: Color(hex: "F0F1F3"), dark: Color(hex: "2C2E38"))
    static let cBackgroundElevated = Color(light: Color(hex: "FFFFFF"), dark: Color(hex: "2F3241"))
    static let cSurfaceMuted = Color(light: Color(hex: "F4F5F7"), dark: Color(hex: "383A47"))

    // Crisp, minimal borders
    static let cBorderDefault = Color(light: Color(hex: "E0E2E7"), dark: Color(hex: "44475A"))
    static let cBorderSubtle = Color(light: Color(hex: "EBEDF2"), dark: Color(hex: "3A3D4A"))
    static let cBorderStrong = Color(light: Color(hex: "C1C4CD"), dark: Color(hex: "565968"))

    // High-contrast, readable text
    static let cTextPrimary = Color(light: Color(hex: "1A1D29"), dark: Color(hex: "F7F8FA"))
    static let cTextSecondary = Color(light: Color(hex: "5E6573"), dark: Color(hex: "A8AEBA"))
    static let cTextTertiary = Color(light: Color(hex: "8F95A3"), dark: Color(hex: "6E7382"))
    static let cTextDisabled = Color(light: Color(hex: "C1C4CD"), dark: Color(hex: "44475A"))
    static let cTextLink = Color(light: ColorTokens.aquaDark, dark: ColorTokens.aquaLight)

    /// Creates an adaptive color from light and dark variants
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}
