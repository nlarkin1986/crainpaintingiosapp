import SwiftUI

struct AppCard<Content: View>: View {
    @Environment(Theme.self) private var theme
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .background(theme.card)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}
