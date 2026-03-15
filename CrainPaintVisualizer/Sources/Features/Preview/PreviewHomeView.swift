import SwiftUI

struct PreviewHomeView: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @Environment(VisualizerViewModel.self) private var visualizerVM
    @Environment(FavoritesViewModel.self) private var favoritesVM

    private let secondaryActions: [PreviewSecondaryAction] = [
        .init(
            title: "Match a real object",
            detail: "Pull a paint color from a chair, tile, or fabric sample.",
            icon: "camera.macro",
            accent: Color(hex: "1A8C84"),
            route: .colorMatcher
        ),
        .init(
            title: "Browse colors by brand",
            detail: "Start with Benjamin Moore, Sherwin-Williams, or Farrow & Ball, then narrow fast.",
            icon: "square.grid.2x2",
            accent: Color(hex: "E28B56"),
            route: .itemPicker
        ),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: theme.space24) {
                hero

                if visualizerVM.homeProjectState != .empty {
                    continueProjectCard
                }

                secondaryActionSection

                if !favoritesVM.favorites.isEmpty {
                    favoritesShelf
                }
            }
            .padding(.horizontal, theme.spacingMD)
            .padding(.top, theme.space20)
            .padding(.bottom, theme.space40)
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle("Preview")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: theme.space16) {
            Text("Preview")
                .font(theme.captionSmall)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .tracking(1.2)
                .foregroundStyle(theme.textTertiary)

            Text(heroTitle)
                .font(theme.displayMedium)
                .foregroundStyle(theme.foreground)

            Text(heroDetail)
                .font(theme.bodyDefault)
                .foregroundStyle(theme.mutedForeground)
                .fixedSize(horizontal: false, vertical: true)

            freshStartMetaRow

            AppButton(heroButtonTitle, variant: .cta, icon: heroButtonIcon) {
                handlePrimaryAction()
            }
            .accessibilityIdentifier("home.primaryCTA")
        }
        .padding(theme.space24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    theme.card,
                    theme.secondary.opacity(0.98),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusXL)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 18, y: 8)
    }

    private var continueProjectCard: some View {
        AppCard(elevation: .flat) {
            VStack(alignment: .leading, spacing: theme.space16) {
                Text("Continue current project")
                    .font(theme.heading3)
                    .foregroundStyle(theme.foreground)

                Text(continueProjectDetail)
                    .font(theme.bodySmall)
                    .foregroundStyle(theme.mutedForeground)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .top, spacing: theme.space16) {
                    VStack(alignment: .leading, spacing: theme.space8) {
                        Text(visualizerVM.currentRoomName)
                            .font(theme.heading2)
                            .foregroundStyle(theme.foreground)

                        Text(visualizerVM.projectProgressLabel)
                            .font(theme.bodySmall)
                            .foregroundStyle(theme.mutedForeground)

                        if !visualizerVM.selectedColors.isEmpty {
                            HStack(spacing: theme.space8) {
                                ForEach(Array(visualizerVM.selectedColors.prefix(4))) { color in
                                    Circle()
                                        .fill(color.color)
                                        .frame(width: 18, height: 18)
                                        .overlay(Circle().stroke(theme.card, lineWidth: 2))
                                }

                                Text(colorCountLabel)
                                    .font(theme.captionSmall)
                                    .foregroundStyle(theme.textTertiary)
                            }
                        }
                    }

                    Spacer(minLength: 0)

                    if visualizerVM.hasPhoto {
                        Image(systemName: "photo")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(theme.primary)
                            .frame(width: 44, height: 44)
                            .background(theme.primary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))
                    }
                }

                AppButton("Continue current project", variant: .outline, icon: "arrow.clockwise") {
                    router.navigate(to: visualizerVM.activeProjectResultsRoute)
                }
                .accessibilityIdentifier("previewHome.continueProject")
            }
            .padding(theme.space20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var secondaryActionSection: some View {
        VStack(alignment: .leading, spacing: theme.space12) {
            Text("Other ways to start")
                .font(theme.heading3)
                .foregroundStyle(theme.foreground)

            ForEach(secondaryActions) { action in
                Button {
                    if action.route == .itemPicker, shouldResetDraftBeforeBrowsingBrand {
                        visualizerVM.prepareFreshProject()
                    }
                    router.navigate(to: action.route)
                } label: {
                    HStack(spacing: theme.space16) {
                        RoundedRectangle(cornerRadius: theme.radiusMD)
                            .fill(action.accent.opacity(0.12))
                            .frame(width: 52, height: 52)
                            .overlay(
                                Image(systemName: action.icon)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(action.accent)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(action.title)
                                .font(theme.heading3)
                                .foregroundStyle(theme.foreground)
                            Text(action.detail)
                                .font(theme.bodySmall)
                                .foregroundStyle(theme.mutedForeground)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.textTertiary)
                    }
                    .padding(theme.space16)
                    .background(theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radiusLarge))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radiusLarge)
                            .stroke(theme.borderSubtle, lineWidth: 1)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityIdentifier(action.accessibilityIdentifier)
            }
        }
    }

    private var favoritesShelf: some View {
        VStack(alignment: .leading, spacing: theme.space12) {
            Text("Saved colors")
                .font(theme.heading3)
                .foregroundStyle(theme.foreground)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.space12) {
                    ForEach(Array(favoritesVM.favorites.prefix(6))) { color in
                        Button {
                            visualizerVM.startFlow(with: color)
                            router.navigate(to: .photoUpload)
                        } label: {
                            VStack(alignment: .leading, spacing: theme.space12) {
                                RoundedRectangle(cornerRadius: theme.radiusLarge)
                                    .fill(color.color)
                                    .frame(width: 140, height: 120)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: theme.radiusLarge)
                                            .stroke(theme.card.opacity(0.8), lineWidth: 1)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(color.name)
                                        .font(theme.heading3)
                                        .foregroundStyle(theme.foreground)
                                        .lineLimit(2)
                                    Text(color.number)
                                        .font(theme.captionSmall)
                                        .foregroundStyle(theme.mutedForeground)
                                }
                            }
                            .padding(theme.space12)
                            .frame(width: 164, alignment: .leading)
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
            }
        }
    }

    private var freshStartMetaRow: some View {
        HStack(spacing: theme.space12) {
            previewMetric(
                icon: "photo",
                title: "New room photo"
            )
            previewMetric(
                icon: "swatchpalette",
                title: "Fresh color set"
            )
        }
    }

    private func previewMetric(icon: String, title: String) -> some View {
        HStack(spacing: theme.space8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(title)
                .font(theme.captionSmall)
                .lineLimit(1)
        }
        .foregroundStyle(theme.foreground)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(theme.background.opacity(0.75))
        .clipShape(Capsule())
    }

    private func handlePrimaryAction() {
        visualizerVM.prepareFreshProject()
        router.navigate(to: .photoUpload)
    }

    private var heroTitle: String {
        "Start with your room"
    }

    private var heroDetail: String {
        switch visualizerVM.homeProjectState {
        case .empty:
            return "Begin with a room photo, pick the surface you want to repaint, then compare a tight set of paint colors."
        default:
            return "Most projects start fresh with a new room photo, a new surface, and a new color direction. Your saved project is still available right below."
        }
    }

    private var heroButtonTitle: String {
        "Start a new preview"
    }

    private var heroButtonIcon: String {
        "arrow.right.circle.fill"
    }

    private var continueProjectDetail: String {
        switch visualizerVM.homeProjectState {
        case .processing:
            return "Your latest batch is still rendering. Jump back in to review progress and open the previews that are already ready."
        case .resultsReady:
            return "Your latest room already has previews ready. Reopen it to compare directions, save finalists, or share what you like."
        default:
            return "Pick up right where you left off with your saved room, surface, and shortlisted colors."
        }
    }

    private var colorCountLabel: String {
        let count = visualizerVM.selectedColors.count
        return count == 1 ? "1 color selected" : "\(count) colors selected"
    }

    private var shouldResetDraftBeforeBrowsingBrand: Bool {
        switch visualizerVM.homeProjectState {
        case .resultsReady, .processing:
            return true
        default:
            return false
        }
    }
}

private struct PreviewSecondaryAction: Identifiable {
    let title: String
    let detail: String
    let icon: String
    let accent: Color
    let route: AppRoute

    var id: String { title }

    var accessibilityIdentifier: String {
        switch route {
        case .colorMatcher:
            return "previewHome.matchObject"
        case .itemPicker:
            return "previewHome.browseByBrand"
        default:
            return "previewHome.secondaryAction.\(title)"
        }
    }
}
