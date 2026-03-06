import SwiftUI

enum AppCardElevation {
    case flat
    case raised
    case floating
}

struct AppCard<Content: View>: View {
    @Environment(Theme.self) private var theme
    let elevation: AppCardElevation
    let content: () -> Content

    init(elevation: AppCardElevation = .raised, @ViewBuilder content: @escaping () -> Content) {
        self.elevation = elevation
        self.content = content
    }

    var body: some View {
        content()
            .background(theme.card)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radiusLG)
                    .stroke(elevation == .flat ? theme.border : .clear, lineWidth: 1)
            )
            .modifier(ElevationShadow(elevation: elevation, theme: theme))
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
            let s = theme.shadowMD()
            content.shadow(color: s.color, radius: s.radius, y: s.y)
        case .floating:
            let s = theme.shadowLG()
            content.shadow(color: s.color, radius: s.radius, y: s.y)
        }
    }
}
