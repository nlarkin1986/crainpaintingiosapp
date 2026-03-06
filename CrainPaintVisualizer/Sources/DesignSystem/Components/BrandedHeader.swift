import SwiftUI

struct BrandedHeader: View {
    @Environment(Theme.self) private var theme

    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacingSM) {
            HStack(spacing: theme.spacingSM) {
                RoundedRectangle(cornerRadius: theme.radiusSM)
                    .fill(theme.ctaGradient)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "paintbrush.pointed.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(theme.actionPrimaryText)
                    )
                Text("Crain Painting")
                    .font(theme.headline)
                    .foregroundStyle(theme.foreground)
            }

            Text(title)
                .font(theme.title)
                .foregroundStyle(theme.foreground)

            if let subtitle {
                Text(subtitle)
                    .font(theme.body)
                    .foregroundStyle(theme.mutedForeground)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, theme.spacingLG)
        .padding(.top, theme.spacingXL)
        .padding(.bottom, theme.spacingMD)
    }
}
