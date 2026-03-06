import SwiftUI

struct ExpertHomeView: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @Environment(ReportsViewModel.self) private var reportsVM

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacingLG) {
                profileCard

                VStack(alignment: .leading, spacing: theme.spacingSM) {
                    Text("What you get")
                        .font(theme.headline)
                    benefitRow(icon: "sparkles", text: "Personalized room-by-room color strategy")
                    benefitRow(icon: "video", text: "Recorded walkthrough from Curt Crain")
                    benefitRow(icon: "sun.max", text: "Lighting-aware recommendations")
                }

                VStack(spacing: theme.spacingSM) {
                    AppButton("Watch Sample Walkthrough", variant: .outline, icon: "play.fill") {
                        let report = reportsVM.readyReports.first ?? reportsVM.createReport(from: nil)
                        router.navigate(to: .sampleOutput(reportId: report.id, chapterId: "living-room"))
                    }
                    AppButton("Book Consultation", variant: .cta, icon: "arrow.right") {
                        let report = reportsVM.readyReports.first ?? reportsVM.createReport(from: nil)
                        router.navigate(to: .consultationCheckout(reportId: report.id))
                    }
                }
            }
            .padding(theme.spacingMD)
        }
        .navigationTitle("Expert")
        .navigationBarTitleDisplayMode(.large)
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: theme.spacingMD) {
            HStack(spacing: theme.spacingMD) {
                Circle()
                    .fill(theme.primary.opacity(0.1))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(theme.primary)
                    )
                    .overlay(
                        Circle()
                            .stroke(theme.primary, lineWidth: 2.5)
                    )
                VStack(alignment: .leading, spacing: 4) {
                    Text("Curt Crain")
                        .font(theme.title)
                    HStack(spacing: 6) {
                        AppBadge(text: "20+ Years", isFilled: true)
                        AppBadge(text: "Fine Artist", isFilled: false)
                    }
                    HStack(spacing: 4) {
                        HStack(spacing: 1) {
                            ForEach(0..<5, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.orange)
                            }
                        }
                        Text("120+ consultations")
                            .font(theme.micro)
                            .foregroundStyle(theme.mutedForeground)
                    }
                }
            }

            Text("Get a guided consultation with practical color choices that hold up in your lighting, layout, and furniture context.")
                .font(theme.body)
                .foregroundStyle(theme.foreground)

            HStack(spacing: 0) {
                Text("\u{201C}Curt's recommendations completely transformed our living room. His eye for color in different lighting was invaluable.\u{201D}")
                    .font(theme.caption)
                    .italic()
                    .foregroundStyle(theme.mutedForeground)
            }
            .padding(theme.spacingSM)
            .background(theme.muted)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusSM))
        }
        .padding(theme.spacingMD)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusXL)
                .stroke(theme.border, lineWidth: 1)
        )
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: theme.spacingSM) {
            Image(systemName: icon)
                .foregroundStyle(theme.primary)
                .frame(width: 22)
            Text(text)
                .font(theme.subhead)
                .foregroundStyle(theme.foreground)
            Spacer()
        }
    }
}
