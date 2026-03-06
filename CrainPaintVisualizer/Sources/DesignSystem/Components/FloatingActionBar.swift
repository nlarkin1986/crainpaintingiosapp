import SwiftUI

struct FloatingActionBar<Content: View>: View {
    @Environment(Theme.self) private var theme
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            content()
                .padding(.horizontal, theme.spacingMD)
                .padding(.vertical, theme.spacingSM)
                .background(.ultraThinMaterial)
        }
    }
}
