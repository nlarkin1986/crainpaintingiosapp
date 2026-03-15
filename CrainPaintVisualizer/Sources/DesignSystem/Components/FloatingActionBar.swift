import SwiftUI

struct FloatingActionBar<Content: View>: View {
    @Environment(Theme.self) private var theme
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [theme.background.opacity(0), theme.background.opacity(0.45), theme.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 16)

            content()
                .padding(theme.space8)
                .background(
                    RoundedRectangle(cornerRadius: theme.radiusLG)
                        .fill(theme.card.opacity(0.98))
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.radiusLG)
                                .stroke(theme.border, lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.08), radius: 10, y: -2)
                )
                .padding(.horizontal, theme.space12)
        }
        .padding(.bottom, max(safeAreaBottom, theme.space4))
        .background(
            LinearGradient(
                colors: [theme.background.opacity(0), theme.background.opacity(0.88)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
        .accessibilityElement(children: .contain)
    }

    private var safeAreaBottom: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 0
    }
}
