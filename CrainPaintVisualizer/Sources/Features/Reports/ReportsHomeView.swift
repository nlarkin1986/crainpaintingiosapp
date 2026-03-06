import SwiftUI

struct ReportsHomeView: View {
    @Environment(Theme.self) private var theme
    @Environment(AppState.self) private var appState
    @Environment(RouterPath.self) private var router
    @Environment(TabRouter.self) private var tabRouter
    @Environment(ReportsViewModel.self) private var reportsVM

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacingLG) {
                header
                    .padding(.horizontal, theme.spacingMD)

                if reportsVM.readyReports.isEmpty {
                    emptyState
                        .padding(.horizontal, theme.spacingMD)
                } else {
                    VStack(spacing: theme.spacingMD) {
                        ForEach(reportsVM.readyReports) { report in
                            ReportCard(report: report) {
                                router.navigate(to: .masterReport(reportId: report.id))
                            }
                        }
                    }
                    .padding(.horizontal, theme.spacingMD)
                }

                VStack(alignment: .leading, spacing: theme.spacingSM) {
                    Text("Need more visual options?")
                        .font(theme.subhead)
                        .foregroundStyle(theme.mutedForeground)
                    AppButton("Open Visualization Gallery", variant: .outline, icon: "photo.on.rectangle.angled") {
                        tabRouter.openResultsGallery(appState: appState)
                    }
                }
                .padding(.horizontal, theme.spacingMD)
                .padding(.bottom, theme.spacingLG)
            }
            .padding(.top, theme.spacingMD)
        }
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.large)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: theme.spacingSM) {
            Text("Master Reports")
                .font(theme.title)
            Text("Personalized walkthroughs and room-ready recommendations from Curt Crain.")
                .font(theme.body)
                .foregroundStyle(theme.mutedForeground)
        }
    }

    private var emptyState: some View {
        VStack(spacing: theme.spacingMD) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(theme.primary)
            Text("No reports yet")
                .font(theme.headline)
            Text("Generate a visualization first, then create a personalized report from your results.")
                .font(theme.body)
                .foregroundStyle(theme.mutedForeground)
                .multilineTextAlignment(.center)
            AppButton("Go To Visualize", variant: .primary, icon: "arrow.right") {
                tabRouter.openVisualizer(appState: appState)
            }
        }
        .padding(theme.spacingLG)
        .frame(maxWidth: .infinity)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusLG)
                .stroke(theme.border, lineWidth: 1)
        )
    }
}

private struct ReportCard: View {
    @Environment(Theme.self) private var theme
    let report: MasterReport
    let action: () -> Void

    private var dateText: String {
        report.createdAt.formatted(date: .abbreviated, time: .omitted)
    }

    var body: some View {
        Button(action: action) {
            AppCard(elevation: .raised) {
                VStack(alignment: .leading, spacing: theme.spacingMD) {
                    HStack(spacing: theme.spacingSM) {
                        // Teal gradient avatar with "CC" fallback
                        if let photoName = report.curatorPhotoName {
                            Image(photoName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [theme.actionPrimary, theme.actionPrimaryPressed],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Text("CC")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundStyle(theme.actionPrimaryText)
                                )
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(report.title)
                                .font(theme.editorialSubtitle)
                                .foregroundStyle(theme.foreground)
                            Text(report.curatorSubtitle.uppercased())
                                .font(theme.micro)
                                .tracking(0.8)
                                .foregroundStyle(theme.primary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(theme.mutedForeground)
                    }

                    HStack {
                        AppBadge(text: "\(report.recommendations.count) ROOMS READY", isFilled: true)
                        Spacer()
                        Text(dateText)
                            .font(theme.caption)
                            .foregroundStyle(theme.mutedForeground)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "play.circle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(theme.primary)
                        Text("\(report.videoTitle) • \(timeText(report.videoDuration))")
                            .font(theme.subhead)
                            .foregroundStyle(theme.foreground)
                    }
                }
                .padding(theme.spacingMD)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func timeText(_ duration: TimeInterval) -> String {
        let total = Int(duration.rounded())
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
