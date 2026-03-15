import SwiftUI
import UIKit

struct MoreHomeView: View {
    @Environment(Theme.self) private var theme
    @Environment(AppState.self) private var appState
    @Environment(TabRouter.self) private var tabRouter
    @Environment(RouterPath.self) private var router
    @Environment(ReportsViewModel.self) private var reportsVM
    @Environment(VisualizerViewModel.self) private var visualizerVM

    @State private var showHowItWorks = false

    private let consultationService = DefaultConsultationService()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: theme.space20) {
                CompactScreenHeader(
                    title: "More",
                    subtitle: "Consultation, help, and device settings stay here so Preview and Library can stay focused."
                )

                consultationSection
                if let latestReport = reportsVM.reports.first {
                    latestReportSection(latestReport)
                }
                helpSection
                settingsSection
            }
            .padding(.bottom, theme.spacingXL)
        }
        .background(theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showHowItWorks) {
            HowItWorksView(
                onBack: { showHowItWorks = false },
                onContinue: {
                    showHowItWorks = false
                    tabRouter.openPreview(appState: appState, route: .photoUpload)
                }
            )
            .environment(theme)
        }
        .task {
            await reportsVM.refreshReports()
        }
    }

    private var package: ConsultationPackageDetails {
        consultationService.packageDetails(for: .videoConsultation)
    }

    private var consultationFlowState: ConsultationFlowState {
        var flowState = visualizerVM.makeConsultationFlowState(from: visualizerVM.latestVisualization)
        flowState.packageType = package.type
        return flowState
    }

    private var consultationContextTitle: String {
        consultationFlowState.sourceRoomName ?? "Current project"
    }

    private var consultationContextSubtitle: String {
        if let sourceColor = consultationFlowState.sourceColor {
            return "Starting from \(sourceColor.name) so Curt can react to a real color you already tested."
        }
        return "Bring Curt in after your free previews when you want a confident final recommendation."
    }

    private var consultationSection: some View {
        VStack(alignment: .leading, spacing: theme.space16) {
            sectionHeader(
                title: "Consultation",
                body: "Bring Curt in when you want a confident final call after you have tested a few colors."
            )

            AppCard(elevation: .floating) {
                VStack(alignment: .leading, spacing: theme.space16) {
                    Image("WelcomeHero")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))

                    VStack(alignment: .leading, spacing: theme.space8) {
                        AppBadge(text: "Optional add-on", isFilled: true)
                        Text(package.name)
                            .font(theme.heading1)
                            .foregroundStyle(theme.foreground)
                        Text(package.subtitle)
                            .font(theme.bodySmall)
                            .foregroundStyle(theme.mutedForeground)
                        Text(consultationContextTitle)
                            .font(theme.heading3)
                            .foregroundStyle(theme.foreground)
                        Text(consultationContextSubtitle)
                            .font(theme.caption)
                            .foregroundStyle(theme.mutedForeground)
                    }

                    ViewThatFits(in: .vertical) {
                        HStack(spacing: theme.space8) {
                            infoPill(icon: "sparkles", text: package.turnaround)
                            infoPill(icon: "video.fill", text: "Recorded walkthrough")
                            infoPill(icon: "sun.max.fill", text: "Lighting-aware")
                        }
                        VStack(alignment: .leading, spacing: theme.space8) {
                            infoPill(icon: "sparkles", text: package.turnaround)
                            infoPill(icon: "video.fill", text: "Recorded walkthrough")
                            infoPill(icon: "sun.max.fill", text: "Lighting-aware")
                        }
                    }

                    VStack(alignment: .leading, spacing: theme.space8) {
                        ForEach(package.features, id: \.self) { feature in
                            HStack(alignment: .top, spacing: theme.space8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(theme.primary)
                                Text(feature)
                                    .font(theme.bodySmall)
                                    .foregroundStyle(theme.mutedForeground)
                            }
                        }
                    }

                    VStack(spacing: theme.space12) {
                        AppButton("Add Curt's Consultation for \(currency(package.price))", variant: .cta, icon: "arrow.right") {
                            router.navigate(to: .consultationCheckout(flowState: consultationFlowState))
                        }
                        .accessibilityIdentifier("more.consultation.primary")

                        AppButton("Preview Sample Walkthrough", variant: .outline, icon: "play.fill") {
                            router.navigate(to: .sampleOutput(reportId: reportsVM.readyReports.first?.id ?? "sample-walkthrough", chapterId: "living-room"))
                        }
                        .accessibilityIdentifier("more.consultation.sample")
                    }
                }
                .padding(theme.space16)
            }
            .padding(.horizontal, theme.spacingMD)
        }
    }

    private func latestReportSection(_ report: MasterReport) -> some View {
        VStack(alignment: .leading, spacing: theme.space16) {
            sectionHeader(
                title: "Your latest report",
                body: "Finished consultations and in-progress walkthroughs stay close from here."
            )

        Button {
            router.navigate(to: .masterReport(reportId: report.id))
        } label: {
                HStack(spacing: theme.space12) {
                    Group {
                        if let imageName = report.videoThumbnailName {
                            Image(imageName)
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
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: theme.space8) {
                            Text(report.title)
                                .font(theme.heading3)
                                .foregroundStyle(theme.foreground)
                                .lineLimit(2)
                            Spacer(minLength: 0)
                            AppBadge(text: report.status.moreLabel, isFilled: report.status.isReady)
                        }

                        Text(report.statusMessage ?? report.curatorSubtitle)
                            .font(theme.bodySmall)
                            .foregroundStyle(theme.mutedForeground)
                            .lineLimit(3)

                        Label(report.status.isReady ? "Open report" : "Check progress", systemImage: "arrow.up.right")
                            .font(theme.captionSmall.weight(.semibold))
                            .foregroundStyle(theme.primary)
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
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, theme.spacingMD)
        .accessibilityIdentifier("more.latestReportCard")
    }
    }

    private var helpSection: some View {
        VStack(alignment: .leading, spacing: theme.space16) {
            sectionHeader(
                title: "Help & learn",
                body: "Use this area for product guidance and the tools that support a paint decision."
            )

            MoreSectionCard {
                MoreActionRow(
                    title: "How the preview flow works",
                    subtitle: "Revisit the core steps and free-preview promise.",
                    systemImage: "questionmark.circle"
                ) {
                    showHowItWorks = true
                }

                Divider()

                MoreActionRow(
                    title: "Open Color Matcher",
                    subtitle: "Sample a real-world object and start a room from that color.",
                    systemImage: "camera.viewfinder"
                ) {
                    tabRouter.openPreview(appState: appState, route: .colorMatcher)
                }

                Divider()

                MoreActionRow(
                    title: "Start a new room preview",
                    subtitle: "Jump straight into a fresh room and upload the photo first.",
                    systemImage: "sparkles.rectangle.stack"
                ) {
                    visualizerVM.prepareFreshProject()
                    tabRouter.openPreview(appState: appState, route: .photoUpload)
                }

                Divider()

                MoreActionRow(
                    title: "Open the Library",
                    subtitle: "Review saved projects, colors, and reports.",
                    systemImage: "square.stack.3d.up"
                ) {
                    tabRouter.openLibrary(appState: appState)
                }
            }
            .padding(.horizontal, theme.spacingMD)
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: theme.space16) {
            sectionHeader(
                title: "Settings",
                body: "Device permissions and app-level preferences live with the system until deeper settings screens exist."
            )

            MoreSectionCard {
                MoreActionRow(
                    title: "Open iPhone Settings",
                    subtitle: "Manage camera, photos, and notification permissions for the app.",
                    systemImage: "gearshape"
                ) {
                    openSystemSettings()
                }

                Divider()

                MoreActionRow(
                    title: "Preview sample consultation",
                    subtitle: "Watch the add-on sample again before booking expert help.",
                    systemImage: "play.rectangle"
                ) {
                    router.navigate(to: .sampleOutput(reportId: reportsVM.readyReports.first?.id ?? "sample-walkthrough", chapterId: "living-room"))
                }
            }
            .padding(.horizontal, theme.spacingMD)
        }
    }

    private func sectionHeader(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: theme.space4) {
            Text(title)
                .font(theme.heading2)
                .foregroundStyle(theme.foreground)
            Text(body)
                .font(theme.bodySmall)
                .foregroundStyle(theme.mutedForeground)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, theme.spacingMD)
    }

    private func infoPill(icon: String, text: String) -> some View {
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

    private func currency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: value as NSNumber) ?? "$\(value)"
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

private struct MoreSectionCard<Content: View>: View {
    @Environment(Theme.self) private var theme

    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusXL)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
    }
}

private struct MoreActionRow: View {
    @Environment(Theme.self) private var theme

    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: theme.space12) {
                Circle()
                    .fill(theme.primary.opacity(0.12))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: systemImage)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(theme.primary)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(theme.heading3)
                        .foregroundStyle(theme.foreground)
                    Text(subtitle)
                        .font(theme.bodySmall)
                        .foregroundStyle(theme.mutedForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.mutedForeground)
            }
            .padding(theme.space16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private extension ReportStatus {
    var moreLabel: String {
        switch self {
        case .generating:
            return "In Progress"
        case .ready:
            return "Ready"
        case .failed:
            return "Needs Review"
        }
    }
}
