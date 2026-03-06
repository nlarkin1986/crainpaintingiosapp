import SwiftUI

struct AppBadge: View {
    @Environment(Theme.self) private var theme

    let text: String
    var isFilled: Bool = false

    var body: some View {
        Text(text)
            .font(theme.micro)
            .padding(.horizontal, theme.spacingSM)
            .padding(.vertical, theme.spacingXS)
            .foregroundStyle(isFilled ? .white : theme.primary)
            .background(isFilled ? theme.primary : Color.clear)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(theme.primary, lineWidth: isFilled ? 0 : 1)
            )
    }
}
