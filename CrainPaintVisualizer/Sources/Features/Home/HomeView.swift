import SwiftUI

struct HomeView: View {
    @Environment(Theme.self) private var theme
    @Environment(AppState.self) private var appState
    @Environment(TabRouter.self) private var tabRouter
    @Environment(RouterPath.self) private var router
    @Environment(VisualizerViewModel.self) private var visualizerVM
    @Environment(ReportsViewModel.self) private var reportsVM
    @State private var showDiscardDraftConfirmation = false
    @State private var isProjectSetupExpanded = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: theme.space20) {
                CompactScreenHeader(
                    title: "Your next step",
                    subtitle: visualizerVM.homeScreenSubtitle
                )

                primaryProjectCard
                quickActionsRow
                latestPreviewCard
                latestReportCard
                expertBridgeCard
            }
            .padding(.bottom, theme.spacingXL)
        }
        .background(theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await reportsVM.refreshReports()
        }
        .onChange(of: visualizerVM.homeProjectState) { _, newValue in
            guard newValue == .processing else { return }
            withAnimation(Theme.animationDefault) {
                isProjectSetupExpanded = false
            }
        }
        .confirmationDialog(
            "Discard current draft?",
            isPresented: $showDiscardDraftConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard Draft and Start New Preview", role: .destructive) {
                discardDraftAndStartNewPreview()
            }
            .accessibilityIdentifier("home.discardDraft.confirm")

            Button("Cancel", role: .cancel) {}
                .accessibilityIdentifier("home.discardDraft.cancel")
        } message: {
            Text("Your current colors, photo, and surface selection will be removed. Saved design cards will remain available.")
        }
    }

    private var primaryProjectCard: some View {
        AppCard(elevation: .raised) {
            VStack(alignment: .leading, spacing: theme.space16) {
                HStack(alignment: .top, spacing: theme.space12) {
                    VStack(alignment: .leading, spacing: theme.space4) {
                        Text(primaryProjectEyebrow)
                            .font(theme.micro.weight(.bold))
                            .tracking(1)
                            .textCase(.uppercase)
                            .foregroundStyle(theme.primary)

                        Text(primaryProjectTitle)
                            .font(theme.heading1)
                            .foregroundStyle(theme.foreground)

                        Text(visualizerVM.projectProgressLabel)
                            .font(theme.bodySmall)
                            .foregroundStyle(theme.mutedForeground)
                    }

                    Spacer()

                    if let badgeText = visualizerVM.homeProjectBadgeText {
                        AppBadge(text: badgeText)
                    }
                }

                if visualizerVM.isCurrentJobProcessing {
                    VStack(alignment: .leading, spacing: theme.space12) {
                        Text("Processing status")
                            .font(theme.micro.weight(.bold))
                            .tracking(1)
                            .textCase(.uppercase)
                            .foregroundStyle(theme.mutedForeground)

                        VStack(alignment: .leading, spacing: theme.space12) {
                            processingUpdateRow(
                                icon: "sparkles.rectangle.stack.fill",
                                title: processingSummaryTitle,
                                detail: "Finished previews unlock in Results once this batch is done."
                            )
                            processingUpdateRow(
                                icon: "lock.fill",
                                title: "Adjustments unlock after this set finishes",
                                detail: "We’re keeping the current room study stable so nothing gets interrupted mid-process."
                            )
                        }
                    }
                } else {
                    projectSetupSection
                }

                AppButton(primaryCTAButtonTitle, variant: .cta, icon: primaryCTAButtonIcon) {
                    handlePrimaryCTA()
                }
                .accessibilityIdentifier("home.primaryCTA")

                if visualizerVM.showsHomeStartNewAction {
                    VStack(alignment: .leading, spacing: theme.space8) {
                        AppButton("Start New Preview", variant: .outline) {
                            showDiscardDraftConfirmation = true
                        }
                        .accessibilityIdentifier("home.startNewCTA")

                        Text("Discard current draft. Design cards stay in Saved.")
                            .font(theme.captionSmall)
                            .foregroundStyle(theme.mutedForeground)
                    }
                }
            }
            .padding(theme.space16)
        }
        .padding(.horizontal, theme.spacingMD)
    }

    private var quickActionsRow: some View {
        HStack(spacing: theme.space12) {
            quickActionCard(
                title: "Match Color",
                body: "Capture a real object and bring the closest paint into your project.",
                icon: "camera.viewfinder"
            ) {
                router.navigate(to: .colorMatcher)
            }

            quickActionCard(
                title: "Open Design Cards",
                body: "Jump back into design cards, favorite colors, and reports.",
                icon: "square.stack.3d.up"
            ) {
                tabRouter.openSaved(appState: appState, section: .previews)
            }
            .accessibilityIdentifier("home.quickAction.saved")
        }
        .padding(.horizontal, theme.spacingMD)
    }

    @ViewBuilder
    private var latestPreviewCard: some View {
        VStack(alignment: .leading, spacing: theme.space12) {
            sectionHeader(
                title: visualizerVM.isCurrentJobProcessing ? "Preview Status" : "Latest Preview",
                detail: visualizerVM.isCurrentJobProcessing ? nil : (visualizerVM.hasSavedVisualizations ? "Open Design Cards" : nil)
            ) {
                tabRouter.openSaved(appState: appState, section: .previews)
            }

            if visualizerVM.isCurrentJobProcessing {
                placeholderCard(
                    title: processingSummaryTitle,
                    body: "Stay on the processing screen while we finish this batch. Preview details unlock once the room study is done."
                )
            } else if let visualization = visualizerVM.latestVisualization {
                Button {
                    openLatestPreview(visualization)
                } label: {
                    previewHighlightCard(visualization)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, theme.spacingMD)
            } else {
                placeholderCard(
                    title: "Your latest preview will appear here",
                    body: "Generate a room preview and it will stay easy to reopen."
                )
            }
        }
    }

    @ViewBuilder
    private var latestReportCard: some View {
        VStack(alignment: .leading, spacing: theme.space12) {
            HStack {
                Text("Consultation Reports")
                    .font(theme.heading2)
                    .foregroundStyle(theme.foreground)
                Spacer()
                Text(reportsVM.reports.isEmpty ? "No reports yet" : "\(reportsVM.reports.count)")
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
            }
            .padding(.horizontal, theme.spacingMD)

            if let report = reportsVM.reports.first {
                Button {
                    appState.selectedTab = .saved
                    tabRouter.openReport(reportId: report.id, appState: appState)
                } label: {
                    VStack(alignment: .leading, spacing: theme.space8) {
                        Text(report.title)
                            .font(theme.heading3)
                            .foregroundStyle(theme.foreground)
                        Text(report.status == .ready ? "Ready to open" : "In progress")
                            .font(theme.caption)
                            .foregroundStyle(theme.mutedForeground)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
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
            } else {
                placeholderCard(
                    title: "Reports show up after checkout",
                    body: "When you purchase a consultation, progress and completed reports will appear here."
                )
            }
        }
    }

    private var expertBridgeCard: some View {
        AppCard(elevation: .raised) {
            VStack(alignment: .leading, spacing: theme.space12) {
                Text("Need a final expert call?")
                    .font(theme.heading2)
                    .foregroundStyle(theme.foreground)
                Text("Preview Curt's walkthrough or book a consultation once you have a shortlist.")
                    .font(theme.bodySmall)
                    .foregroundStyle(theme.mutedForeground)
                AppButton("Explore Expert Help", variant: .outline, icon: "person.crop.circle") {
                    appState.selectedTab = .expert
                }
            }
            .padding(theme.space16)
        }
        .padding(.horizontal, theme.spacingMD)
    }

    private func openLatestPreview(_ visualization: Visualization) {
        let isFreshlyRendered = visualizerVM.currentJobCompletedVisualizations.contains(where: { $0.id == visualization.id })
        if isFreshlyRendered {
            router.navigate(to: .visualizationDetail(visualization: visualization))
        } else {
            router.navigate(to: .savedPreviewDetail(visualization: visualization))
        }
    }

    private func quickActionCard(title: String, body: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: theme.space8) {
                Circle()
                    .fill(theme.primary.opacity(0.12))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: icon)
                            .foregroundStyle(theme.primary)
                    )

                Text(title)
                    .font(theme.heading3)
                    .foregroundStyle(theme.foreground)
                Text(body)
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(theme.space16)
            .background(theme.card)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radiusLG)
                    .stroke(theme.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func previewHighlightCard(_ visualization: Visualization) -> some View {
        VStack(alignment: .leading, spacing: theme.space12) {
            VisualizationLoadedImageView(
                visualization: visualization,
                role: .after,
                preset: .homeFeature,
                contentMode: .fill
            ) {
                RoundedRectangle(cornerRadius: theme.radiusXL)
                    .fill(Color(hex: visualization.colorHex).opacity(0.2))
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))

            VStack(alignment: .leading, spacing: 4) {
                Text(visualization.roomName)
                    .font(theme.heading3)
                    .foregroundStyle(theme.foreground)
                Text("\(visualization.colorName) / \(visualization.colorCode)")
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
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

    private func placeholderCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: theme.space8) {
            Text(title)
                .font(theme.heading3)
                .foregroundStyle(theme.foreground)
            Text(body)
                .font(theme.bodySmall)
                .foregroundStyle(theme.mutedForeground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.space16)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusXL)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
        .padding(.horizontal, theme.spacingMD)
    }

    private var primaryProjectEyebrow: String {
        visualizerVM.homeProjectEyebrow
    }

    private var primaryProjectTitle: String {
        visualizerVM.homeProjectTitle
    }

    private var primaryCTAButtonTitle: String {
        visualizerVM.homePrimaryCTAButtonTitle
    }

    private var primaryCTAButtonIcon: String {
        switch visualizerVM.homeProjectState {
        case .processing:
            return "hourglass.circle"
        case .resultsReady:
            return "square.stack.3d.up"
        case .reviewDraft:
            return "checkmark.circle"
        default:
            return "arrow.right"
        }
    }

    private var projectSetupSectionTitle: String {
        visualizerVM.homeProjectState == .empty ? "Project setup" : "Preview flow"
    }

    private var processingSummaryTitle: String {
        let readyCount = visualizerVM.currentJobCompletedCount
        let totalCount = visualizerVM.currentJobTotalCount

        if totalCount == 0 {
            return "Preparing your preview set"
        }
        if readyCount > 0 {
            return "\(readyCount) of \(totalCount) previews ready so far"
        }
        return "Building \(totalCount) previews now"
    }

    private func processingUpdateRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: theme.space12) {
            Circle()
                .fill(theme.primary.opacity(0.12))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(theme.primary)
                )

            VStack(alignment: .leading, spacing: theme.space4) {
                Text(title)
                    .font(theme.label.weight(.semibold))
                    .foregroundStyle(theme.foreground)
                Text(detail)
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(theme.space12)
        .background(theme.secondary)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
    }

    private func sectionHeader(title: String, detail: String?, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(theme.heading2)
                .foregroundStyle(theme.foreground)
            Spacer()
            if let detail {
                Button(detail, action: action)
                    .font(theme.captionSmall.weight(.semibold))
                    .foregroundStyle(theme.primary)
            }
        }
        .padding(.horizontal, theme.spacingMD)
    }

    private func handlePrimaryCTA() {
        if visualizerVM.homeProjectState == .empty {
            visualizerVM.prepareFreshProject()
        }
        router.navigate(to: visualizerVM.resumeRoute)
    }

    private func discardDraftAndStartNewPreview() {
        visualizerVM.reset()
        router.navigate(to: .photoUpload)
    }

    private var currentSetupStep: ProjectSetupStep? {
        if visualizerVM.selectedColors.isEmpty {
            return .colors
        }
        if !visualizerVM.hasPhoto {
            return .photo
        }
        if !visualizerVM.isSurfaceSelectionValid {
            return .surface
        }
        return nil
    }

    private var completedSetupCount: Int {
        ProjectSetupStep.allCases.filter { setupState(for: $0) == .complete }.count
    }

    private var projectSetupSummaryTitle: String {
        switch visualizerVM.homeProjectState {
        case .empty, .chooseColors:
            return "Next: Choose colors"
        case .addPhoto:
            return "Next: Add a room photo"
        case .chooseSurface:
            return "Next: Choose the surface"
        case .reviewDraft:
            return "Ready to review"
        case .resultsReady:
            return "Setup complete"
        case .processing:
            return "Preview processing"
        }
    }

    private var projectSetupSummaryDetail: String {
        switch visualizerVM.homeProjectState {
        case .empty, .chooseColors:
            return "Start with paint, then move through photo and surface."
        case .addPhoto:
            return "Colors are set. Add the room photo next."
        case .chooseSurface:
            return "Colors and photo are ready. Pick the surface next."
        case .reviewDraft:
            return "Colors, photo, and surface are ready for final review."
        case .resultsReady:
            return "This preview already has its colors, photo, and surface."
        case .processing:
            return "Your current preview set is processing."
        }
    }

    private var projectSetupProgressText: String {
        "\(completedSetupCount) of \(ProjectSetupStep.allCases.count) complete"
    }

    private var projectSetupSummaryIcon: String {
        if let currentSetupStep {
            return currentSetupStep.iconName
        }
        return visualizerVM.homeProjectState == .resultsReady ? "square.stack.3d.up.fill" : "checkmark.circle.fill"
    }

    private var projectSetupSummaryState: ProjectSetupVisualState {
        if let currentSetupStep {
            return setupState(for: currentSetupStep)
        }
        return .complete
    }

    private var projectSetupSection: some View {
        VStack(alignment: .leading, spacing: theme.space12) {
            Button {
                withAnimation(Theme.animationDefault) {
                    isProjectSetupExpanded.toggle()
                }
            } label: {
                VStack(alignment: .leading, spacing: theme.space12) {
                    HStack(alignment: .top, spacing: theme.space12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: theme.radiusMD)
                                .fill(iconBackground(for: projectSetupSummaryState))
                                .frame(width: 42, height: 42)

                            Image(systemName: projectSetupSummaryIcon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(iconForeground(for: projectSetupSummaryState))
                        }

                        VStack(alignment: .leading, spacing: theme.space4) {
                            Text(projectSetupSectionTitle)
                                .font(theme.micro.weight(.bold))
                                .tracking(1)
                                .textCase(.uppercase)
                                .foregroundStyle(theme.mutedForeground)

                            Text(projectSetupSummaryTitle)
                                .font(theme.heading3)
                                .foregroundStyle(theme.foreground)

                            Text(projectSetupSummaryDetail)
                                .font(theme.caption)
                                .foregroundStyle(theme.mutedForeground)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: theme.space8)

                        VStack(alignment: .trailing, spacing: theme.space8) {
                            Text(projectSetupProgressText)
                                .font(theme.captionSmall.weight(.semibold))
                                .foregroundStyle(theme.primary)
                                .multilineTextAlignment(.trailing)

                            Image(systemName: isProjectSetupExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(theme.primary)
                        }
                    }

                    setupProgressTrack
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(theme.space12)
                .background(theme.secondary)
                .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radiusLG)
                        .stroke(theme.borderSubtle, lineWidth: 1)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(projectSetupSectionTitle)
            .accessibilityValue("\(projectSetupSummaryTitle). \(projectSetupProgressText). \(isProjectSetupExpanded ? "Expanded" : "Collapsed")")
            .accessibilityHint("Shows or hides the full preview flow")
            .accessibilityIdentifier("home.projectSetup.disclosure")

            if isProjectSetupExpanded {
                VStack(spacing: theme.space8) {
                    ForEach(ProjectSetupStep.allCases, id: \.self) { step in
                        projectSetupDetailRow(for: step)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var setupProgressTrack: some View {
        HStack(spacing: theme.space8) {
            ForEach(ProjectSetupStep.allCases, id: \.self) { step in
                Capsule()
                    .fill(progressFill(for: step))
                    .frame(maxWidth: .infinity)
                    .frame(height: 6)
            }
        }
        .accessibilityHidden(true)
    }

    private func projectSetupDetailRow(for step: ProjectSetupStep) -> some View {
        let state = setupState(for: step)

        return HStack(spacing: theme.space12) {
            ZStack {
                RoundedRectangle(cornerRadius: theme.radiusMD)
                    .fill(iconBackground(for: state))
                    .frame(width: 38, height: 38)

                Image(systemName: step.iconName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(iconForeground(for: state))
            }

            VStack(alignment: .leading, spacing: theme.space2) {
                Text(step.title)
                    .font(theme.label.weight(.semibold))
                    .foregroundStyle(theme.foreground)

                Text(statusText(for: step))
                    .font(theme.captionSmall)
                    .foregroundStyle(statusForeground(for: state))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: theme.space8)

            Text(stepStatusLabel(for: state))
                .font(theme.micro.weight(.bold))
                .foregroundStyle(stepStatusForeground(for: state))
                .padding(.horizontal, theme.space8)
                .padding(.vertical, theme.space4)
                .background(stepStatusBackground(for: state))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, theme.space12)
        .padding(.vertical, theme.space12)
        .background(stepBackground(for: state))
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusLG)
                .stroke(stepBorder(for: state), lineWidth: state == .active ? 1.5 : 1)
        )
        .accessibilityIdentifier(step.accessibilityIdentifier)
        .accessibilityLabel("\(step.title), \(statusText(for: step)), \(stepStatusLabel(for: state))")
    }

    private func setupState(for step: ProjectSetupStep) -> ProjectSetupVisualState {
        switch step {
        case .colors where !visualizerVM.selectedColors.isEmpty:
            return .complete
        case .photo where visualizerVM.hasPhoto:
            return .complete
        case .surface where visualizerVM.isSurfaceSelectionValid:
            return .complete
        case _ where currentSetupStep == step:
            return .active
        default:
            return .pending
        }
    }

    private func statusText(for step: ProjectSetupStep) -> String {
        switch step {
        case .colors:
            let colorCount = visualizerVM.selectedColors.count
            if colorCount == 0 {
                return "Choose up to five paint colors"
            }
            return colorCount == 1 ? "1 color selected" : "\(colorCount) colors selected"
        case .photo:
            if visualizerVM.hasPhoto {
                return "Room photo ready"
            }
            if visualizerVM.isCompressing {
                return "Preparing your photo"
            }
            return "Add a room photo"
        case .surface:
            if visualizerVM.isSurfaceSelectionValid {
                return visualizerVM.surfaceDescription
            }
            return "Pick walls, trim, or cabinets"
        }
    }

    private func stepBackground(for state: ProjectSetupVisualState) -> Color {
        switch state {
        case .pending:
            return theme.secondary.opacity(0.8)
        case .active:
            return theme.primary.opacity(0.11)
        case .complete:
            return theme.feedbackSuccess.opacity(0.10)
        }
    }

    private func stepBorder(for state: ProjectSetupVisualState) -> Color {
        switch state {
        case .pending:
            return theme.borderSubtle
        case .active:
            return theme.primary.opacity(0.35)
        case .complete:
            return theme.feedbackSuccess.opacity(0.32)
        }
    }

    private func iconBackground(for state: ProjectSetupVisualState) -> Color {
        switch state {
        case .pending:
            return theme.card
        case .active:
            return theme.primary.opacity(0.18)
        case .complete:
            return theme.feedbackSuccess.opacity(0.18)
        }
    }

    private func iconForeground(for state: ProjectSetupVisualState) -> Color {
        switch state {
        case .pending:
            return theme.mutedForeground
        case .active:
            return theme.primary
        case .complete:
            return theme.feedbackSuccess
        }
    }

    private func statusForeground(for state: ProjectSetupVisualState) -> Color {
        switch state {
        case .pending:
            return theme.mutedForeground
        case .active:
            return theme.primary
        case .complete:
            return theme.feedbackSuccess
        }
    }

    private func progressFill(for step: ProjectSetupStep) -> Color {
        switch setupState(for: step) {
        case .pending:
            return theme.border
        case .active:
            return theme.primary.opacity(0.65)
        case .complete:
            return theme.feedbackSuccess
        }
    }

    private func stepStatusLabel(for state: ProjectSetupVisualState) -> String {
        switch state {
        case .pending:
            return "Later"
        case .active:
            return "Next"
        case .complete:
            return "Done"
        }
    }

    private func stepStatusBackground(for state: ProjectSetupVisualState) -> Color {
        switch state {
        case .pending:
            return theme.card
        case .active:
            return theme.primary.opacity(0.16)
        case .complete:
            return theme.feedbackSuccess.opacity(0.14)
        }
    }

    private func stepStatusForeground(for state: ProjectSetupVisualState) -> Color {
        switch state {
        case .pending:
            return theme.mutedForeground
        case .active:
            return theme.primary
        case .complete:
            return theme.feedbackSuccess
        }
    }
}

private enum ProjectSetupStep: CaseIterable, Hashable {
    case colors
    case photo
    case surface

    var title: String {
        switch self {
        case .colors:
            return "Colors"
        case .photo:
            return "Photo"
        case .surface:
            return "Surface"
        }
    }

    var iconName: String {
        switch self {
        case .colors:
            return "paintpalette.fill"
        case .photo:
            return "photo.fill"
        case .surface:
            return "square.split.diagonal.2x2"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .colors:
            return "home.projectSetup.colors"
        case .photo:
            return "home.projectSetup.photo"
        case .surface:
            return "home.projectSetup.surface"
        }
    }
}

private enum ProjectSetupVisualState {
    case pending
    case active
    case complete
}
