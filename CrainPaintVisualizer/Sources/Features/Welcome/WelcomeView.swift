import SwiftUI

struct WelcomeView: View {
    @Environment(Theme.self) private var theme
    @Environment(AppState.self) private var appState
    @State private var isVisible = false
    @State private var showLearnMore = false

    var body: some View {
        ZStack {
            // Hero background gradient (no image asset needed)
            LinearGradient(
                colors: [theme.background, theme.accentSubtle.opacity(0.3), theme.background],
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
                    .background(theme.card.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: theme.radiusSM))

                // Tagline
                Text("Trusted Craftsmanship Since 1952")
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)

                // Headline
                Text("Visualize your\nperfect space")
                    .font(theme.largeTitle)
                    .foregroundStyle(theme.foreground)
                    .multilineTextAlignment(.center)

                // Subheading
                Text("See exactly how your room will look with professional paint colors, powered by AI visualization.")
                    .font(theme.body)
                    .foregroundStyle(theme.mutedForeground)
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
                }
                .padding(.horizontal, theme.spacingLG)

                // Security badge
                HStack(spacing: theme.spacingXS) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 12))
                        .foregroundStyle(theme.primary)
                    Text("Secure & Trusted Family Business")
                        .font(theme.micro)
                        .foregroundStyle(theme.mutedForeground)
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
        .sheet(isPresented: $showLearnMore) {
            WelcomeDetailsSheet {
                showLearnMore = false
                withAnimation { appState.onboardingComplete = true }
            }
            .presentationDetents([.medium])
        }
    }
}

private struct WelcomeDetailsSheet: View {
    @Environment(Theme.self) private var theme
    @Environment(\.dismiss) private var dismiss

    let continueAction: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacingMD) {
                    Text("How It Works")
                        .font(theme.title)
                        .foregroundStyle(theme.foreground)

                    detailRow(icon: "paintpalette.fill", title: "Choose real paint colors", subtitle: "Browse Benjamin Moore, Sherwin-Williams, and Behr selections.")
                    detailRow(icon: "camera.fill", title: "Upload your room", subtitle: "Start with a live photo so the preview matches your actual space.")
                    detailRow(icon: "person.crop.circle.fill", title: "Request Curt's report", subtitle: "Turn a favorite result into an expert recommendation and consultation.")
                }
                .padding(theme.spacingLG)
            }
            .background(theme.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .bottomBar) {
                    AppButton("Continue", variant: .cta) {
                        continueAction()
                    }
                }
            }
        }
    }

    private func detailRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: theme.spacingSM) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .foregroundStyle(theme.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(theme.subhead)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.foreground)
                Text(subtitle)
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
            }
        }
    }
}
