import SwiftUI

struct HowItWorksView: View {
    @Environment(Theme.self) private var theme

    let onBack: () -> Void
    let onContinue: () -> Void

    private let steps: [HowItWorksStep] = [
        .init(
            number: "1",
            title: "Pick Your Palette",
            subtitle: "Browse curated collections from Benjamin Moore & Sherwin-Williams."
        ),
        .init(
            number: "2",
            title: "Snap & Upload",
            subtitle: "Our AI handles lighting, shadows, and masking so previews stay true to your space."
        ),
        .init(
            number: "3",
            title: "Expert Review",
            subtitle: "Bring your favorite render into a polished report and consultation with Curt."
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: theme.space48) {
                    heroSection
                    stepsSection
                    trustSection
                }
                .padding(.horizontal, theme.spacingLG)
                .padding(.top, theme.spacingLG)
                .padding(.bottom, theme.spacingXL)
            }
        }
        .background(Color.white)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            footer
        }
    }

    private var header: some View {
        HStack(spacing: theme.spacingMD) {
            circularIconButton(systemName: "chevron.left", action: onBack)
                .accessibilityIdentifier("howItWorks.back")

            Spacer(minLength: theme.spacingSM)

            HStack(spacing: theme.spacingSM) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12, weight: .bold))
                Text("70+ Years of Craft")
                    .font(TypographyTokens.micro.weight(.black))
                    .tracking(1.2)
                    .textCase(.uppercase)
            }
            .foregroundStyle(ColorTokens.aqua)
            .padding(.horizontal, theme.spacingMD)
            .padding(.vertical, theme.spacingSM)
            .background(ColorTokens.aqua.opacity(0.08))
            .overlay(
                Capsule()
                    .stroke(ColorTokens.aqua.opacity(0.12), lineWidth: 1)
            )
            .clipShape(Capsule())
            .accessibilityElement(children: .combine)

            Spacer(minLength: theme.spacingSM)

            circularIconButton(systemName: "xmark", action: onBack)
                .accessibilityIdentifier("howItWorks.close")
        }
        .padding(.horizontal, theme.spacingLG)
        .padding(.top, theme.spacingSM)
        .padding(.vertical, theme.spacingMD)
        .background(.ultraThinMaterial)
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: theme.spacingLG) {
            VStack(alignment: .leading, spacing: theme.spacingMD) {
                (
                    Text("Visualize your home's potential ")
                        .foregroundStyle(ColorTokens.inkPrimary)
                    + Text("instantly.")
                        .foregroundStyle(ColorTokens.aqua)
                        .italic()
                )
                .font(TypographyTokens.displayLarge)
                .tracking(-1.5)
                .lineSpacing(-2)
                .accessibilityIdentifier("howItWorks.title")

                Text("Stop guessing. Use our AI-powered visualizer to see exactly how your space will look before you lift a brush.")
                    .font(TypographyTokens.bodyDefault)
                    .foregroundStyle(ColorTokens.inkSecondary)
                    .lineSpacing(4)
            }

            ZStack(alignment: .topLeading) {
                Image("HowItWorksHero")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 255)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL, style: .continuous))

                HStack(spacing: theme.spacingSM) {
                    Circle()
                        .fill(ColorTokens.feedbackSuccess)
                        .frame(width: 8, height: 8)
                    Text("AI Mapping Active")
                        .font(TypographyTokens.micro.weight(.black))
                        .tracking(1.2)
                        .textCase(.uppercase)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, theme.spacingMD)
                .padding(.vertical, theme.spacingSM)
                .background(.black.opacity(0.36))
                .clipShape(Capsule())
                .padding(theme.spacingMD)
            }
            .overlay(
                RoundedRectangle(cornerRadius: theme.radiusXL, style: .continuous)
                    .stroke(ColorTokens.borderSubtle.opacity(0.9), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.14), radius: 22, y: 10)
        }
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacingXL) {
            HStack(spacing: theme.spacingMD) {
                Rectangle()
                    .fill(ColorTokens.borderSubtle)
                    .frame(height: 1)
                Text("Easy as 1, 2, 3")
                    .font(TypographyTokens.micro.weight(.black))
                    .tracking(2.6)
                    .textCase(.uppercase)
                    .foregroundStyle(ColorTokens.inkSecondary)
                Rectangle()
                    .fill(ColorTokens.borderSubtle)
                    .frame(height: 1)
            }

            VStack(alignment: .leading, spacing: theme.spacingLG) {
                ForEach(steps) { step in
                    stepRow(step)
                }
            }
        }
    }

    private func stepRow(_ step: HowItWorksStep) -> some View {
        HStack(alignment: .top, spacing: theme.spacingLG) {
            Text(step.number)
                .font(TypographyTokens.heading1.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(ColorTokens.aqua)
                .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG, style: .continuous))
                .shadow(color: ColorTokens.aqua.opacity(0.22), radius: 12, y: 6)

            VStack(alignment: .leading, spacing: theme.spacingSM) {
                Text(step.title)
                    .font(TypographyTokens.heading1.weight(.black))
                    .foregroundStyle(ColorTokens.inkPrimary)
                    .textCase(.uppercase)

                Text(step.subtitle)
                    .font(TypographyTokens.bodyDefault)
                    .foregroundStyle(ColorTokens.inkSecondary)
                    .lineSpacing(3)
            }
            .padding(.top, theme.spacingXS)
        }
    }

    private var trustSection: some View {
        VStack(spacing: theme.spacingMD) {
            HStack(spacing: -10) {
                placeholderAvatar(color: ColorTokens.aquaSubtle)
                placeholderAvatar(color: ColorTokens.sunshineSubtle)
                placeholderAvatar(color: ColorTokens.feedbackSuccessSubtle)

                Text("4.9k")
                    .font(TypographyTokens.micro.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(ColorTokens.aqua)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }

            VStack(spacing: theme.spacingXS) {
                Text("Trusted by 4,900+ Homeowners")
                    .font(TypographyTokens.micro.weight(.black))
                    .tracking(1.8)
                    .textCase(.uppercase)
                    .foregroundStyle(ColorTokens.inkPrimary)

                Text("\"The AI was 99.9% accurate to the final paint job.\"")
                    .font(TypographyTokens.caption)
                    .foregroundStyle(ColorTokens.inkSecondary)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, theme.spacingLG)
        .padding(.vertical, theme.spacingLG)
        .background(ColorTokens.lightGray)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusXL, style: .continuous)
                .stroke(ColorTokens.borderSubtle.opacity(0.9), lineWidth: 1)
        )
    }

    private func placeholderAvatar(color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color)
            Image(systemName: "person.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(ColorTokens.inkTertiary)
        }
        .frame(width: 44, height: 44)
        .overlay(Circle().stroke(Color.white, lineWidth: 2))
    }

    private var footer: some View {
        VStack(spacing: theme.spacingMD) {
            AppButton("Get My Free Renders", variant: .cta, icon: "arrow.right.circle.fill") {
                onContinue()
            }
            .accessibilityIdentifier("howItWorks.continue")

            HStack(spacing: theme.spacingSM) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(ColorTokens.aqua)
                Text("Free to try • No credit card required")
                    .font(TypographyTokens.micro.weight(.black))
                    .tracking(1.0)
                    .textCase(.uppercase)
                    .foregroundStyle(ColorTokens.inkSecondary)
            }
        }
        .padding(.horizontal, theme.spacingLG)
        .padding(.top, theme.spacingMD)
        .padding(.bottom, theme.spacingLG)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0),
                    Color.white.opacity(0.85),
                    Color.white,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func circularIconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(ColorTokens.inkTertiary)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.94))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
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
