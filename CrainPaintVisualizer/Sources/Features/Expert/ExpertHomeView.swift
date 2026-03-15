import SwiftUI

struct ExpertHomeView: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @Environment(ReportsViewModel.self) private var reportsVM
    @Environment(VisualizerViewModel.self) private var visualizerVM

    private let consultationService = DefaultConsultationService()

    private var package: ConsultationPackageDetails {
        consultationService.packageDetails(for: .videoConsultation)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: theme.space20) {
                heroCard
                valueSection
                processSection
                packageCard
            }
            .padding(.horizontal, theme.spacingMD)
            .padding(.top, theme.space16)
            .padding(.bottom, theme.spacingXL)
        }
        .background(theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var heroCard: some View {
        AppCard(elevation: .floating) {
            VStack(alignment: .leading, spacing: 0) {
                Image("WelcomeHero")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .clipped()

                VStack(alignment: .leading, spacing: theme.space16) {
                    HeroHeader(
                        eyebrow: "Optional expert help",
                        title: "Add Curt when you need the final call.",
                        subtitle: "Use the consultation when you want a lighting-aware recommendation and a clear final decision."
                    )

                    HStack(spacing: theme.space8) {
                        heroStat(text: package.turnaround)
                        heroStat(text: "Recorded walkthrough")
                        heroStat(text: "One-time consultation")
                    }

                    VStack(spacing: theme.space12) {
                        AppButton("Add Curt's Consultation for \(currency(package.price))", variant: .cta, icon: "arrow.right") {
                            var flowState = visualizerVM.makeConsultationFlowState(from: visualizerVM.latestVisualization)
                            flowState.packageType = package.type
                            router.navigate(to: .consultationCheckout(flowState: flowState))
                        }
                        .accessibilityIdentifier("expertHome.primaryCTA")

                        AppButton("Preview Curt's Walkthrough", variant: .outline, icon: "play.fill") {
                            router.navigate(to: .sampleOutput(reportId: reportsVM.readyReports.first?.id ?? "sample-walkthrough", chapterId: "living-room"))
                        }
                        .accessibilityIdentifier("expertHome.previewCTA")
                    }
                }
                .padding(theme.space16)
            }
        }
    }

    private var valueSection: some View {
        AppCard(elevation: .raised) {
            VStack(alignment: .leading, spacing: theme.space16) {
                Text("What Curt adds")
                    .font(theme.heading2)
                    .foregroundStyle(theme.foreground)

                benefitRow(icon: "checkmark.seal.fill", title: "A final recommendation on your strongest options", body: "Curt helps you choose between the colors you already tested instead of restarting the process.")
                benefitRow(icon: "video.fill", title: "Recorded walkthrough from Curt", body: "You get a practical video analysis of what is working, what to avoid, and where to take the room next.")
                benefitRow(icon: "sun.max.fill", title: "Lighting-aware judgment", body: "Curt interprets how your room's light, furnishings, and flow change the right answer.")
            }
            .padding(theme.space16)
        }
    }

    private var processSection: some View {
        VStack(alignment: .leading, spacing: theme.space12) {
            Text("How the consultation works")
                .font(theme.heading2)
                .foregroundStyle(theme.foreground)

            VStack(spacing: theme.space12) {
                processRow(step: "01", title: "Shortlist your favorite AI results", body: "Use the visualizer first so Curt can react to the colors you are seriously considering.")
                processRow(step: "02", title: "Curt reviews the room like a decision", body: "You get concise, practical feedback on what to choose, what to avoid, and why.")
                processRow(step: "03", title: "Move forward with more confidence", body: "Use the report and walkthrough when you're ready to buy paint or brief your painter.")
            }
        }
    }

    private var packageCard: some View {
        AppCard(elevation: .raised) {
            VStack(alignment: .leading, spacing: theme.space16) {
                Text(package.name)
                    .font(theme.heading2)
                    .foregroundStyle(theme.foreground)

                HStack(alignment: .firstTextBaseline) {
                    Text("$\(NSDecimalNumber(decimal: package.price).intValue)")
                        .font(theme.friendlyNumber)
                        .foregroundStyle(theme.foreground)
                    Text("/ \(package.turnaround)")
                        .font(theme.caption)
                        .foregroundStyle(theme.mutedForeground)
                }

                ForEach(package.features, id: \.self) { feature in
                    HStack(alignment: .top, spacing: theme.space8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(theme.primary)
                        Text(feature)
                            .font(theme.bodySmall)
                            .foregroundStyle(theme.mutedForeground)
                    }
                }

                AppButton("Add Curt's Consultation for \(currency(package.price))", variant: .cta, icon: "arrow.right") {
                    var flowState = visualizerVM.makeConsultationFlowState(from: visualizerVM.latestVisualization)
                    flowState.packageType = package.type
                    router.navigate(to: .consultationCheckout(flowState: flowState))
                }
                .accessibilityIdentifier("expertHome.packageCTA")
            }
            .padding(theme.space16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func heroStat(text: String) -> some View {
        Text(text)
            .font(theme.captionSmall)
            .fontWeight(.semibold)
            .foregroundStyle(theme.foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(theme.secondary)
            .clipShape(Capsule())
    }

    private func benefitRow(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: theme.space12) {
            Circle()
                .fill(theme.primary.opacity(0.12))
                .frame(width: 42, height: 42)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(theme.primary)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(theme.heading3)
                    .foregroundStyle(theme.foreground)
                Text(body)
                    .font(theme.bodySmall)
                    .foregroundStyle(theme.mutedForeground)
            }
        }
    }

    private func processRow(step: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: theme.space12) {
            Text(step)
                .font(theme.friendlyLabel)
                .foregroundStyle(theme.primary)
                .frame(width: 42, height: 42)
                .background(theme.primary.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(theme.heading3)
                    .foregroundStyle(theme.foreground)
                Text(body)
                    .font(theme.bodySmall)
                    .foregroundStyle(theme.mutedForeground)
            }
        }
        .padding(theme.space16)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusXL)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
    }

    private func currency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: value as NSNumber) ?? "$\(value)"
    }
}
