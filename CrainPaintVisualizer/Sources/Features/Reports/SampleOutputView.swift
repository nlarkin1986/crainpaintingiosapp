import SwiftUI

struct SampleOutputView: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @Environment(ReportsViewModel.self) private var reportsVM
    @Environment(\.dismiss) private var dismiss

    let reportId: String
    let chapterId: String?

    @State private var playerVM = VideoPlayerViewModel()

    private var report: MasterReport? {
        reportsVM.report(for: reportId)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(hex: "7A695C"), Color(hex: "344956"), Color(hex: "1E2732")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: theme.spacingLG) {
                topBar
                Spacer()
                centerPlayback
                Spacer()
                timeline
                packageCard
            }
            .padding(.horizontal, theme.spacingMD)
            .padding(.top, theme.spacingSM)
            .padding(.bottom, theme.spacingLG)
        }
        .navigationBarBackButtonHidden(true)
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.45))
                    .clipShape(Circle())
            }

            Spacer()

            Text("SAMPLE RECORDING")
                .font(theme.micro)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.red)
                .clipShape(Capsule())

            Text((chapterId ?? "living-room").replacingOccurrences(of: "-", with: " ").uppercased())
                .font(theme.micro)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.black.opacity(0.45))
                .clipShape(Capsule())
        }
    }

    private var centerPlayback: some View {
        VStack(spacing: theme.spacingSM) {
            Button {
                playerVM.togglePlay()
            } label: {
                Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(theme.actionPrimaryText)
                    .frame(width: 86, height: 86)
                    .background(theme.actionPrimary.opacity(0.95))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            }

            Text(report?.videoTitle ?? "Curt's Master Walkthrough")
                .font(theme.title)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("\(timeText(report?.videoDuration ?? playerVM.duration)) Personalized Analysis")
                .font(theme.subhead)
                .foregroundStyle(.white.opacity(0.86))
        }
    }

    private var timeline: some View {
        VStack(spacing: theme.spacingSM) {
            Slider(value: Binding(get: {
                playerVM.progress
            }, set: { newValue in
                playerVM.seek(to: newValue)
            }), in: 0...1)
            .tint(theme.primary)

            HStack {
                Text(playerVM.elapsedText)
                Spacer()
                Text(playerVM.remainingText)
            }
            .font(theme.caption)
            .foregroundStyle(.white.opacity(0.85))
        }
    }

    private var packageCard: some View {
        VStack(alignment: .leading, spacing: theme.spacingSM) {
            Text("PREMIUM PACKAGE")
                .font(theme.micro)
                .foregroundStyle(theme.mutedForeground)

            HStack(alignment: .firstTextBaseline) {
                Text("$100.00")
                    .font(theme.friendlyNumber)
                    .foregroundStyle(theme.foreground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("/ complete report")
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
                Spacer()
            }

            AppBadge(text: "RECORDING INCLUDED", isFilled: false)

            AppButton("Book Your Master Consultation", variant: .primary, icon: "arrow.right") {
                router.navigate(to: .consultationCheckout(reportId: reportId))
            }
            .accessibilityIdentifier("sampleOutput.bookConsultation")
        }
        .padding(theme.spacingMD)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
    }

    private func timeText(_ duration: TimeInterval) -> String {
        let total = Int(duration.rounded())
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
