import SwiftUI

struct ReportsHomeView: View {
    @Environment(Theme.self) private var theme
    @Environment(AppState.self) private var appState
    @Environment(RouterPath.self) private var router
    @Environment(TabRouter.self) private var tabRouter
    @Environment(ReportsViewModel.self) private var reportsVM

    private var featuredReport: MasterReport? {
        reportsVM.readyReports.first
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: theme.space20) {
                CompactScreenHeader(
                    title: "Reports",
                    subtitle: reportsVM.readyReports.isEmpty
                        ? "Your personalized walkthroughs will appear here."
                        : "Open your latest walkthrough or revisit past reports.",
                    detail: reportsVM.readyReports.isEmpty ? "0 ready" : "\(reportsVM.readyReports.count) ready"
                )

                if let featuredReport {
                    featuredReportCard(featuredReport)

                    HStack {
                        Text("Recent Reports")
                            .font(theme.heading2)
                            .foregroundStyle(theme.foreground)
                        Spacer()
                        AppBadge(text: "\(reportsVM.readyReports.count) READY", isFilled: true)
                    }
                    .padding(.horizontal, theme.spacingMD)

                    VStack(spacing: theme.space12) {
                        ForEach(reportsVM.readyReports) { report in
                            ReportCard(report: report) {
                                router.navigate(to: .masterReport(reportId: report.id))
                            }
                        }
                    }
                    .padding(.horizontal, theme.spacingMD)
                } else {
                    emptyState
                }

                expertUpsell
            }
            .padding(.bottom, theme.spacingXL)
        }
        .background(theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func featuredReportCard(_ report: MasterReport) -> some View {
        Button {
            router.navigate(to: .masterReport(reportId: report.id))
        } label: {
            VStack(alignment: .leading, spacing: theme.space16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Latest Report")
                            .font(theme.micro)
                            .fontWeight(.bold)
                            .tracking(1)
                            .foregroundStyle(theme.primary)
                        Text(report.title)
                            .font(theme.heading1)
                            .foregroundStyle(theme.foreground)
                        Text(report.curatorSubtitle)
                            .font(theme.caption)
                            .foregroundStyle(theme.mutedForeground)
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(theme.foreground)
                        .frame(width: 40, height: 40)
                        .background(theme.card.opacity(0.9))
                        .clipShape(Circle())
                }

                reportHeroImage(report)
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))

                HStack(spacing: theme.space12) {
                    ZStack {
                        Circle()
                            .fill(theme.primary.opacity(0.12))
                            .frame(width: 52, height: 52)
                        Image(systemName: "play.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(theme.primary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(report.videoTitle)
                            .font(theme.heading3)
                            .foregroundStyle(theme.foreground)
                        Text("\(report.recommendations.count) room recommendations")
                            .font(theme.caption)
                            .foregroundStyle(theme.mutedForeground)
                    }
                }

                ViewThatFits(in: .vertical) {
                    HStack {
                        metaPill(icon: "sparkles", text: "Lighting-aware analysis")
                        metaPill(icon: "video.fill", text: timeText(report.videoDuration))
                    }
                    VStack(alignment: .leading, spacing: theme.space8) {
                        metaPill(icon: "sparkles", text: "Lighting-aware analysis")
                        metaPill(icon: "video.fill", text: timeText(report.videoDuration))
                    }
                }
            }
            .padding(theme.space16)
            .background(theme.card)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radiusXL)
                    .stroke(theme.borderSubtle, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 18, y: 8)
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, theme.spacingMD)
    }

    private var emptyState: some View {
        VStack(spacing: theme.space16) {
            Circle()
                .fill(theme.primary.opacity(0.1))
                .frame(width: 72, height: 72)
                .overlay(
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(theme.primary)
                )

            VStack(spacing: theme.space8) {
                Text("No reports yet")
                    .font(theme.heading2)
                Text("Generate a visualization first, then come back here for a personalized walkthrough and room recommendations.")
                    .font(theme.bodySmall)
                    .foregroundStyle(theme.mutedForeground)
                    .multilineTextAlignment(.center)
            }

            AppButton("Go To Visualize", variant: .outline, icon: "wand.and.stars") {
                tabRouter.openVisualizer(appState: appState)
            }
        }
        .padding(theme.space24)
        .frame(maxWidth: .infinity)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusXL)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
        .padding(.horizontal, theme.spacingMD)
    }

    private var expertUpsell: some View {
        AppCard(elevation: .raised) {
            VStack(alignment: .leading, spacing: theme.space12) {
                Text("Need more visual options?")
                    .font(theme.heading2)
                    .foregroundStyle(theme.foreground)

                Text("Open the preview gallery to compare more color options, then bring the strongest choices back into your report flow.")
                    .font(theme.bodySmall)
                    .foregroundStyle(theme.mutedForeground)

                AppButton("Open Visualization Gallery", variant: .outline, icon: "photo.on.rectangle.angled") {
                    tabRouter.openResultsGallery(appState: appState)
                }
            }
            .padding(theme.space16)
        }
        .padding(.horizontal, theme.spacingMD)
    }

    private func metaPill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(theme.captionSmall)
                .fontWeight(.semibold)
        }
        .foregroundStyle(theme.foreground)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(theme.secondary)
        .clipShape(Capsule())
    }

    private func reportHeroImage(_ report: MasterReport) -> some View {
        Group {
            if let thumbnail = report.videoThumbnailName {
                Image(thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [Color(hex: "77919A"), Color(hex: "385869")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    private func timeText(_ duration: TimeInterval) -> String {
        let total = Int(duration.rounded())
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d walkthrough", mins, secs)
    }
}

private struct ReportCard: View {
    @Environment(Theme.self) private var theme
    let report: MasterReport
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: theme.space12) {
                Group {
                    if let thumbnail = report.videoThumbnailName {
                        Image(thumbnail)
                            .resizable()
                            .scaledToFill()
                    } else {
                        LinearGradient(
                            colors: [Color(hex: "839DA5"), Color(hex: "486674")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
                .frame(width: 88, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))

                VStack(alignment: .leading, spacing: 6) {
                    Text(report.title)
                        .font(theme.heading3)
                        .foregroundStyle(theme.foreground)

                    Text(report.curatorSubtitle.uppercased())
                        .font(theme.micro)
                        .tracking(0.9)
                        .foregroundStyle(theme.primary)

                    Text("\(report.recommendations.count) room recommendations")
                        .font(theme.caption)
                        .foregroundStyle(theme.mutedForeground)

                    Text(report.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(theme.captionSmall)
                        .foregroundStyle(theme.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.mutedForeground)
            }
            .padding(theme.space12)
            .background(theme.card)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radiusXL)
                    .stroke(theme.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
