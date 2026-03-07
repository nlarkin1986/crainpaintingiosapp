import SwiftUI

enum AppButtonVariant {
    case primary      // Aqua blue solid
    case outline      // White with border
    case ghost        // Transparent with text
    case cta          // Aqua gradient, prominent
    case sunshine     // Yellow accent for special actions
}

struct AppButton: View {
    @Environment(Theme.self) private var theme

    let title: String
    let variant: AppButtonVariant
    let icon: String?
    let isDisabled: Bool
    let action: () -> Void

    init(
        _ title: String,
        variant: AppButtonVariant = .primary,
        icon: String? = nil,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.variant = variant
        self.icon = icon
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: theme.spacingSM) {
                if let icon {
                    Image(systemName: icon)
                        .font(iconSize)
                        .imageScale(.medium)
                }
                Text(title)
                    .font(fontSize)
                    .fontWeight(fontWeight)
            }
            .frame(maxWidth: .infinity)
            .frame(height: buttonHeight)
            .foregroundStyle(foregroundColor)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(overlayBorder)
            .shadow(color: shadowColor, radius: shadowRadius, y: shadowY)
        }
        .buttonStyle(SpringButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }

    private var buttonHeight: CGFloat {
        switch variant {
        case .cta: 56
        case .sunshine: 52
        default: 48
        }
    }

    private var fontWeight: Font.Weight {
        switch variant {
        case .cta, .sunshine: .semibold
        case .primary: .medium
        default: .regular
        }
    }

    private var iconSize: Font {
        variant == .cta || variant == .sunshine 
            ? .system(size: 18, weight: .semibold)
            : .system(size: 16, weight: .medium)
    }

    private var fontSize: Font {
        switch variant {
        case .cta: TypographyTokens.heading3
        case .sunshine: TypographyTokens.heading3
        case .primary: TypographyTokens.label
        case .outline, .ghost: TypographyTokens.bodySmall
        }
    }

    private var cornerRadius: CGFloat {
        switch variant {
        case .cta, .sunshine: theme.radiusLG
        default: theme.radiusMD
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary: theme.actionPrimaryText
        case .cta: theme.actionCTAText
        case .sunshine: ColorTokens.inkPrimary
        case .outline: theme.foreground
        case .ghost: theme.primary
        }
    }

    // Enhanced shadows for depth
    private var shadowColor: Color {
        switch variant {
        case .cta: theme.actionPrimary.opacity(0.25)
        case .sunshine: ColorTokens.sunshine.opacity(0.3)
        case .primary: Color.black.opacity(0.08)
        default: .clear
        }
    }

    private var shadowRadius: CGFloat {
        switch variant {
        case .cta, .sunshine: 12
        case .primary: 4
        default: 0
        }
    }

    private var shadowY: CGFloat {
        switch variant {
        case .cta, .sunshine: 4
        case .primary: 2
        default: 0
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch variant {
        case .primary:
            theme.actionPrimary
        case .cta:
            // Aqua blue gradient
            LinearGradient(
                colors: [ColorTokens.aqua, ColorTokens.aquaDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sunshine:
            // Sunshine yellow gradient
            LinearGradient(
                colors: [ColorTokens.sunshine, ColorTokens.sunshineDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .outline:
            theme.card
        case .ghost:
            Color.clear
        }
    }

    @ViewBuilder
    private var overlayBorder: some View {
        switch variant {
        case .outline:
            RoundedRectangle(cornerRadius: theme.radiusMD)
                .stroke(theme.border, lineWidth: 1.5)
        default:
            EmptyView()
        }
    }
}

// Enhanced button style with spring animation
struct SpringButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
// Simple scale button style for interactive elements
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

