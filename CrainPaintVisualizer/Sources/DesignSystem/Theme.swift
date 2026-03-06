import SwiftUI

@MainActor
@Observable
final class Theme {

    // MARK: - Colors (Semantic Tokens)

    // Brand / Accent
    var primary: Color = ColorTokens.accent
    var accent: Color = ColorTokens.accentLight
    var accentSubtle: Color = ColorTokens.accentSubtle

    // Action / CTA
    var actionPrimary: Color = ColorTokens.actionPrimary
    var actionPrimaryPressed: Color = ColorTokens.actionPrimaryPressed
    var actionPrimaryText: Color = ColorTokens.actionPrimaryText
    var actionSecondary: Color = ColorTokens.actionSecondary
    var actionSecondaryText: Color = ColorTokens.actionSecondaryText
    var destructive: Color = ColorTokens.actionDestructive

    // Neutrals (adaptive light/dark)
    var background: Color = .cBackground
    var card: Color = .cBackgroundElevated
    var muted: Color = .cSurfaceMuted
    var secondary: Color = .cBackgroundSecondary
    var input: Color = .cBackgroundTertiary

    // Text
    var foreground: Color = .cTextPrimary
    var mutedForeground: Color = .cTextSecondary
    var textTertiary: Color = .cTextTertiary
    var textDisabled: Color = .cTextDisabled
    var textLink: Color = .cTextLink

    // Borders
    var border: Color = .cBorderDefault
    var borderSubtle: Color = .cBorderSubtle
    var borderStrong: Color = .cBorderStrong

    // Feedback
    var feedbackSuccess: Color = ColorTokens.feedbackSuccess
    var feedbackWarning: Color = ColorTokens.feedbackWarning
    var feedbackError: Color = ColorTokens.feedbackError

    // Specialized
    var expertBadge: Color = ColorTokens.expertBadge
    var expertBadgeSubtle: Color = ColorTokens.expertBadgeSubtle
    var stepComplete: Color = ColorTokens.stepComplete
    var stepCurrent: Color = ColorTokens.stepCurrent
    var stepUpcoming: Color = ColorTokens.stepUpcoming

    // CTA Gradient (teal)
    var ctaGradient: LinearGradient {
        LinearGradient(
            colors: [ColorTokens.actionPrimary, ColorTokens.actionPrimaryPressed],
            startPoint: .leading, endPoint: .trailing
        )
    }

    // MARK: - Typography (System Fonts)

    let displayLarge: Font = TypographyTokens.displayLarge
    let displayMedium: Font = TypographyTokens.displayMedium

    // Backward-compatible names mapped to new tokens
    let largeTitle: Font = TypographyTokens.displayLarge
    let title: Font = TypographyTokens.heading1
    let headline: Font = TypographyTokens.heading3
    let body: Font = TypographyTokens.bodyDefault
    let bodyMedium: Font = TypographyTokens.label
    let subhead: Font = TypographyTokens.bodySmall
    let caption: Font = TypographyTokens.captionSmall
    let micro: Font = TypographyTokens.micro

    // New granular tokens
    let heading1: Font = TypographyTokens.heading1
    let heading2: Font = TypographyTokens.heading2
    let heading3: Font = TypographyTokens.heading3
    let bodyLarge: Font = TypographyTokens.bodyLarge
    let bodyDefault: Font = TypographyTokens.bodyDefault
    let bodySmall: Font = TypographyTokens.bodySmall
    let label: Font = TypographyTokens.label
    let captionSmall: Font = TypographyTokens.captionSmall

    // Editorial (serif)
    let editorialTitle: Font = TypographyTokens.editorialTitle
    let editorialSubtitle: Font = TypographyTokens.editorialSubtitle
    let editorialBody: Font = TypographyTokens.editorialBody
    let editorialQuote: Font = TypographyTokens.editorialQuote

    // Friendly (rounded)
    let friendlyNumber: Font = TypographyTokens.friendlyNumber
    let friendlyLabel: Font = TypographyTokens.friendlyLabel

    // Mono (technical)
    let monoCode: Font = TypographyTokens.monoCode
    let monoLabel: Font = TypographyTokens.monoLabel

    // MARK: - Spacing

    let space2: CGFloat = 2
    let space4: CGFloat = 4
    let space8: CGFloat = 8
    let space12: CGFloat = 12
    let space16: CGFloat = 16
    let space20: CGFloat = 20
    let space24: CGFloat = 24
    let space32: CGFloat = 32
    let space48: CGFloat = 48
    let space64: CGFloat = 64

    // Backward-compatible spacing names
    let spacingXS: CGFloat = 4
    let spacingSM: CGFloat = 8
    let spacingMD: CGFloat = 16
    let spacingLG: CGFloat = 24
    let spacingXL: CGFloat = 32
    let spacing2XL: CGFloat = 48

    // MARK: - Corner Radii

    let radiusSmall: CGFloat = 8
    let radiusMedium: CGFloat = 12
    let radiusLarge: CGFloat = 16
    let radiusXL: CGFloat = 24
    let radiusFull: CGFloat = 9999

    // Backward-compatible radius names
    let radiusSM: CGFloat = 8
    let radiusMD: CGFloat = 12
    let radiusLG: CGFloat = 16

    // MARK: - Shadows

    func shadowSM(_ color: Color = .black) -> (color: Color, radius: CGFloat, y: CGFloat) {
        (color.opacity(0.08), 3, 1)
    }
    func shadowMD(_ color: Color = .black) -> (color: Color, radius: CGFloat, y: CGFloat) {
        (color.opacity(0.12), 12, 4)
    }
    func shadowLG(_ color: Color = .black) -> (color: Color, radius: CGFloat, y: CGFloat) {
        (color.opacity(0.16), 24, 8)
    }

    // MARK: - Animation

    static let animationFast: Animation = .spring(response: 0.2)
    static let animationDefault: Animation = .spring(response: 0.35)
    static let animationSlow: Animation = .spring(response: 0.5)
}
