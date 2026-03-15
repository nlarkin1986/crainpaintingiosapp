import SwiftUI

struct ResultsGalleryView: View {
    @Environment(Theme.self) private var theme
    @Environment(AppState.self) private var appState
    @Environment(TabRouter.self) private var tabRouter
    @Environment(RouterPath.self) private var router
    @Environment(VisualizerViewModel.self) private var visualizerVM

    private var currentJob: VisualizationJob? { visualizerVM.currentJob }
    private var completedVisualizations: [Visualization] {
        let currentJobVisualizations = visualizerVM.currentJobCompletedVisualizations
        if !currentJobVisualizations.isEmpty {
            return currentJobVisualizations
        }
        return visualizerVM.activeProjectResults.map(\.visualization)
    }
    private var hasSavedDesignCards: Bool { !visualizerVM.activeProjectResults.isEmpty || visualizerVM.hasSavedVisualizations }
    private var hasReadyPreviews: Bool { !completedVisualizations.isEmpty }
    private var isProcessing: Bool { visualizerVM.isCurrentJobProcessing }
    private var hasFailedItems: Bool { visualizerVM.currentJobFailedCount > 0 }
    private var shouldShowCompactStatus: Bool { hasReadyPreviews && (isProcessing || hasFailedItems) }
    private var shouldShowJobDetails: Bool { hasReadyPreviews && (isProcessing || hasFailedItems) }
    private var processingPresentation: ResultsGalleryProcessingPresentation? {
        guard let currentJob, isProcessing else { return nil }
        return ResultsGalleryProcessingPresentation(
            job: currentJob,
            completedCount: visualizerVM.currentJobCompletedCount,
            lastGenerationMessage: visualizerVM.lastGenerationMessage
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: theme.space20) {
                    if hasReadyPreviews {
                        readyFirstContent
                    } else if let currentJob, let processingPresentation {
                        processingContent(job: currentJob, presentation: processingPresentation)
                    } else {
                        standardContent
                    }
                }
                .padding(.bottom, theme.spacing2XL)
            }

            if shouldShowFloatingActionBar {
                FloatingActionBar {
                    AppButton(primaryActionTitle, variant: .cta, icon: primaryActionIcon) {
                        router.navigate(to: primaryActionRoute)
                    }
                }
            }
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var standardContent: some View {
        CompactScreenHeader(
            title: screenTitle,
            subtitle: screenSubtitle,
            detail: currentJobDetail
        )

        if let currentJob {
            jobSummaryCard(currentJob)

            VStack(alignment: .leading, spacing: theme.space12) {
                Text("Current Job")
                    .font(theme.heading2)
                    .foregroundStyle(theme.foreground)
                    .padding(.horizontal, theme.spacingMD)

                ForEach(currentJob.items) { item in
                    JobItemCard(item: item) {
                        if case .completed(let result) = item.state {
                            router.navigate(to: .visualizationDetail(visualization: result.visualization))
                        }
                    } retryAction: {
                        Task {
                            await visualizerVM.retryGeneration(for: item.color)
                        }
                    }
                    .padding(.horizontal, theme.spacingMD)
                }
            }
        }

        if !completedVisualizations.isEmpty {
            previewsSection(
                title: "Ready to Review",
                visualizations: completedVisualizations
            )
        }

        if currentJob == nil && completedVisualizations.isEmpty {
            emptyState
        }
    }

