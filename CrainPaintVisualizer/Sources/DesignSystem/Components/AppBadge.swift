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
            .foregroundStyle(isFilled ? theme.actionPrimaryText : theme.mutedForeground)
            .background(isFilled ? theme.actionPrimary : theme.muted)
            .clipShape(Capsule())
    }
}
