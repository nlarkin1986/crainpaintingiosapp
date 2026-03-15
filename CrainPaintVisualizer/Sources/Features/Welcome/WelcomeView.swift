import SwiftUI

struct WelcomeView: View {
    @Environment(Theme.self) private var theme
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false
    @State private var showLearnMore = false

    var body: some View {
        ZStack {
            Image("WelcomeHero")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.08),
                    Color.black.opacity(0.12),
                    Color.black.opacity(0.48),
                    Color.black.opacity(0.76),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: theme.space24) {
                Spacer()

                AppCard(elevation: .floating) {
                    VStack(alignment: .leading, spacing: theme.space16) {
                        HeroHeader(
                            eyebrow: "Crain Painting",
                            title: "Preview your room before you commit.",
                            subtitle: "Test real paint colors in your own space, then add expert help only if you want the final call.",
                            footnote: "3 free previews. No credit card required."
                        ) {
                            welcomePill(label: "Since 1952", systemImage: "checkmark.shield.fill")
                        }

                        AppButton("Enter the App", variant: .cta) {
                            withAnimation {
                                appState.onboardingComplete = true
                            }
                        }
                        .accessibilityIdentifier("welcome.getStarted")

                        Button {
                            showLearnMore = true
                        } label: {
                            HStack(spacing: theme.space8) {
                                Image(systemName: "info.circle")
                                Text("How it works")
                            }
                            .font(theme.captionSmall.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.9))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("welcome.learnMore")

                        HStack(spacing: theme.space8) {
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 12))
                            Text("Start with previews. Add expert guidance only when you want a final call.")
                                .font(theme.micro)
                        }
                        .foregroundStyle(.white.opacity(0.72))
                    }
                    .padding(theme.spacingLG)
                    .background(.ultraThinMaterial)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radiusLG)
                        .stroke(.white.opacity(0.14), lineWidth: 1)
                )
                .padding(.horizontal, theme.spacingLG)
                .padding(.bottom, theme.spacingLG)
            }
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
        }
        .onAppear {
            if reduceMotion {
                isVisible = true
            } else {
                withAnimation(.spring(response: 0.6)) {
                    isVisible = true
                }
            }
        }
        .sheet(isPresented: $showLearnMore) {
            HowItWorksView(
                onBack: {
                    showLearnMore = false
                },
                onContinue: {
                    showLearnMore = false
                    withAnimation {
                        appState.onboardingComplete = true
                    }
                }
            )
            .environment(theme)
            .environment(appState)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private func welcomePill(label: String, systemImage: String) -> some View {
        HStack(spacing: theme.spacingXS) {
            Image(systemName: systemImage)
            Text(label)
        }
        .font(theme.captionSmall.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, theme.spacingSM)
        .padding(.vertical, theme.space8)
        .background(.white.opacity(0.14))
        .clipShape(Capsule())
    }
}
