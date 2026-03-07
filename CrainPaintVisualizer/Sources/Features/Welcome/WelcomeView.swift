import SwiftUI

struct WelcomeView: View {
    @Environment(Theme.self) private var theme
    @Environment(AppState.self) private var appState
    @State private var isVisible = false
    @State private var showLearnMore = false
    @State private var animate = false

    var body: some View {
        ZStack {
            // Clean gradient background (Airbnb style)
            LinearGradient(
                colors: [
                    Color(hex: "FAFBFC"),
                    ColorTokens.aquaSubtle.opacity(0.3),
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Decorative elements
            GeometryReader { geometry in
                // Floating aqua circle - top right
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ColorTokens.aquaLight.opacity(0.2), ColorTokens.aqua.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: geometry.size.width - 100, y: -150)
                    .scaleEffect(animate ? 1.1 : 1.0)
                
                // Floating yellow circle - bottom left
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ColorTokens.sunshineLight.opacity(0.3), ColorTokens.sunshine.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .offset(x: -80, y: geometry.size.height - 100)
                    .scaleEffect(animate ? 1.15 : 1.0)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: theme.space32) {
                    Spacer(minLength: 60)

                    // Premium logo/icon area
                    VStack(spacing: theme.space20) {
                        // Animated paint brush icon with gradient
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [ColorTokens.aqua, ColorTokens.aquaDark],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 88, height: 88)
                                .shadow(color: ColorTokens.aqua.opacity(0.3), radius: 20, y: 10)
                            
                            Image(systemName: "paintbrush.pointed.fill")
                                .font(.system(size: 38, weight: .semibold))
                                .foregroundStyle(.white)
                                .rotationEffect(.degrees(-45))
                        }
                        .scaleEffect(isVisible ? 1.0 : 0.8)
                        .rotationEffect(.degrees(isVisible ? 0 : -180))

                        // Branding
                        VStack(spacing: theme.space8) {
                            Text("Crain Painting")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(ColorTokens.inkPrimary)
                            
                            HStack(spacing: theme.space8) {
                                Rectangle()
                                    .fill(ColorTokens.sunshine)
                                    .frame(width: 24, height: 2)
                                
                                Text("Est. 1952")
                                    .font(.system(size: 13, weight: .semibold))
                                    .tracking(2)
                                    .foregroundStyle(ColorTokens.inkSecondary)
                                
                                Rectangle()
                                    .fill(ColorTokens.sunshine)
                                    .frame(width: 24, height: 2)
                            }
                        }
                    }
                    .padding(.top, theme.space24)

                    // Headline with better typography
                    VStack(spacing: theme.space16) {
                        Text("Visualize Your\nPerfect Space")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(ColorTokens.inkPrimary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)

                        Text("See exactly how your room will look with professional paint colors, powered by AI visualization.")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(ColorTokens.inkSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .padding(.horizontal, theme.space32)
                    }

                    // Feature highlights
                    VStack(spacing: theme.space12) {
                        FeaturePill(
                            icon: "wand.and.stars",
                            text: "AI-Powered Visualization",
                            color: ColorTokens.aqua
                        )
                        FeaturePill(
                            icon: "photo.on.rectangle.angled",
                            text: "Real-Time Preview",
                            color: ColorTokens.sunshine
                        )
                        FeaturePill(
                            icon: "person.badge.shield.checkmark",
                            text: "Expert Guidance",
                            color: ColorTokens.feedbackSuccess
                        )
                    }
                    .padding(.horizontal, theme.space32)

                    // CTA buttons
                    VStack(spacing: theme.space16) {
                        AppButton("Get Started", variant: .cta, icon: "arrow.right") {
                            withAnimation(.spring(response: 0.5)) {
                                appState.onboardingComplete = true
                            }
                        }
                        .accessibilityIdentifier("welcome.getStarted")
                        
                        Button {
                            showLearnMore = true
                        } label: {
                            HStack(spacing: theme.space8) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Learn More")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundStyle(ColorTokens.aquaDark)
                        }
                        .accessibilityIdentifier("welcome.learnMore")
                    }
                    .padding(.horizontal, theme.space24)

                    // Trust badge
                    HStack(spacing: theme.space12) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(ColorTokens.feedbackSuccess)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Family-Owned & Trusted")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(ColorTokens.inkPrimary)
                            Text("Serving our community for 70+ years")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(ColorTokens.inkSecondary)
                        }
                    }
                    .padding(.horizontal, theme.space20)
                    .padding(.vertical, theme.space16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                    .padding(.horizontal, theme.space24)

                    Spacer(minLength: 40)
                }
            }
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 30)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                isVisible = true
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                animate = true
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
// MARK: - Feature Pill Component

private struct FeaturePill: View {
    @Environment(Theme.self) private var theme
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: theme.space12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(ColorTokens.inkPrimary)
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, theme.space16)
        .padding(.vertical, theme.space12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

