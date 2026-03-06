import SwiftUI

struct AppInput: View {
    @Environment(Theme.self) private var theme
    @FocusState private var isFocused: Bool

    let placeholder: String
    @Binding var text: String
    var icon: String?

    var body: some View {
        HStack(spacing: theme.spacingSM) {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(theme.mutedForeground)
            }
            TextField(placeholder, text: $text)
                .font(theme.body)
                .focused($isFocused)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(theme.mutedForeground)
                }
            }
        }
        .padding(.horizontal, theme.spacingMD)
        .frame(height: 48)
        .background(theme.input)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusMD)
                .stroke(isFocused ? theme.primary : theme.border, lineWidth: isFocused ? 2 : 1)
        )
    }
}
