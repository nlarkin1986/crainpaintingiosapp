import SwiftUI

// MARK: - Typography Tokens

/// All typography uses Apple system fonts: SF Pro, New York, SF Rounded, SF Mono.
/// No custom font bundling needed — automatic Dynamic Type scaling.
enum TypographyTokens {

    // MARK: - SF Pro (Default) — UI Text

    static let displayLarge: Font = .system(.largeTitle, design: .default, weight: .bold)
    static let displayMedium: Font = .system(.title, design: .default, weight: .bold)
    static let heading1: Font = .system(.title2, design: .default, weight: .semibold)
    static let heading2: Font = .system(.title3, design: .default, weight: .semibold)
    static let heading3: Font = .system(.headline, design: .default, weight: .semibold)
    static let bodyLarge: Font = .system(.body, design: .default, weight: .regular)
    static let bodyDefault: Font = .system(.callout, design: .default, weight: .regular)
    static let bodySmall: Font = .system(.subheadline, design: .default, weight: .regular)
    static let label: Font = .system(.subheadline, design: .default, weight: .medium)
    static let caption: Font = .system(.footnote, design: .default, weight: .regular)
    static let captionSmall: Font = .system(.caption, design: .default, weight: .regular)
    static let micro: Font = .system(.caption, design: .default, weight: .medium)

    // MARK: - New York (Serif) — Editorial & Expert Content

    static let editorialTitle: Font = .system(.title, design: .serif, weight: .bold)
    static let editorialSubtitle: Font = .system(.title3, design: .serif, weight: .regular)
    static let editorialBody: Font = .system(.body, design: .serif, weight: .regular)
    static let editorialQuote: Font = .system(.callout, design: .serif, weight: .regular).italic()

    // MARK: - SF Rounded — Friendly Accents

    static let friendlyNumber: Font = .system(.title, design: .rounded, weight: .bold)
    static let friendlyLabel: Font = .system(.headline, design: .rounded, weight: .semibold)

    // MARK: - SF Mono — Technical Details

    static let monoCode: Font = .system(.footnote, design: .monospaced, weight: .regular)
    static let monoLabel: Font = .system(.caption, design: .monospaced, weight: .medium)
}
