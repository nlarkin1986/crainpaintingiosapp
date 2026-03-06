import SwiftUI

enum AppButtonVariant {
    case primary
    case outline
    case ghost
    case cta
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
                }
                Text(title)
                    .font(fontSize)
            }
            .frame(maxWidth: .infinity)
            .frame(height: variant == .cta ? 56 : 48)
            .foregroundStyle(foregroundColor)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(overlayBorder)
            .shadow(color: variant == .cta ? theme.actionPrimary.opacity(0.2) : .clear, radius: 8, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }

    private var fontSize: Font {
        switch variant {
        case .cta: TypographyTokens.heading3
        case .primary: TypographyTokens.label
        case .outline, .ghost: TypographyTokens.bodySmall
        }
    }

    private var cornerRadius: CGFloat {
        variant == .cta ? theme.radiusLG : theme.radiusMD
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary: theme.actionPrimaryText
        case .cta: theme.actionCTAText
        case .outline: theme.foreground
        case .ghost: theme.primary
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch variant {
        case .primary:
            theme.actionPrimary
        case .cta:
            theme.ctaGradient
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

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}
