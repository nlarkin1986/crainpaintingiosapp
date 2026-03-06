import SwiftUI

struct WelcomeView: View {
    @Environment(Theme.self) private var theme
    @Environment(AppState.self) private var appState
    @State private var isVisible = false

    var body: some View {
        ZStack {
            // Hero background
            Image("hero-living-room")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.6), .black.opacity(0)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .ignoresSafeArea()
                )

            VStack(spacing: theme.spacingLG) {
                Spacer()

                // Branding badge
                Text("Aura Finishes")
                    .font(theme.micro)
                    .foregroundStyle(.white)
                    .padding(.horizontal, theme.spacingMD)
                    .padding(.vertical, theme.spacingSM)
                    .background(.white.opacity(0.2))
                    .clipShape(Capsule())

                // Tagline
                Text("Trusted Craftsmanship Since 1952")
                    .font(theme.caption)
                    .foregroundStyle(.white.opacity(0.8))

                // Headline
                Text("Visualize your\nperfect space")
                    .font(theme.largeTitle)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                // Subheading
                Text("See exactly how your room will look with professional paint colors, powered by AI visualization.")
                    .font(theme.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, theme.spacingXL)

                VStack(spacing: theme.spacingSM) {
                    AppButton("Get Started", variant: .cta) {
                        withAnimation { appState.onboardingComplete = true }
                    }
                    AppButton("Sign In", variant: .outline) {
                        // TODO: Sign in flow
                    }
                }
                .padding(.horizontal, theme.spacingLG)

                // Security badge
                HStack(spacing: theme.spacingXS) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 12))
                    Text("Secure & Trusted Family Business")
                        .font(theme.micro)
                }
                .foregroundStyle(.white.opacity(0.6))
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
    }
}
