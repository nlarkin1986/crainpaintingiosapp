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
                VStack(alignment: .leading, spacing: theme.space40) {
                    heroSection
                    stepsSection
                    trustSection
                }
                .padding(.horizontal, theme.space24)
                .padding(.top, theme.space20)
                .padding(.bottom, theme.space32)
            }
        }
        .background(Color.white)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            footer
        }
    }

    private var header: some View {
        HStack(spacing: theme.space12) {
            circularIconButton(systemName: "chevron.left", action: onBack)
                .accessibilityIdentifier("howItWorks.back")

            Spacer(minLength: theme.space8)

            HStack(spacing: theme.space8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12, weight: .bold))
                Text("70+ Years of Craft")
                    .font(theme.micro.weight(.black))
                    .tracking(1.2)
                    .textCase(.uppercase)
            }
            .foregroundStyle(theme.primary)
            .padding(.horizontal, theme.space16)
            .padding(.vertical, theme.space8)
            .background(theme.primary.opacity(0.08))
            .overlay(
                Capsule()
                    .stroke(theme.primary.opacity(0.12), lineWidth: 1)
            )
            .clipShape(Capsule())
            .accessibilityElement(children: .combine)

            Spacer(minLength: theme.space8)

            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, theme.space24)
        .padding(.top, theme.space8)
        .padding(.bottom, theme.space16)
        .background(.ultraThinMaterial)
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: theme.space24) {
            VStack(alignment: .leading, spacing: theme.space12) {
                (
                    Text("Visualize your home's potential ")
                        .foregroundStyle(Color(hex: "0F172A"))
                    + Text("instantly.")
                        .foregroundStyle(theme.primary)
                        .italic()
                )
                .font(.system(size: 48, weight: .black, design: .default))
                .tracking(-1.5)
                .lineSpacing(-2)
                .accessibilityIdentifier("howItWorks.title")

                Text("Stop guessing. Use our AI-powered visualizer to see exactly how your space will look before you lift a brush.")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color(hex: "64748B"))
                    .lineSpacing(4)
            }

            ZStack(alignment: .topLeading) {
                Image("HowItWorksHero")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 255)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))

                HStack(spacing: theme.space8) {
                    Circle()
                        .fill(Color(hex: "22C55E"))
                        .frame(width: 8, height: 8)
                    Text("AI Mapping Active")
                        .font(theme.micro.weight(.black))
                        .tracking(1.2)
                        .textCase(.uppercase)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, theme.space12)
                .padding(.vertical, theme.space8)
                .background(.black.opacity(0.36))
                .clipShape(Capsule())
                .padding(theme.space16)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color(hex: "E2E8F0").opacity(0.9), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.14), radius: 22, y: 10)
        }
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: theme.space32) {
            HStack(spacing: theme.space16) {
                Rectangle()
                    .fill(Color(hex: "E2E8F0"))
                    .frame(height: 1)
                Text("Easy as 1, 2, 3")
                    .font(theme.micro.weight(.black))
                    .tracking(2.6)
                    .textCase(.uppercase)
                    .foregroundStyle(Color(hex: "64748B"))
                Rectangle()
                    .fill(Color(hex: "E2E8F0"))
                    .frame(height: 1)
            }

            VStack(alignment: .leading, spacing: theme.space24) {
                ForEach(steps) { step in
                    stepRow(step)
                }
            }
        }
    }

    private func stepRow(_ step: HowItWorksStep) -> some View {
        HStack(alignment: .top, spacing: theme.space20) {
            Text(step.number)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: theme.primary.opacity(0.22), radius: 12, y: 6)

            VStack(alignment: .leading, spacing: theme.space8) {
                Text(step.title)
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(Color(hex: "0F172A"))
                    .textCase(.uppercase)

                Text(step.subtitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(hex: "64748B"))
                    .lineSpacing(3)
            }
            .padding(.top, theme.space4)
        }
    }

    private var trustSection: some View {
        VStack(spacing: theme.space16) {
            HStack(spacing: -10) {
                placeholderAvatar(color: Color(hex: "D8F3F0"))
                placeholderAvatar(color: Color(hex: "DDEAF6"))
                placeholderAvatar(color: Color(hex: "F4E2D7"))

                Text("4.9k")
                    .font(theme.micro.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(theme.primary)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }

            VStack(spacing: theme.space4) {
                Text("Trusted by 4,900+ Homeowners")
                    .font(theme.micro.weight(.black))
                    .tracking(1.8)
                    .textCase(.uppercase)
                    .foregroundStyle(Color(hex: "0F172A"))

                Text("\"The AI was 99.9% accurate to the final paint job.\"")
                    .font(theme.caption)
                    .foregroundStyle(Color(hex: "64748B"))
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, theme.space24)
        .padding(.vertical, theme.space24)
        .background(Color(hex: "F8FAFC"))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color(hex: "E2E8F0").opacity(0.9), lineWidth: 1)
        )
    }

    private func placeholderAvatar(color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color)
            Image(systemName: "person.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(hex: "334155"))
        }
        .frame(width: 44, height: 44)
        .overlay(Circle().stroke(Color.white, lineWidth: 2))
    }

    private var footer: some View {
        VStack(spacing: theme.space16) {
            AppButton("Get My Free Renders", variant: .cta, icon: "arrow.right.circle.fill") {
                onContinue()
            }
            .accessibilityIdentifier("howItWorks.continue")

            HStack(spacing: theme.space8) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(theme.primary)
                Text("Free to try • No credit card required")
                    .font(theme.micro.weight(.black))
                    .tracking(1.0)
                    .textCase(.uppercase)
                    .foregroundStyle(Color(hex: "64748B"))
            }
        }
        .padding(.horizontal, theme.space24)
        .padding(.top, theme.space16)
        .padding(.bottom, theme.space20)
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
                .foregroundStyle(Color(hex: "334155"))
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
