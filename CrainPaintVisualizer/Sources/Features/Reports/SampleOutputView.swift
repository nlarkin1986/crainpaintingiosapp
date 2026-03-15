import SwiftUI

struct SampleOutputView: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @Environment(ReportsViewModel.self) private var reportsVM
    @Environment(VisualizerViewModel.self) private var visualizerVM
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let reportId: String
    let chapterId: String?

    @State private var playerVM = VideoPlayerViewModel()

    private let consultationService = DefaultConsultationService()

    private var report: MasterReport? {
        reportsVM.report(for: reportId)
    }

    private var package: ConsultationPackageDetails {
        consultationService.packageDetails(for: .videoConsultation)
    }

    private var consultationFlowState: ConsultationFlowState {
        if let report {
            return ConsultationFlowState(
                sourceProjectID: report.projectID,
                sourceColor: report.recommendations.first?.suggestedColor,
                sourceRoomName: report.recommendations.first?.roomName ?? report.title,
                packageType: package.type
            )
        }

        var flowState = visualizerVM.makeConsultationFlowState(from: visualizerVM.latestVisualization)
        flowState.packageType = package.type
        return flowState
    }

    private var chapterLabel: String {
        let raw = chapterId ?? "living-room"
        return raw.replacingOccurrences(of: "-", with: " ").uppercased()
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundMedia
                screenScrim

                VStack(spacing: theme.space20) {
                    playbackRegion(in: geometry.size)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                    timelineBlock
                }
                .padding(.horizontal, theme.spacingMD)
                .padding(.top, theme.space16)
                .padding(.bottom, theme.space12)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            header
        }
        .safeAreaInset(edge: .bottom) {
            packageSheet
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var backgroundMedia: some View {
        Group {
            if let imageName = report?.videoThumbnailName ?? report?.recommendations.first?.afterImageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [Color(hex: "7A695C"), Color(hex: "344956"), Color(hex: "1E2732")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
        }
    }

    private var screenScrim: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black.opacity(0.14), Color.black.opacity(0.3), Color.black.opacity(0.66)],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [Color.black.opacity(0.1), Color.clear],
                center: .center,
                startRadius: 40,
                endRadius: 340
            )
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: theme.space12) {
            HStack(spacing: theme.space12) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.black.opacity(0.34))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
                .accessibilityIdentifier("sampleOutput.back")

                Spacer(minLength: theme.space12)

                capsuleLabel(
                    text: "ADD-ON SAMPLE",
                    foreground: theme.expertBadge,
                    background: theme.expertBadgeSubtle.opacity(0.98)
                )
            }

            capsuleLabel(
                text: "CHAPTER 1: \(chapterLabel)",
                foreground: .white,
                background: .black.opacity(0.3)
            )
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, theme.spacingMD)
        .padding(.top, theme.space8)
        .padding(.bottom, theme.space12)
    }

    private var centerPlayback: some View {
        VStack(spacing: theme.space16) {
            Button {
                playerVM.togglePlay()
            } label: {
                Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 84, height: 84)
                    .background(theme.primary.opacity(0.92))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(playerVM.isPlaying ? "Pause sample walkthrough" : "Play sample walkthrough")
            .accessibilityIdentifier("sampleOutput.play")

            VStack(spacing: theme.space12) {
                Text(report?.videoTitle ?? "Curt's Consultation Walkthrough")
                    .font(theme.displayMedium)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.84)

                Text("\(videoDurationText) preview of the optional add-on")
                    .font(theme.bodySmall)
                    .foregroundStyle(.white.opacity(0.84))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var timelineBlock: some View {
        VStack(spacing: theme.space12) {
            Slider(value: Binding(get: {
                playerVM.progress
            }, set: { newValue in
                playerVM.seek(to: newValue)
            }), in: 0...1)
            .tint(theme.primary)

            HStack {
                Text(playerVM.elapsedText)
                Spacer()
                Text(timeText(report?.videoDuration ?? playerVM.duration))
            }
            .font(theme.caption)
            .foregroundStyle(.white.opacity(0.88))
        }
        .padding(.horizontal, theme.space16)
        .padding(.vertical, theme.space16)
        .background(
            RoundedRectangle(cornerRadius: theme.radiusLG)
                .fill(Color.black.opacity(0.28))
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusLG)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var packageSheet: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: theme.space16) {
                HStack(alignment: .top, spacing: theme.space12) {
                    Text(package.name.uppercased())
                        .font(theme.micro)
                        .fontWeight(.bold)
                        .tracking(1.1)
                        .foregroundStyle(theme.mutedForeground)

                    Spacer(minLength: theme.space12)

                    Text(package.turnaround.uppercased())
                        .font(theme.micro)
                        .fontWeight(.bold)
                        .tracking(0.8)
                        .foregroundStyle(Color(hex: "456BFF"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Color(hex: "E8F0FF"))
                        .clipShape(Capsule())
                }

                ViewThatFits(in: .horizontal) {
                    priceRowHorizontal
                    priceRowVertical
                }

                Text(package.subtitle)
                    .font(theme.bodySmall)
                    .foregroundStyle(theme.mutedForeground)
                    .fixedSize(horizontal: false, vertical: true)

                addConsultationButton
                    .accessibilityIdentifier("sampleOutput.bookConsultation")
            }
            .padding(theme.space16)
            .background(
                RoundedRectangle(cornerRadius: theme.radiusXL)
                    .fill(theme.card.opacity(0.98))
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.radiusXL)
                    .stroke(theme.borderSubtle, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.14), radius: 18, y: 6)
        }
        .padding(.horizontal, theme.spacingMD)
        .padding(.top, theme.space8)
        .padding(.bottom, theme.space8)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0), Color.black.opacity(0.16)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var priceRowHorizontal: some View {
        HStack(alignment: .firstTextBaseline, spacing: theme.space12) {
            priceAmount

            Text("one-time consultation")
                .font(theme.caption)
                .foregroundStyle(theme.mutedForeground)

            Spacer(minLength: 0)
        }
    }

    private var priceRowVertical: some View {
        VStack(alignment: .leading, spacing: theme.space16) {
            priceAmount
            Text("One-time consultation")
                .font(theme.caption)
                .foregroundStyle(theme.mutedForeground)
        }
    }

    private var priceAmount: some View {
        Text("$\(NSDecimalNumber(decimal: package.price).intValue).00")
            .font(theme.friendlyNumber)
            .foregroundStyle(theme.foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
    }

    private var addConsultationButton: some View {
        Button {
            router.navigate(to: .consultationCheckout(flowState: consultationFlowState))
        } label: {
            HStack(spacing: theme.space12) {
                Text("Add Curt's Consultation for \(currency(package.price))")
                    .font(theme.heading3)
                    .foregroundStyle(theme.actionCTAText)

                Spacer(minLength: 0)

                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.actionCTAText)
            }
            .padding(.horizontal, theme.space20)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(theme.ctaGradient)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
            .shadow(color: .black.opacity(0.14), radius: 10, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func playbackRegion(in size: CGSize) -> some View {
        let showsThumbnail = shouldShowSupportingThumbnail(in: size)
        let thumbnailSize = supportingThumbnailSize(in: size)

        return HStack(alignment: .center, spacing: theme.space16) {
            if showsThumbnail {
                Color.clear
                    .frame(width: thumbnailSize.width, height: thumbnailSize.height)
            }

            centerPlayback

            if showsThumbnail {
                supportingThumbnail(size: thumbnailSize)
            }
        }
        .padding(.horizontal, theme.space16)
        .padding(.vertical, theme.space24)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: theme.radiusXL)
                    .fill(Color.black.opacity(0.14))

                RoundedRectangle(cornerRadius: theme.radiusXL)
                    .fill(
                        LinearGradient(
                            colors: [Color.black.opacity(0.12), Color.black.opacity(0.24), Color.black.opacity(0.46)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusXL)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.22), radius: 24, y: 16)
    }

    private func supportingThumbnail(size: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            Group {
                if let imageName = report?.recommendations.first?.beforeImageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [Color.white.opacity(0.26), Color.white.opacity(0.08)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radiusLG)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )

            capsuleLabel(
                text: "BEFORE",
                foreground: .white,
                background: .black.opacity(0.36)
            )
            .padding(10)
        }
        .frame(width: size.width, height: size.height)
        .shadow(color: .black.opacity(0.18), radius: 14, y: 8)
        .accessibilityHidden(true)
    }

    private func shouldShowSupportingThumbnail(in size: CGSize) -> Bool {
        size.width >= 380 &&
        size.height >= 760 &&
        verticalSizeClass != .compact &&
        !dynamicTypeSize.isAccessibilitySize
    }

    private func supportingThumbnailSize(in size: CGSize) -> CGSize {
        CGSize(
            width: min(104, max(92, size.width * 0.25)),
            height: min(168, max(144, size.height * 0.2))
        )
    }

    private var videoDurationText: String {
        timeText(report?.videoDuration ?? playerVM.duration)
    }

    private func capsuleLabel(text: String, foreground: Color, background: Color) -> some View {
        Text(text)
            .font(theme.micro)
            .fontWeight(.bold)
            .foregroundStyle(foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(background)
            )
    }

    private func timeText(_ duration: TimeInterval) -> String {
        let total = Int(duration.rounded())
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private func currency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: value as NSNumber) ?? "$\(value)"
    }
}
