import SwiftUI

struct WelcomeView: View {
    @Environment(Theme.self) private var theme
    @Environment(AppState.self) private var appState
    @State private var isVisible = false
    @State private var showLearnMore = false

    var body: some View {
        ZStack {
            // Hero background image
            Image("WelcomeHero")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()

            // Gradient overlay for text legibility
            LinearGradient(
                colors: [
                    Color.black.opacity(0.15),
                    Color.black.opacity(0.05),
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.7),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: theme.spacingLG) {
                Spacer()

                // Branding badge
                Text("Crain Painting")
                    .font(theme.subhead)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.primary)
                    .padding(.horizontal, theme.spacingLG)
                    .padding(.vertical, theme.spacingSM)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radiusSM))

                // Tagline
                Text("Trusted Craftsmanship Since 1952")
                    .font(theme.caption)
                    .foregroundStyle(.white.opacity(0.85))

                // Headline
                Text("Visualize your\nperfect space")
                    .font(theme.largeTitle)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                // Subheading
                Text("See exactly how your room will look with professional paint colors, powered by AI visualization.")
                    .font(theme.body)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, theme.spacingXL)

                VStack(spacing: theme.spacingMD) {
                    AppButton("Get Started", variant: .cta) {
                        withAnimation { appState.onboardingComplete = true }
                    }
                    .accessibilityIdentifier("welcome.getStarted")
                    AppButton("Learn More", variant: .outline, icon: "info.circle") {
                        showLearnMore = true
                    }
                    .accessibilityIdentifier("welcome.learnMore")
                }
                .padding(.horizontal, theme.spacingLG)

                // Security badge
                HStack(spacing: theme.spacingXS) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("Secure & Trusted Family Business")
                        .font(theme.micro)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.bottom, theme.spacingXL)
            }
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6)) {
                isVisible = true
            }
        }
        .fullScreenCover(isPresented: $showLearnMore) {
            HowItWorksView(
                onBack: {
                    showLearnMore = false
                },
                onContinue: {
                    showLearnMore = false
                    withAnimation { appState.onboardingComplete = true }
                }
            )
            .environment(theme)
            .environment(appState)
        }
    }
}
