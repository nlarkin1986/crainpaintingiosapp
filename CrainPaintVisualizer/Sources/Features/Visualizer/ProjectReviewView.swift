import SwiftUI

struct ProjectReviewView: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @Environment(VisualizerViewModel.self) private var visualizerVM
    @State private var isStartingGeneration = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: theme.space16) {
                    WizardHeader(
                        steps: wizardSteps,
                        currentStep: 3,
                        helper: "Double-check the essentials before generation starts. We’ll move you into a live processing screen next."
                    )

                    if let photo = visualizerVM.photo {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
                            .padding(.horizontal, theme.spacingMD)
                    }

                    summaryCard
                }
                .padding(.bottom, 120)
            }

            FloatingActionBar {
                AppButton(
                    isStartingGeneration ? "Starting preview..." : "Generate My Previews",
                    variant: .cta,
                    icon: isStartingGeneration ? "hourglass" : "wand.and.stars",
                    isDisabled: !visualizerVM.canReviewProject || isStartingGeneration
                ) {
                    isStartingGeneration = true
                    router.navigate(to: .resultsGallery)
                    Task {
                        await visualizerVM.startGeneration()
                    }
                }
                .accessibilityIdentifier("projectReview.generate")
            }
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle("Review Project")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var wizardSteps: [String] {
        ["Photo", "Surface", "Colors", "Review"]
    }

    private var summaryCard: some View {
        AppCard(elevation: .raised) {
            VStack(alignment: .leading, spacing: theme.space16) {
                reviewRow(
                    title: "Colors",
                    detail: "\(visualizerVM.selectedColors.count) selected",
                    actionLabel: "Edit Colors"
                ) {
                    FlowLayout(spacing: theme.space8) {
                        ForEach(visualizerVM.selectedColors) { color in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 14, height: 14)
                                Text(color.name)
                                    .font(theme.caption)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(theme.secondary)
                            .clipShape(Capsule())
                        }
                    }
                } action: {
                    router.navigate(to: .itemPicker)
                }

                Divider()

                reviewRow(
                    title: "Photo",
                    detail: visualizerVM.hasPhoto ? "Photo ready for upload" : "Add a room photo",
                    actionLabel: "Change Photo",
                    body: { EmptyView() }
                ) {
                    router.navigate(to: .photoUpload)
                }

                Divider()

                reviewRow(
                    title: "Surface",
                    detail: visualizerVM.surfaceDescription,
                    actionLabel: "Edit Surface",
                    body: { EmptyView() }
                ) {
                    router.navigate(to: .surfacePicker)
                }
            }
            .padding(theme.space16)
        }
        .padding(.horizontal, theme.spacingMD)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("projectReview.summary")
    }

    private func reviewRow<Body: View>(
        title: String,
        detail: String,
        actionLabel: String,
        @ViewBuilder body: () -> Body,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: theme.space8) {
            HStack(alignment: .top, spacing: theme.space12) {
                VStack(alignment: .leading, spacing: theme.space4) {
                    Text(title)
                        .font(theme.heading3)
                        .foregroundStyle(theme.foreground)
                    Text(detail)
                        .font(theme.bodySmall)
                        .foregroundStyle(theme.mutedForeground)
                }

                Spacer()

                Button(actionLabel, action: action)
                    .font(theme.captionSmall.weight(.semibold))
                    .foregroundStyle(theme.primary)
            }

            body()
        }
    }
}

private struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    init(spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
