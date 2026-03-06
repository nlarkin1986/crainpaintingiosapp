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
                    .font(theme.subhead)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .foregroundStyle(foregroundColor)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))
            .overlay(overlayBorder)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary, .cta: .white
        case .outline: theme.foreground
        case .ghost: theme.primary
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch variant {
        case .primary:
            theme.primary
        case .cta:
            theme.ctaGradient
        case .outline, .ghost:
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
