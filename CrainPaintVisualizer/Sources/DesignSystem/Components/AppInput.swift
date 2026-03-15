import SwiftUI

struct AppInput: View {
    @Environment(Theme.self) private var theme
    @FocusState private var isFocused: Bool

    let placeholder: String
    @Binding var text: String
    var icon: String?
    var errorMessage: String?
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: theme.spacingSM) {
                if let icon {
                    Image(systemName: icon)
                        .foregroundStyle(hasError ? theme.destructive : theme.mutedForeground)
                }
                TextField(placeholder, text: $text)
                    .font(theme.body)
                    .focused($isFocused)
                    .keyboardType(keyboardType)
                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Label("Clear text", systemImage: "xmark.circle.fill")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(theme.mutedForeground)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear text")
                }
            }
            .padding(.horizontal, theme.spacingMD)
            .frame(height: 52)
            .background(theme.card)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radiusMD)
                    .stroke(borderColor, lineWidth: hasError || isFocused ? 2 : 1)
            )
            .shadow(
                color: isFocused ? theme.primary.opacity(0.14) : .black.opacity(0.04),
                radius: isFocused ? 14 : 6,
                y: 2
            )

            if let errorMessage, hasError {
                Text(errorMessage)
                    .font(theme.micro)
                    .foregroundStyle(theme.destructive)
                    .padding(.horizontal, theme.spacingXS)
            }
        }
    }

    private var hasError: Bool {
        errorMessage != nil && !text.isEmpty
    }

    private var borderColor: Color {
        if hasError { return theme.destructive }
        if isFocused { return theme.primary }
        return theme.border
    }
}
