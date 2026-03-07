import SwiftUI

enum AppCardElevation {
    case flat        // No shadow, just border
    case raised      // Subtle elevation
    case floating    // Prominent elevation
    case hover       // Interactive state
}

struct AppCard<Content: View>: View {
    @Environment(Theme.self) private var theme
    let elevation: AppCardElevation
    let accentColor: Color?
    let content: () -> Content

    init(
        elevation: AppCardElevation = .raised,
        accentColor: Color? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.elevation = elevation
        self.accentColor = accentColor
        self.content = content
    }

    var body: some View {
        content()
            .background(theme.card)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(borderOverlay)
            .modifier(ElevationShadow(elevation: elevation, theme: theme))
    }
    
    private var cornerRadius: CGFloat {
        switch elevation {
        case .floating, .hover: theme.radiusXL
        default: theme.radiusLG
        }
    }
    
    @ViewBuilder
    private var borderOverlay: some View {
        if let accentColor {
            // Accent border (e.g., aqua blue or sunshine yellow)
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        } else if elevation == .flat {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(theme.borderSubtle, lineWidth: 1)
        }
    }
}

private struct ElevationShadow: ViewModifier {
    let elevation: AppCardElevation
    let theme: Theme

    func body(content: Content) -> some View {
        switch elevation {
        case .flat:
            content
        case .raised:
            content
                .shadow(color: Color.black.opacity(0.04), radius: 2, y: 1)
                .shadow(color: Color.black.opacity(0.06), radius: 8, y: 2)
        case .floating:
            content
                .shadow(color: Color.black.opacity(0.06), radius: 4, y: 2)
                .shadow(color: Color.black.opacity(0.1), radius: 16, y: 4)
        case .hover:
            content
                .shadow(color: ColorTokens.aqua.opacity(0.15), radius: 8, y: 2)
                .shadow(color: Color.black.opacity(0.08), radius: 20, y: 6)
        }
    }
}
