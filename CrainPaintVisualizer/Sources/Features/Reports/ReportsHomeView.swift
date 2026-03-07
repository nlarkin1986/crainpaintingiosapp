import SwiftUI

struct ReportsHomeView: View {
    @Environment(Theme.self) private var theme
    @Environment(AppState.self) private var appState
    @Environment(RouterPath.self) private var router
    @Environment(TabRouter.self) private var tabRouter
    @Environment(ReportsViewModel.self) private var reportsVM

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.space24) {
                // Hero section with visual interest
                VStack(alignment: .leading, spacing: theme.space12) {
                    HStack(spacing: theme.space8) {
                        // Aqua accent pill
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [ColorTokens.aqua, ColorTokens.aquaDark],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 8, height: 8)
                            .shadow(color: ColorTokens.aqua.opacity(0.4), radius: 4, y: 0)
                        
                        Text("EXPERT INSIGHTS")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.2)
                            .foregroundStyle(ColorTokens.aquaDark)
                    }
                    
                    Text("Master Reports")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(theme.foreground)
                    
                    Text("Personalized walkthroughs and room-ready recommendations from Curt Crain.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(theme.mutedForeground)
                        .lineSpacing(4)
                }
                .padding(.horizontal, theme.space20)
                .padding(.top, theme.space8)

                if reportsVM.readyReports.isEmpty {
                    emptyState
                        .padding(.horizontal, theme.space20)
                } else {
                    VStack(spacing: theme.space16) {
                        ForEach(reportsVM.readyReports) { report in
                            ReportCard(report: report) {
                                router.navigate(to: .masterReport(reportId: report.id))
                            }
                        }
                    }
                    .padding(.horizontal, theme.space20)
                }

                // Call-to-action section with sunshine yellow accent
                VStack(alignment: .leading, spacing: theme.space16) {
                    HStack(spacing: theme.space8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [ColorTokens.sunshine, ColorTokens.sunshineDeep],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("Need more visual options?")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(theme.foreground)
                    }
                    
                    AppButton("Open Visualization Gallery", variant: .outline, icon: "photo.on.rectangle.angled") {
                        tabRouter.openResultsGallery(appState: appState)
                    }
                }
                .padding(.horizontal, theme.space20)
                .padding(.bottom, theme.space32)
            }
            .padding(.top, theme.space12)
        }
        .background(theme.background)
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.large)
    }

    private var emptyState: some View {
        AppCard(elevation: .raised, accentColor: ColorTokens.aquaLight.opacity(0.3)) {
            VStack(spacing: theme.space20) {
                // Icon with gradient
                ZStack {
                    Circle()
                        .fill(ColorTokens.aquaSubtle)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [ColorTokens.aqua, ColorTokens.aquaDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: theme.space8) {
                    Text("No reports yet")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(theme.foreground)
                    
                    Text("Generate a visualization first, then create a personalized report from your results.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(theme.mutedForeground)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
                AppButton("Go To Visualize", variant: .cta, icon: "arrow.right") {
                    tabRouter.openVisualizer(appState: appState)
                }
                .padding(.top, theme.space8)
            }
            .padding(theme.space24)
            .frame(maxWidth: .infinity)
        }
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
                VStack(alignment: .leading, spacing: theme.space16) {
                    HStack(spacing: theme.space12) {
                        // Premium avatar with aqua gradient
                        if let photoName = report.curatorPhotoName {
                            Image(photoName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .strokeBorder(ColorTokens.aquaLight.opacity(0.3), lineWidth: 2)
                                )
                                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                        } else {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [ColorTokens.aqua, ColorTokens.aquaDark],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Text("CC")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                )
                                .shadow(color: ColorTokens.aqua.opacity(0.3), radius: 6, y: 2)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(report.title)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(theme.foreground)
                            
                            Text(report.curatorSubtitle.uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(ColorTokens.aquaDark)
                        }
                        
                        Spacer()
                        
                        // Chevron with subtle circle background
                        Circle()
                            .fill(ColorTokens.aquaSubtle)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(ColorTokens.aqua)
                            )
                    }

                    // Stats row with improved design
                    HStack(spacing: theme.space12) {
                        HStack(spacing: theme.space8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(ColorTokens.feedbackSuccess)
                            
                            Text("\(report.recommendations.count) ROOMS READY")
                                .font(.system(size: 12, weight: .bold))
                                .tracking(0.6)
                                .foregroundStyle(theme.foreground)
                        }
                        .padding(.horizontal, theme.space12)
                        .padding(.vertical, theme.space8)
                        .background(ColorTokens.feedbackSuccessSubtle)
                        .clipShape(Capsule())
                        
                        Spacer()
                        
                        Text(dateText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(theme.mutedForeground)
                    }

                    // Video info with play button
                    HStack(spacing: theme.space8) {
                        ZStack {
                            Circle()
                                .fill(ColorTokens.aqua)
                                .frame(width: 28, height: 28)
                            
                            Image(systemName: "play.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .offset(x: 1)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(report.videoTitle)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(theme.foreground)
                            
                            Text("\(timeText(report.videoDuration)) walkthrough")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(theme.mutedForeground)
                        }
                        
                        Spacer()
                    }
                }
                .padding(theme.space20)
            }
        }
        .buttonStyle(SpringButtonStyle())
    }

    private func timeText(_ duration: TimeInterval) -> String {
        let total = Int(duration.rounded())
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
