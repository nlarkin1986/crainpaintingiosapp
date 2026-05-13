import SwiftUI

struct WelcomeView: View {
    @Environment(Theme.self) private var theme
    @Environment(AppState.self) private var appState
    @State private var showLearnMore = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: theme.spacingLG) {
                hero
                valueStack
                trustBlock
                actions
            }
            .padding(.horizontal, theme.spacingLG)
            .padding(.top, theme.spacingMD)
            .padding(.bottom, theme.spacingXL)
        }
        .background(ColorTokens.backgroundPrimary.ignoresSafeArea())
        .fullScreenCover(isPresented: $showLearnMore) {
            HowItWorksView(
                onBack: { showLearnMore = false },
                onContinue: {
                    showLearnMore = false
                    withAnimation { appState.onboardingComplete = true }
                }
            )
            .environment(theme)
            .environment(appState)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: theme.spacingMD) {
            ZStack(alignment: .bottomLeading) {
                Image("WelcomeHero")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 340)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
                    .overlay(
                        LinearGradient(
                            colors: [.black.opacity(0.08), .black.opacity(0.52)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
                    )

                VStack(alignment: .leading, spacing: theme.spacingSM) {
                    Text("Crain Painting")
                        .font(theme.micro)
                        .fontWeight(.bold)
                        .tracking(1.3)
                        .textCase(.uppercase)
                        .foregroundStyle(.white.opacity(0.82))

                    Text("Photograph a room. Preview real paint.")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(3)
                        .minimumScaleFactor(0.82)

                    Label("Contractor-backed color guidance since 1952", systemImage: "checkmark.shield.fill")
                        .font(theme.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(theme.spacingLG)
            }
            .accessibilityLabel("Room photo with paint visualization preview")

            Text("Use your own room photo, choose Benjamin Moore or Sherwin-Williams colors, and generate realistic AI paint studies before you commit.")
                .font(theme.body)
                .foregroundStyle(theme.mutedForeground)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var valueStack: some View {
        VStack(spacing: theme.spacingSM) {
            WelcomeCapability(icon: "camera.fill", title: "Camera-first flow", detail: "Capture or upload a room photo in one step.")
            WelcomeCapability(icon: "paintpalette.fill", title: "Real paint libraries", detail: "Browse, search, match, and favorite trusted colors.")
            WelcomeCapability(icon: "sparkles", title: "5 free AI renders", detail: "Only completed visualizations count. Failed renders do not.")
        }
    }

    private var trustBlock: some View {
        HStack(alignment: .top, spacing: theme.spacingMD) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(theme.primary)
                .frame(width: 44, height: 44)
                .background(theme.primary.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Need a second opinion?")
                    .font(theme.subhead)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.foreground)
                Text("Turn a saved result into optional expert guidance from Crain without blocking the free color tools.")
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
            }
        }
        .padding(theme.spacingMD)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusLG)
                .stroke(theme.border, lineWidth: 1)
        )
    }

    private var actions: some View {
        VStack(spacing: theme.spacingSM) {
            AppButton("Start Visualizing", variant: .cta, icon: "camera.fill") {
                withAnimation(.spring(response: 0.35)) {
                    appState.onboardingComplete = true
                }
            }
            .accessibilityIdentifier("welcome.getStarted")

            Button {
                showLearnMore = true
            } label: {
                Label("How it works", systemImage: "info.circle")
                    .font(theme.subhead)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .accessibilityIdentifier("welcome.learnMore")
        }
    }
}

private struct WelcomeCapability: View {
    @Environment(Theme.self) private var theme
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: theme.spacingMD) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.primary)
                .frame(width: 42, height: 42)
                .background(theme.primary.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(theme.subhead)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.foreground)
                Text(detail)
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(theme.spacingMD)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusLG)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
    }
}
