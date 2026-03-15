import SwiftUI

struct MasterReportView: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @Environment(FavoritesViewModel.self) private var favoritesVM
    @Environment(ReportsViewModel.self) private var reportsVM

    let reportId: String

    @State private var showSavedToast = false
    @State private var toastMessage = "Added to favorites"

    private var report: MasterReport? {
        reportsVM.report(for: reportId)
    }

    var body: some View {
        Group {
            if let report {
                ScrollView {
                    VStack(alignment: .leading, spacing: theme.space24) {
                        profileHeader(report: report)

                        statusCard(report: report)

                        if report.status.isReady {
                            videoSection(report: report)

                            if !report.recommendations.isEmpty {
                                sectionHeader

                                VStack(spacing: theme.spacingMD) {
                                    ForEach(report.recommendations) { recommendation in
                                        RecommendationCard(
                                            recommendation: recommendation,
                                            isFavorite: favoritesVM.isFavorite(recommendation.suggestedColor),
                                            onToggleFavorite: {
                                                let added = favoritesVM.addFavorite(recommendation.suggestedColor)
                                                if !added {
                                                    _ = favoritesVM.removeFavorite(recommendation.suggestedColor)
                                                }
                                                toastMessage = added ? "Added to favorites" : "Removed from favorites"
                                                showSavedToast = true
                                            }
                                        )
                                    }
                                }
                            }
                        } else {
                            reportPendingState(report)
                        }
                    }
                    .padding(.horizontal, theme.spacingMD)
                    .padding(.top, theme.space16)
                    .padding(.bottom, theme.spacing2XL)
                }
                .background(theme.background)
            } else {
                ContentUnavailableView("Report unavailable", systemImage: "doc.text.magnifyingglass")
            }
        }
        .navigationTitle("Master Report")
        .navigationBarTitleDisplayMode(.inline)
        .toast(isPresented: $showSavedToast, message: toastMessage, icon: "heart.fill")
        .task(id: reportId) {
            await reportsVM.refreshReport(orderID: reportId)
        }
    }

    private func statusCard(report: MasterReport) -> some View {
        HStack(alignment: .top, spacing: theme.spacingSM) {
            Circle()
                .fill(theme.primary.opacity(0.12))
                .frame(width: 42, height: 42)
                .overlay(
                    Image(systemName: statusIcon(for: report.status))
                        .foregroundStyle(theme.primary)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(statusTitle(for: report.status))
                    .font(theme.subhead)
                    .fontWeight(.semibold)
                Text(report.statusMessage ?? fallbackStatusBody(for: report.status))
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(theme.spacingMD)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusLG)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
    }

    private func reportPendingState(_ report: MasterReport) -> some View {
        VStack(alignment: .leading, spacing: theme.spacingMD) {
            if report.status.isGenerating {
                ProgressView()
                    .tint(theme.primary)
                Text("Your consultation is still being prepared. This screen will update as soon as recommendations are ready.")
                    .font(theme.bodySmall)
                    .foregroundStyle(theme.mutedForeground)
            } else {
                Text("We couldn't finish this report yet. Please try again later or contact support if the issue continues.")
                    .font(theme.bodySmall)
                    .foregroundStyle(theme.mutedForeground)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacingMD)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusLG)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Profile Header

    private func profileHeader(report: MasterReport) -> some View {
        VStack(alignment: .leading, spacing: theme.spacingSM) {
            HStack(spacing: theme.spacingSM) {
                // Avatar
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
                    Text("MASTER REPORT")
                        .font(theme.micro)
                        .fontWeight(.bold)
                        .tracking(1)
                        .foregroundStyle(theme.primary)
                    Text(report.title)
                        .font(theme.editorialTitle)
                    Text(report.curatorSubtitle.uppercased())
                        .font(theme.micro)
                        .tracking(0.8)
                        .foregroundStyle(theme.primary)
                }

                Spacer()

                ShareLink(item: shareText(for: report)) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.foreground)
                        .frame(width: 44, height: 44)
                        .background(theme.muted)
                        .clipShape(Circle())
                }
            }

            HStack {
                AppBadge(text: "\(report.recommendations.count) ROOMS READY", isFilled: true)
                Spacer()
                Text(report.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
            }

            Rectangle()
                .fill(theme.borderSubtle)
                .frame(height: 1)
        }
    }

    // MARK: - Video Section

    private func videoSection(report: MasterReport) -> some View {
        VStack(alignment: .leading, spacing: theme.spacingSM) {
            Text("Your Personalized Video")
                .font(theme.editorialSubtitle)

            Button {
                router.navigate(to: .sampleOutput(reportId: report.id, chapterId: "living-room"))
            } label: {
                Color.clear
                    .aspectRatio(16.0 / 9.0, contentMode: .fit)
                    .overlay {
                        // Background
                        Group {
                            if let thumbName = report.videoThumbnailName {
                                Image(thumbName)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                LinearGradient(
                                    colors: [
                                        Color(hex: "4A7C8A"),
                                        Color(hex: "2B5264"),
                                        Color(hex: "1A3140")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            }
                        }
                    }
                    .overlay {
                        // Dark scrim
                        LinearGradient(
                            colors: [.black.opacity(0.1), .black.opacity(0.45)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .overlay {
                        // Content
                        VStack(spacing: theme.spacingSM) {
                            // Frosted play button
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 64, height: 64)
                                Circle()
                                    .stroke(.white.opacity(0.4), lineWidth: 1.5)
                                    .frame(width: 64, height: 64)
                                Image(systemName: "play.fill")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(.white)
                            }

                            Text(report.videoTitle)
                                .font(theme.heading3)
                                .foregroundStyle(.white)

                            // Duration capsule
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                Text(timeText(report.videoDuration))
                                    .font(theme.captionSmall)
                            }
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.white.opacity(0.15))
                            .clipShape(Capsule())
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityIdentifier("masterReport.videoButton")
        }
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        VStack(alignment: .leading, spacing: theme.spacingXS) {
            Text("Recommended Rooms")
                .font(theme.editorialSubtitle)
            Text("Save any color directly to favorites")
                .font(theme.caption)
                .foregroundStyle(theme.mutedForeground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func timeText(_ duration: TimeInterval) -> String {
        let total = Int(duration.rounded())
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d Walkthrough", mins, secs)
    }

    private func shareText(for report: MasterReport) -> String {
        "Review my Crain Paint Visualizer report: \(report.title) with \(report.recommendations.count) curated room recommendation\(report.recommendations.count == 1 ? "" : "s")."
    }

    private func statusTitle(for status: ReportStatus) -> String {
        switch status {
        case .generating:
            return "Report in progress"
        case .ready:
            return "Report ready"
        case .failed:
            return "Report needs attention"
        }
    }

    private func statusIcon(for status: ReportStatus) -> String {
        switch status {
        case .generating:
            return "clock.fill"
        case .ready:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }

    private func fallbackStatusBody(for status: ReportStatus) -> String {
        switch status {
        case .generating:
            return "Curt's team is reviewing your room and preparing recommendations."
        case .ready:
            return "Your report is ready to review and save from this screen."
        case .failed:
            return "We hit a snag while generating this report."
        }
    }
}

// MARK: - Recommendation Card

private struct RecommendationCard: View {
    @Environment(Theme.self) private var theme

    let recommendation: RoomRecommendation
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    @State private var fullscreenImage: FullscreenTarget?

    private struct FullscreenTarget: Identifiable {
        let id = UUID()
        let image: Image
        let title: String
        var assetName: String?
    }

    var body: some View {
        AppCard(elevation: .raised) {
            VStack(alignment: .leading, spacing: theme.spacingMD) {
                // Room name
                Text(recommendation.roomName)
                    .font(theme.heading2)

                // Before / After images
                HStack(spacing: theme.spacingSM) {
                    roomPreview(
                        label: recommendation.beforeTitle,
                        imageName: recommendation.beforeImageName,
                        isAfter: false
                    )
                    roomPreview(
                        label: recommendation.afterTitle,
                        imageName: recommendation.afterImageName,
                        isAfter: true
                    )
                }

                // Color info row
                HStack(spacing: theme.spacingSM) {
                    Circle()
                        .fill(recommendation.suggestedColor.color)
                        .frame(width: 56, height: 56)
                        .shadow(
                            color: recommendation.suggestedColor.color.opacity(0.35),
                            radius: 6,
                            y: 3
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(recommendation.suggestedColor.name)
                            .font(theme.heading3)
                        Text("\(recommendation.suggestedColor.brand.displayName) / \(recommendation.suggestedColor.number)")
                            .font(theme.captionSmall)
                            .foregroundStyle(theme.mutedForeground)
                    }

                    Spacer()

                    Button(action: onToggleFavorite) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(isFavorite ? Color.red : theme.mutedForeground)
                            .frame(width: 44, height: 44)
                            .background(theme.muted)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isFavorite ? "Remove saved color" : "Save color")
                }

                // Expert rationale blockquote
                HStack(alignment: .top, spacing: theme.spacingSM) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(theme.primary)
                        .frame(width: 3)

                    Text("\"\(recommendation.rationale)\"")
                        .font(theme.editorialQuote)
                        .foregroundStyle(theme.mutedForeground)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(theme.spacingSM)
                .background(theme.muted.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: theme.radiusSM))
            }
            .padding(theme.spacingMD)
        }
        .fullScreenCover(item: $fullscreenImage) { target in
            FullscreenImageViewer(
                image: target.image,
                title: target.title,
                assetName: target.assetName
            )
        }
    }

    private func roomPreview(label: String, imageName: String?, isAfter: Bool) -> some View {
        Button {
            guard let imageName else { return }
            fullscreenImage = FullscreenTarget(
                image: Image(imageName),
                title: "\(recommendation.roomName) - \(label)",
                assetName: imageName
            )
        } label: {
            ZStack(alignment: .topLeading) {
                Color.clear
                    .aspectRatio(4.0 / 3.0, contentMode: .fit)
                    .overlay {
                        Group {
                            if let imageName {
                                Image(imageName)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                ZStack {
                                    LinearGradient(
                                        colors: isAfter
                                            ? [recommendation.suggestedColor.color.opacity(0.2), recommendation.suggestedColor.color.opacity(0.08)]
                                            : [Color(hex: "C4B8AB"), Color(hex: "A89B8E")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    Image(systemName: isAfter ? "sofa.fill" : "photo")
                                        .font(.system(size: 24, weight: .light))
                                        .foregroundStyle(isAfter ? recommendation.suggestedColor.color.opacity(0.4) : .white.opacity(0.5))
                                }
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))

                AppBadge(text: label.uppercased(), isFilled: isAfter)
                    .padding(8)
                    .allowsHitTesting(false)
            }
        }
        .buttonStyle(.plain)
        .disabled(imageName == nil)
    }
}
