import SwiftUI

struct HowItWorksView: View {
    @Environment(Theme.self) private var theme

    let onBack: () -> Void
    let onContinue: () -> Void

    private let steps: [HowItWorksStep] = [
        .init(
            number: "1",
            title: "Upload your room",
            subtitle: "Start with your real space so every preview feels grounded."
        ),
        .init(
            number: "2",
            title: "Shortlist strong colors",
            subtitle: "Compare a few serious color options without leaving your photo."
        ),
        .init(
            number: "3",
            title: "Ask Curt only if needed",
            subtitle: "Expert guidance stays optional until you want a final recommendation."
        ),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: theme.space20) {
                header
                introSection
                stepsSection
                footer
            }
            .padding(.horizontal, theme.space24)
            .padding(.top, theme.space20 + 28)
            .padding(.bottom, theme.space24)
        }
        .background(theme.background.ignoresSafeArea())
    }

    private var header: some View {
        HStack(alignment: .top, spacing: theme.space12) {
            VStack(alignment: .leading, spacing: theme.space8) {
                Text("How it works")
                    .font(theme.heading1)
                    .foregroundStyle(theme.foreground)
                    .accessibilityIdentifier("howItWorks.title")

                Text("Preview your own room first. Bring in expert guidance only when you want the final call.")
                    .font(theme.bodySmall)
                    .foregroundStyle(theme.mutedForeground)
            }

            Spacer(minLength: theme.space12)

            Button(action: onBack) {
                Label("Close", systemImage: "xmark")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.foreground)
                    .frame(width: 44, height: 44)
                    .background(theme.card)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(theme.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
            .accessibilityIdentifier("howItWorks.back")
        }
    }

    private var introSection: some View {
        HStack(spacing: theme.space8) {
            AppBadge(text: "3 free previews", isFilled: true)

            Text("No credit card required")
                .font(theme.captionSmall)
                .foregroundStyle(theme.mutedForeground)
        }
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: theme.space12) {
            ForEach(steps) { step in
                stepRow(step)
            }
        }
    }

    private func stepRow(_ step: HowItWorksStep) -> some View {
        HStack(alignment: .top, spacing: theme.space16) {
            Text(step.number)
                .font(theme.captionSmall.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(theme.primary)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: theme.space4) {
                Text(step.title)
                    .font(theme.heading3)
                    .foregroundStyle(theme.foreground)

                Text(step.subtitle)
                    .font(theme.bodySmall)
                    .foregroundStyle(theme.mutedForeground)
            }
        }
        .padding(theme.space16)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusLG)
                .stroke(theme.border, lineWidth: 1)
        )
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: theme.space16) {
            Text("You can keep exploring on your own, then bring in Curt only when you want a final recommendation.")
                .font(theme.caption)
                .foregroundStyle(theme.mutedForeground)

            AppButton("Get My Free Previews", variant: .cta, icon: "arrow.right.circle.fill") {
                onContinue()
            }
            .accessibilityIdentifier("howItWorks.continue")
        }
    }
}

private struct HowItWorksStep: Identifiable {
    let id: String
    let number: String
    let title: String
    let subtitle: String

    init(number: String, title: String, subtitle: String) {
        self.id = number
        self.number = number
        self.title = title
        self.subtitle = subtitle
    }
}

#Preview {
    HowItWorksView(onBack: {}, onContinue: {})
        .environment(Theme())
}
