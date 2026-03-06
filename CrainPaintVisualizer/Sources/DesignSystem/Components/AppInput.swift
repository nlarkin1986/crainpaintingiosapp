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
                    .stroke(borderColor, lineWidth: hasError || isFocused ? 2 : 0)
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
        return .clear
    }
}
