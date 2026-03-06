import SwiftUI

struct FloatingActionBar<Content: View>: View {
    @Environment(Theme.self) private var theme
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            // Gradient fade above bar
            LinearGradient(
                colors: [theme.background.opacity(0), theme.background.opacity(0.85), theme.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 8)

            VStack(spacing: 0) {
                Rectangle()
                    .fill(theme.border)
                    .frame(height: 0.5)

                content()
                    .padding(.horizontal, theme.spacingMD)
                    .padding(.vertical, theme.space12)
                    .background(.regularMaterial)
            }
        }
        .padding(.bottom, safeAreaBottom)
        .background(.regularMaterial.opacity(safeAreaBottom > 0 ? 1 : 0))
        .shadow(color: .black.opacity(0.12), radius: 16, y: -8)
        .accessibilityElement(children: .contain)
    }

    private var safeAreaBottom: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 0
    }
}