    @ViewBuilder
    private var readyFirstContent: some View {
        CompactScreenHeader(
            title: screenTitle,
            subtitle: screenSubtitle,
            detail: currentJobDetail
        )

        VStack(alignment: .leading, spacing: theme.space12) {
            previewsSection(
                title: "Ready to Review",
                detail: currentJob.map { "\($0.roomName) • \($0.surfaceDescription)" },
                visualizations: completedVisualizations
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("results.readySection")

        readyActionsSection

        if shouldShowCompactStatus, let currentJob {
            readyStateStatusModule(for: currentJob)
        }

        if shouldShowJobDetails, let currentJob {
            jobDetailsSection(currentJob)
                .accessibilityIdentifier("results.jobDetails")
        }
    }

    @ViewBuilder
    private func processingContent(
        job: VisualizationJob,
        presentation: ResultsGalleryProcessingPresentation
    ) -> some View {
        CompactScreenHeader(
            title: presentation.title,
            subtitle: presentation.subtitle,
            detail: presentation.detail
        )

        processingStatusModule(presentation)

        VStack(alignment: .leading, spacing: theme.space12) {
            ForEach(job.items) { item in
                ProcessingJobItemRow(item: item, presentation: presentation)
                    .padding(.horizontal, theme.spacingMD)
            }
        }
    }

    private var readyActionsSection: some View {
        VStack(alignment: .leading, spacing: theme.space12) {
            Text(readyResultsSummary)
                .font(theme.bodySmall)
                .foregroundStyle(theme.mutedForeground)
                .fixedSize(horizontal: false, vertical: true)

            AppButton(primaryActionTitle, variant: .outline, icon: primaryActionIcon) {
                router.navigate(to: primaryActionRoute)
            }
            .frame(maxWidth: 220, alignment: .leading)
            .accessibilityIdentifier("results.adjustProjectInline")
        }
        .padding(.horizontal, theme.spacingMD)
    }

    private func processingStatusModule(
        _ presentation: ResultsGalleryProcessingPresentation
    ) -> some View {
        AppCard(elevation: .raised) {
            VStack(alignment: .leading, spacing: theme.space12) {
                Text(presentation.surfaceLine)
                    .font(theme.subhead.weight(.semibold))
                    .foregroundStyle(theme.foreground)

                Text(presentation.subtitle)
                    .font(theme.label.weight(.semibold))
                    .foregroundStyle(theme.foreground)
                    .fixedSize(horizontal: false, vertical: true)

                ProcessingActivityBar()
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Preview rendering activity")
                    .accessibilityValue(presentation.progressAccessibilityValue)
                    .accessibilityIdentifier("results.processing.progress")

                Text(presentation.helperText)
                    .font(theme.bodySmall)
                    .foregroundStyle(theme.mutedForeground)
                    .fixedSize(horizontal: false, vertical: true)

                if let notice = presentation.notice {
                    Text(notice)
                        .font(theme.bodySmall)
                        .foregroundStyle(theme.mutedForeground)
                        .padding(theme.space12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(theme.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
                }
            }
            .padding(theme.space16)
        }
        .padding(.horizontal, theme.spacingMD)
        .accessibilityIdentifier("results.processing.status")
    }

    private func readyStateStatusModule(for job: VisualizationJob) -> some View {
        AppCard(elevation: .raised) {
            VStack(alignment: .leading, spacing: theme.space12) {
                HStack(alignment: .top, spacing: theme.space12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(readyStateStatusTitle)
                            .font(theme.heading3)
                            .foregroundStyle(theme.foreground)
                            .accessibilityIdentifier("results.processing.compactStatusTitle")

                        Text("\(job.roomName) • \(job.surfaceDescription)")
                            .font(theme.caption)
                            .foregroundStyle(theme.mutedForeground)
                    }

                    Spacer()

                    if isProcessing {
                        ProcessingStatusToken(state: .generating, label: "Rendering now")
                            .accessibilityIdentifier("results.processing.compactStatusToken")
                    } else if hasFailedItems {
                        ProcessingStatusToken(
                            state: .failed("Needs review"),
                            label: visualizerVM.currentJobFailedCount == 1 ? "Needs review" : "\(visualizerVM.currentJobFailedCount) need review"
                        )
                        .accessibilityIdentifier("results.processing.compactStatusToken")
                    }
                }

                HStack(spacing: theme.space8) {
                    statusPill(
                        value: "\(visualizerVM.currentJobCompletedCount)",
                        label: "Ready",
                        emphasized: visualizerVM.currentJobCompletedCount > 0
                    )

                    if isProcessing {
                        statusPill(
                            value: "\(visualizerVM.currentJobProcessingCount)",
                            label: "Rendering",
                            emphasized: true
                        )
                    }

                    if hasFailedItems {
                        statusPill(
                            value: "\(visualizerVM.currentJobFailedCount)",
                            label: "Needs Review",
                            emphasized: true
                        )
                    }
                }

                Text(readyStateHelperText)
                    .font(theme.bodySmall)
                    .foregroundStyle(theme.mutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("results.processing.compactStatusHelper")

                if let notice = currentJob?.notice ?? visualizerVM.lastGenerationMessage {
                    Text(notice)
                        .font(theme.bodySmall)
                        .foregroundStyle(theme.mutedForeground)
                        .padding(theme.space12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(theme.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
                }
            }
            .padding(theme.space16)
        }
        .padding(.horizontal, theme.spacingMD)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("results.processing.compactStatus")
    }

    private var screenTitle: String {
        "Your results"
    }

    private var screenSubtitle: String {
        if currentJob != nil, visualizerVM.currentJobFailedCount > 0 {
            return "Review the finished previews below or retry anything that needs attention."
        }
        if currentJob == nil, !completedVisualizations.isEmpty {
            return "Compare the saved previews for this room, reopen a favorite, or generate a new batch."
        }
        if currentJob == nil, completedVisualizations.isEmpty, hasSavedDesignCards {
            return "This project doesn't have active results right now. Open the Saved tab for your design cards or start another room study."
        }
        return "Review a finished preview or start another room study."
    }

    private var currentJobDetail: String {
        if currentJob != nil {
            let completeCount = visualizerVM.currentJobCompletedCount
            let failedCount = visualizerVM.currentJobFailedCount
            if failedCount > 0 {
                return "\(completeCount) ready • \(failedCount) need review"
            }
            return "\(completeCount) ready"
        }

        if !completedVisualizations.isEmpty {
            return completedVisualizations.count == 1
                ? "1 preview ready"
                : "\(completedVisualizations.count) previews ready"
        }

        if hasSavedDesignCards {
            return "\(visualizerVM.savedVisualizations.count) design cards saved"
        }

        return "Waiting for first result"
    }

    private var primaryActionTitle: String {
        if visualizerVM.selectedColors.isEmpty {
            return "Start a Preview"
        }
        if currentJob == nil {
            return "Preview More Colors"
        }
        return "Adjust Project"
    }

    private var primaryActionIcon: String {
        if currentJob == nil && visualizerVM.selectedColors.isEmpty {
            return "wand.and.stars"
        }
        return "arrow.clockwise"
    }

    private var primaryActionRoute: AppRoute {
        if visualizerVM.selectedColors.isEmpty {
            return .photoUpload
        }
        return .itemPicker
    }

    private var shouldShowFloatingActionBar: Bool {
        !hasReadyPreviews && processingPresentation?.hidesFloatingActionBar != true
    }

    private var readyResultsSummary: String {
        if isProcessing {
            return visualizerVM.currentJobCompletedCount == 1
                ? "1 preview is ready now while the rest of this room study keeps rendering."
                : "\(visualizerVM.currentJobCompletedCount) previews are ready now while the rest of this room study keeps rendering."
        }

        if hasFailedItems {
            return visualizerVM.currentJobCompletedCount == 1
                ? "1 preview is ready to review. Retry the option that still needs attention."
                : "\(visualizerVM.currentJobCompletedCount) previews are ready to review. Retry the options that still need attention."
        }

        return "Your finished previews are ready to compare, reopen, and refine."
    }

    private var readyStateStatusTitle: String {
        if isProcessing {
            return "Rendering continues in the background"
        }
        return hasFailedItems ? "One more preview needs review" : "Room study summary"
    }

    private var readyStateHelperText: String {
        if let processingPresentation {
            return processingPresentation.helperText
        }
        return "Retry anything that missed. Your ready previews stay available above."
    }

    private func jobDetailsSection(_ job: VisualizationJob) -> some View {
        VStack(alignment: .leading, spacing: theme.space12) {
            Text("Current Job")
                .font(theme.heading2)
                .foregroundStyle(theme.foreground)
                .padding(.horizontal, theme.spacingMD)
                .accessibilityIdentifier("results.jobDetails.heading")

            ForEach(job.items) { item in
                JobItemCard(item: item) {
                    if case .completed(let result) = item.state {
                        router.navigate(to: .visualizationDetail(visualization: result.visualization))
                    }
                } retryAction: {
                    Task {
                        await visualizerVM.retryGeneration(for: item.color)
                    }
                }
                .padding(.horizontal, theme.spacingMD)
            }
        }
    }

    private func jobSummaryCard(_ job: VisualizationJob) -> some View {
        AppCard(elevation: .raised) {
            VStack(alignment: .leading, spacing: theme.space16) {
                HStack(alignment: .top, spacing: theme.space12) {
                    Circle()
                        .fill(theme.primary.opacity(0.12))
                        .frame(width: 46, height: 46)
                        .overlay(
                            Image(systemName: visualizerVM.currentJobFailedCount > 0 ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                .foregroundStyle(visualizerVM.currentJobFailedCount > 0 ? theme.feedbackWarning : theme.primary)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(jobSummaryTitle)
                            .font(theme.heading2)
                            .foregroundStyle(theme.foreground)
                        Text("\(job.roomName) • \(job.surfaceDescription)")
                            .font(theme.caption)
                            .foregroundStyle(theme.mutedForeground)
                    }
                    Spacer()
                }

                HStack(spacing: theme.space8) {
                    statusPill(
                        value: "\(visualizerVM.currentJobCompletedCount)",
                        label: "Ready",
                        emphasized: visualizerVM.currentJobCompletedCount > 0
                    )
                    statusPill(
                        value: "\(visualizerVM.currentJobFailedCount)",
                        label: "Needs Review",
                        emphasized: visualizerVM.currentJobFailedCount > 0
                    )
                    statusPill(value: "\(visualizerVM.currentJobTotalCount)", label: "Total", emphasized: false)
                }

                Text(jobSummaryMessage)
                    .font(theme.bodySmall)
                    .foregroundStyle(theme.mutedForeground)
                    .fixedSize(horizontal: false, vertical: true)

                if let notice = job.notice ?? visualizerVM.lastGenerationMessage {
                    Text(notice)
                        .font(theme.bodySmall)
                        .foregroundStyle(theme.mutedForeground)
                        .padding(theme.space12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(theme.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
                }
            }
            .padding(theme.space16)
        }
        .padding(.horizontal, theme.spacingMD)
    }

    private func previewsSection(
        title: String,
        detail: String? = nil,
        visualizations: [Visualization]
    ) -> some View {
        VStack(alignment: .leading, spacing: theme.space12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(theme.heading2)
                    .foregroundStyle(theme.foreground)

                if let detail {
                    Text(detail)
                        .font(theme.caption)
                        .foregroundStyle(theme.mutedForeground)
                }
            }
            .padding(.horizontal, theme.spacingMD)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: theme.space12) {
                    ForEach(visualizations) { visualization in
                        Button {
                            openVisualization(visualization)
                        } label: {
                            GalleryPreviewCard(visualization: visualization)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .accessibilityIdentifier("results.readyPreviewCard")
                    }
                }
                .padding(.horizontal, theme.spacingMD)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: theme.space16) {
            Circle()
                .fill(theme.primary.opacity(0.1))
                .frame(width: 72, height: 72)
                .overlay(
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(theme.primary)
                )

            VStack(spacing: theme.space8) {
                Text(hasSavedDesignCards ? "No active results right now" : "No results yet")
                    .font(theme.heading2)
                    .foregroundStyle(theme.foreground)
                Text(
                    hasSavedDesignCards
                        ? "Your finished previews are already saved in Saved > Design Cards."
                        : "Finish a project review and your latest preview will appear here."
                )
                    .font(theme.bodySmall)
                    .foregroundStyle(theme.mutedForeground)
                    .multilineTextAlignment(.center)
            }

            if hasSavedDesignCards {
                AppButton("Open Design Cards", variant: .outline, icon: "bookmark.fill") {
                    tabRouter.openSaved(appState: appState, section: .previews)
                }
                .accessibilityIdentifier("results.empty.openSaved")
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

    private func openVisualization(_ visualization: Visualization) {
        visualizerVM.selectVisualization(visualization.id, projectID: visualization.projectID)
        router.navigate(to: .visualizationDetail(visualization: visualization))
    }

    private var jobSummaryTitle: String {
        if visualizerVM.currentJobFailedCount > 0 {
            return "Preview set needs attention"
        }
        return "Your preview set is ready"
    }

    private var jobSummaryMessage: String {
        if visualizerVM.currentJobFailedCount > 0 {
            return "Some previews need another pass. Review the finished options below and retry anything that missed."
        }
        return "Everything in this room study is ready to review, compare, and adjust."
    }

    private func statusPill(value: String, label: String, emphasized: Bool) -> some View {
        VStack(alignment: .leading, spacing: theme.space2) {
            Text(value)
                .font(theme.heading3)
                .foregroundStyle(emphasized ? theme.foreground : theme.mutedForeground)
            Text(label)
                .font(theme.captionSmall)
                .foregroundStyle(theme.mutedForeground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.space12)
        .background(emphasized ? theme.primary.opacity(0.08) : theme.secondary)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
    }
}

struct ResultsGalleryProcessingPresentation {
    let title: String
    let subtitle: String
    let detail: String?
    let surfaceLine: String
    let helperText: String
    let notice: String?
    let progressAccessibilityValue: String
    let hidesFreshPreviews = true
    let hidesSavedLibrary = true
    let hidesFloatingActionBar = true
    let hidesOpenLatest = true

    init(job: VisualizationJob, completedCount: Int, lastGenerationMessage: String?) {
        let displayTotalCount = job.items.count
        let isSingular = displayTotalCount == 1
        let activeItem = job.items.first(where: \.state.isGenerating) ?? job.items.first(where: \.state.isQueued)
        let activeColorName = activeItem?.color.name ?? "your selected color"
        let normalizedSurface = job.surfaceDescription.lowercased()

        title = isSingular ? "Rendering your preview" : "Rendering your previews"
        subtitle = "Applying \(activeColorName) to \(normalizedSurface) now"
        detail = isSingular ? nil : "\(completedCount) of \(displayTotalCount) ready"
        surfaceLine = "\(job.roomName) • \(job.surfaceDescription)"
        helperText = isSingular
            ? "Rendering continues if you leave this screen. Your preview will appear here automatically when it's ready."
            : "Rendering continues if you leave this screen. Finished previews will appear here automatically."
        notice = job.notice ?? lastGenerationMessage
        if let detail {
            progressAccessibilityValue = "\(detail). \(subtitle)"
        } else {
            progressAccessibilityValue = subtitle
        }
    }

    func statusToken(for state: VisualizationJobItemState) -> String {
        switch state {
        case .queued:
            return "Queued"
        case .generating:
            return "Rendering now"
        case .completed:
            return "Ready"
        case .failed:
            return "Needs review"
        }
    }
}

private struct JobItemCard: View {
    @Environment(Theme.self) private var theme

    let item: VisualizationJobItem
    let action: () -> Void
    let retryAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: theme.space12) {
            HStack(spacing: theme.space12) {
                RoundedRectangle(cornerRadius: theme.radiusLG)
                    .fill(item.color.color)
                    .frame(width: 56, height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radiusLG)
                            .stroke(theme.borderSubtle, lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.color.name)
                        .font(theme.heading3)
                        .foregroundStyle(theme.foreground)
                    Text("\(item.color.brand.displayName) / \(item.color.number)")
                        .font(theme.caption)
                        .foregroundStyle(theme.mutedForeground)
                }

                Spacer()

                statusBadge
            }

            statusBody
        }
        .padding(theme.space16)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusXL)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private var borderColor: Color {
        switch item.state {
        case .completed:
            return theme.primary.opacity(0.24)
        case .failed:
            return theme.feedbackWarning.opacity(0.18)
        default:
            return theme.borderSubtle
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch item.state {
        case .queued:
            Label("Queued", systemImage: "clock")
                .font(theme.captionSmall)
                .foregroundStyle(theme.mutedForeground)
        case .generating:
            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Processing")
                    .font(theme.captionSmall)
            }
            .foregroundStyle(theme.primary)
        case .completed:
            Label("Ready", systemImage: "checkmark.circle.fill")
                .font(theme.captionSmall)
                .foregroundStyle(theme.primary)
        case .failed:
            Label("Needs review", systemImage: "exclamationmark.triangle.fill")
                .font(theme.captionSmall)
                .foregroundStyle(theme.feedbackWarning)
        }
    }

    @ViewBuilder
    private var statusBody: some View {
        switch item.state {
        case .queued, .generating:
            EmptyView()
        case .completed(let result):
            Button(action: action) {
                HStack(spacing: theme.space12) {
                    VisualizationLoadedImageView(
                        visualization: result.visualization,
                        role: .after,
                        preset: .jobCard,
                        contentMode: .fill
                    ) {
                        RoundedRectangle(cornerRadius: theme.radiusLG)
                            .fill(item.color.color.opacity(0.2))
                    }
                    .frame(width: 96, height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(result.roomName)
                            .font(theme.subhead)
                            .foregroundStyle(theme.foreground)
                        Text(result.surface)
                            .font(theme.caption)
                            .foregroundStyle(theme.mutedForeground)
                        Label("Open Preview", systemImage: "arrow.up.right")
                            .font(theme.captionSmall)
                            .foregroundStyle(theme.primary)
                    }

                    Spacer()
                }
            }
            .buttonStyle(.plain)
        case .failed(let message):
            VStack(alignment: .leading, spacing: theme.space12) {
                Text(message)
                    .font(theme.bodySmall)
                    .foregroundStyle(theme.mutedForeground)

                AppButton("Retry Preview", variant: .outline, icon: "arrow.clockwise", action: retryAction)
            }
        }
    }
}

private struct ProcessingJobItemRow: View {
    @Environment(Theme.self) private var theme

    let item: VisualizationJobItem
    let presentation: ResultsGalleryProcessingPresentation

    var body: some View {
        HStack(spacing: theme.space12) {
            RoundedRectangle(cornerRadius: theme.radiusLG)
                .fill(item.color.color)
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radiusLG)
                        .stroke(theme.borderSubtle, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(item.color.name)
                    .font(theme.heading3)
                    .foregroundStyle(theme.foreground)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text("\(item.color.brand.displayName) / \(item.color.number)")
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ProcessingStatusToken(
                state: item.state,
                label: presentation.statusToken(for: item.state)
            )
        }
        .padding(theme.space16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(rowBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusXL)
                .stroke(borderColor, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.color.name), \(presentation.statusToken(for: item.state))")
        .accessibilityIdentifier("results.processing.row.\(item.color.id)")
    }

    private var rowBackgroundColor: Color {
        if case .generating = item.state {
            return theme.primary.opacity(0.06)
        }
        return theme.card
    }

    private var borderColor: Color {
        if case .generating = item.state {
            return theme.primary.opacity(0.24)
        }
        return theme.borderSubtle
    }
}

private struct ProcessingStatusToken: View {
    @Environment(Theme.self) private var theme

    let state: VisualizationJobItemState
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            if case .generating = state {
                ProgressView()
                    .controlSize(.mini)
                    .tint(foregroundColor)
            }

            Text(label)
                .font(theme.captionSmall.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, theme.space8)
        .padding(.vertical, 6)
        .frame(minWidth: 104)
        .background(backgroundColor)
        .clipShape(Capsule())
    }

    private var foregroundColor: Color {
        switch state {
        case .queued:
            return theme.mutedForeground
        case .generating, .completed:
            return theme.primary
        case .failed:
            return theme.feedbackWarning
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .queued:
            return theme.secondary
        case .generating:
            return theme.primary.opacity(0.08)
        case .completed:
            return theme.primary.opacity(0.12)
        case .failed:
            return theme.feedbackWarning.opacity(0.12)
        }
    }
}

private struct ProcessingActivityBar: View {
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -0.4

    var body: some View {
        GeometryReader { geometry in
            let width = max(geometry.size.width * 0.34, 88)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(theme.secondary)

                Capsule()
                    .fill(theme.primary.opacity(reduceMotion ? 0.18 : 0.1))

                if reduceMotion {
                    Capsule()
                        .fill(theme.primary.opacity(0.28))
                        .frame(width: width)
                } else {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.primary.opacity(0.12),
                                    theme.primary.opacity(0.45),
                                    theme.primary.opacity(0.12),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: width)
                        .offset(x: phase * max(geometry.size.width + width, width))
                        .onAppear {
                            phase = -0.4
                            withAnimation(.linear(duration: 1.15).repeatForever(autoreverses: false)) {
                                phase = 1
                            }
                        }
                }
            }
            .clipShape(Capsule())
        }
        .frame(height: 12)
    }
}

struct GalleryPreviewCard: View {
    @Environment(Theme.self) private var theme
    let visualization: Visualization

    var body: some View {
        VStack(alignment: .leading, spacing: theme.space8) {
            VisualizationLoadedImageView(
                visualization: visualization,
                role: .after,
                preset: .galleryCard,
                contentMode: .fill
            ) {
                RoundedRectangle(cornerRadius: theme.radiusLG)
                    .fill(Color(hex: visualization.colorHex).opacity(0.24))
            }
            .frame(width: 190, height: 220)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))

            VStack(alignment: .leading, spacing: 4) {
                Text(visualization.colorName)
                    .font(theme.heading3)
                    .foregroundStyle(theme.foreground)
                    .lineLimit(1)
                Text(visualization.roomName)
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
                Label("Open Preview", systemImage: "arrow.up.right")
                    .font(theme.captionSmall)
                    .foregroundStyle(theme.primary)
            }
            .padding(.horizontal, theme.space4)
        }
        .frame(width: 200, alignment: .leading)
        .padding(theme.space12)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusXL)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
    }
}
