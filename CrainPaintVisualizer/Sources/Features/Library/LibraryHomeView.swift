import SwiftUI
import UIKit

struct LibraryHomeView: View {
    @Environment(Theme.self) private var theme
    @Environment(AppState.self) private var appState
    @Environment(TabRouter.self) private var tabRouter
    @Environment(RouterPath.self) private var router
    @Environment(VisualizerViewModel.self) private var visualizerVM
    @Environment(FavoritesViewModel.self) private var favoritesVM
    @Environment(ReportsViewModel.self) private var reportsVM

    private let projectColumns = [GridItem(.adaptive(minimum: 250), spacing: 16)]
    private let colorColumns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: theme.space20) {
                header
                sectionPicker
                sectionContent
            }
            .padding(.bottom, theme.spacingXL)
        }
        .background(theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .animation(Theme.animationDefault, value: appState.selectedLibrarySection)
        .task {
            await reportsVM.refreshReports()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: theme.space12) {
            CompactScreenHeader(
                title: "Library",
                subtitle: librarySubtitle,
                detail: appState.selectedLibrarySection.rawValue
            )

            HStack(spacing: theme.space8) {
                statPill(
                    icon: "square.stack.3d.up.fill",
                    text: "\(visualizerVM.projects.count) Projects",
                    foreground: theme.foreground,
                    background: theme.secondary
                )
                statPill(
                    icon: "heart.fill",
                    text: "\(favoritesVM.favorites.count) Colors",
                    foreground: theme.primary,
                    background: theme.primary.opacity(0.12)
                )
                statPill(
                    icon: "doc.text.fill",
                    text: "\(reportsVM.reports.count) Reports",
                    foreground: theme.foreground,
                    background: theme.secondary
                )
            }
            .padding(.horizontal, theme.spacingMD)
        }
    }

    private var sectionPicker: some View {
        Picker("Library Section", selection: Bindable(appState).selectedLibrarySection) {
            ForEach(LibrarySection.allCases) { section in
                Text(section.rawValue).tag(section)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, theme.spacingMD)
        .accessibilityIdentifier("library.sectionPicker")
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch appState.selectedLibrarySection {
        case .projects:
            projectsSection
        case .colors:
            colorsSection
        case .reports:
            reportsSection
        }
    }

    private var projectsSection: some View {
        VStack(alignment: .leading, spacing: theme.space16) {
            sectionIntro(
                title: "Room projects",
                body: "Resume active rooms, reopen results, or continue a draft where you left off."
            )

            if visualizerVM.projects.isEmpty {
                emptyCard(
                    title: "No room projects yet",
                    body: "Start with a room photo and each project will stay organized here with its colors, previews, and reports.",
                    buttonLabel: "Start My First Project",
                    icon: "sparkles.rectangle.stack.fill"
                ) {
                    tabRouter.openPreview(appState: appState, route: .photoUpload)
                }
            } else {
                LazyVGrid(columns: projectColumns, spacing: 16) {
                    ForEach(visualizerVM.projects) { project in
                        let summary = projectSummary(for: project)
                        ProjectLibraryCard(
                            project: project,
                            summary: summary,
                            isActive: visualizerVM.activeProjectID == project.id,
                            actionTitle: projectActionTitle(for: project)
                        ) {
                            openProject(project)
                        }
                    }
                }
                .padding(.horizontal, theme.spacingMD)
            }
        }
        .accessibilityIdentifier("library.section.projects")
    }

    private var colorsSection: some View {
        VStack(alignment: .leading, spacing: theme.space16) {
            sectionIntro(
                title: "Saved colors",
                body: "Tap a favorite color to carry that color back into a new room preview."
            )

            HStack(spacing: theme.space12) {
                AppButton("Open Matcher", variant: .outline, icon: "camera.viewfinder") {
                    tabRouter.openPreview(appState: appState, route: .colorMatcher)
                }

                AppButton("Start From Scratch", variant: .ghost, icon: "arrow.clockwise") {
                    visualizerVM.prepareFreshProject()
                    tabRouter.openPreview(appState: appState, route: .photoUpload)
                }
            }
            .padding(.horizontal, theme.spacingMD)

            if favoritesVM.favorites.isEmpty {
                emptyCard(
                    title: "No saved colors yet",
                    body: "Save colors from the matcher, preview detail, or reports to keep a shortlist ready for future rooms.",
                    buttonLabel: "Try The Color Matcher",
                    icon: "paintpalette.fill"
                ) {
                    tabRouter.openPreview(appState: appState, route: .colorMatcher)
                }
            } else {
                LazyVGrid(columns: colorColumns, spacing: 16) {
                    ForEach(favoritesVM.favorites) { color in
                        ColorLibraryCard(color: color) {
                            visualizerVM.startFlow(with: color)
                            tabRouter.openPreview(appState: appState, route: .photoUpload)
                        }
                    }
                }
                .padding(.horizontal, theme.spacingMD)
            }
        }
        .accessibilityIdentifier("library.section.colors")
    }

    private var reportsSection: some View {
        VStack(alignment: .leading, spacing: theme.space16) {
            sectionIntro(
                title: "Consultation reports",
                body: "Keep every walkthrough, pending consultation, and finished recommendation easy to reopen."
            )

            if reportsVM.reports.isEmpty {
                emptyCard(
                    title: "No reports yet",
                    body: "Consultation reports appear here after checkout and stay available while they generate and once they are ready.",
                    buttonLabel: "Explore Consultation",
                    icon: "person.crop.circle.fill"
                ) {
                    tabRouter.openMore(appState: appState)
                }
            } else {
                if let featuredReport = reportsVM.readyReports.first ?? reportsVM.reports.first {
                    ReportFeaturedCard(report: featuredReport) {
                        router.navigate(to: .masterReport(reportId: featuredReport.id))
                    }
                    .padding(.horizontal, theme.spacingMD)
                }

                VStack(spacing: theme.space12) {
                    ForEach(reportsVM.reports) { report in
                        LibraryReportRow(report: report) {
                            router.navigate(to: .masterReport(reportId: report.id))
                        }
                    }
                }
                .padding(.horizontal, theme.spacingMD)
            }
        }
        .accessibilityIdentifier("library.section.reports")
    }

    private var librarySubtitle: String {
        switch appState.selectedLibrarySection {
        case .projects:
            return "Projects keep rooms, previews, and next steps together."
        case .colors:
            return "Saved colors stay ready for the next room you test."
        case .reports:
            return "Consultations and walkthroughs live here once they are underway."
        }
    }

    private func projectSummary(for project: RoomProject) -> ProjectCardSummary {
        let results = visualizerVM.results(for: project.id)
        let leadVisualization = selectedVisualization(for: project, results: results)
        let reportCount = matchingReports(for: project).count

        return ProjectCardSummary(
            leadVisualization: leadVisualization,
            resultCount: results.count,
            shortlistCount: project.shortlistedVisualizationIDs.count,
            reportCount: reportCount,
            hasPhoto: project.hasPhoto,
            directionCount: project.candidateColors.count
        )
    }

    private func matchingReports(for project: RoomProject) -> [MasterReport] {
        reportsVM.reports.filter { report in
            if let reportProjectID = report.projectID, reportProjectID == project.id {
                return true
            }
            return project.reportIDs.contains(report.id)
        }
    }

    private func selectedVisualization(
        for project: RoomProject,
        results: [VisualizationResult]
    ) -> Visualization? {
        if let selectedID = project.selectedVisualizationID,
           let selected = results.first(where: { $0.id == selectedID })?.visualization {
            return selected
        }

        return results.first?.visualization
    }

    private func openProject(_ project: RoomProject) {
        let route = projectRoute(for: project)
        Task {
            await visualizerVM.activateProject(project.id)
            tabRouter.openPreview(appState: appState, route: route)
        }
    }

    private func projectRoute(for project: RoomProject) -> AppRoute {
        let hasResults = !visualizerVM.results(for: project.id).isEmpty || !project.visualizationIDs.isEmpty
        if hasResults {
            return .results(projectID: project.id)
        }
        if !project.hasPhoto {
            return .photoUpload
        }
        let hasValidSurface = project.selectedSurface != nil && (
            project.selectedSurface != .custom ||
            !project.customSurfaceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        )
        if !hasValidSurface {
            return .surfacePicker
        }
        if project.candidateColors.isEmpty {
            return .itemPicker
        }
        return .projectReview
    }

    private func projectActionTitle(for project: RoomProject) -> String {
        switch projectRoute(for: project) {
        case .results:
            return "Open Results"
        case .itemPicker:
            return "Choose Colors"
        case .surfacePicker:
            return "Choose Surface"
        case .projectReview:
            return "Review Project"
        default:
            return "Resume Project"
        }
    }

    private func sectionIntro(title: String, body: String) -> some View {
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

    private func emptyCard(
        title: String,
        body: String,
        buttonLabel: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: theme.space16) {
            Circle()
                .fill(theme.primary.opacity(0.08))
                .frame(width: 72, height: 72)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(theme.primary)
                )

            VStack(spacing: theme.space8) {
                Text(title)
                    .font(theme.heading2)
                    .foregroundStyle(theme.foreground)
                Text(body)
                    .font(theme.bodySmall)
                    .foregroundStyle(theme.mutedForeground)
                    .multilineTextAlignment(.center)
            }

            AppButton(buttonLabel, variant: .outline, icon: "arrow.right", action: action)
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

    private func statPill(
        icon: String,
        text: String,
        foreground: Color,
        background: Color
    ) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(theme.captionSmall)
                .fontWeight(.semibold)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(background)
        .clipShape(Capsule())
    }
}

private struct ProjectCardSummary {
    let leadVisualization: Visualization?
    let resultCount: Int
    let shortlistCount: Int
    let reportCount: Int
    let hasPhoto: Bool
    let directionCount: Int
}

private struct ProjectLibraryCard: View {
    @Environment(Theme.self) private var theme

    let project: RoomProject
    let summary: ProjectCardSummary
    let isActive: Bool
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: theme.space16) {
                ProjectCardHero(project: project, leadVisualization: summary.leadVisualization)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
                    .overlay(alignment: .topLeading) {
                        HStack(spacing: theme.space8) {
                            AppBadge(text: project.state.libraryLabel, isFilled: project.state.isEmphasized)
                            if isActive {
                                AppBadge(text: "Active", isFilled: true)
                            }
                        }
                        .padding(theme.space12)
                    }

                VStack(alignment: .leading, spacing: theme.space8) {
                    Text(project.title)
                        .font(theme.heading2)
                        .foregroundStyle(theme.foreground)
                        .lineLimit(2)

                    Text(projectSubtitle)
                        .font(theme.bodySmall)
                        .foregroundStyle(theme.mutedForeground)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: theme.space8) {
                        summaryPill(value: "\(summary.directionCount)", label: "Colors")
                        if summary.hasPhoto {
                            summaryPill(value: "1", label: "Photo")
                        }
                        if summary.resultCount > 0 {
                            summaryPill(value: "\(summary.resultCount)", label: "Previews")
                        }
                        if summary.shortlistCount > 0 {
                            summaryPill(value: "\(summary.shortlistCount)", label: "Finalists")
                        }
                        if summary.reportCount > 0 {
                            summaryPill(value: "\(summary.reportCount)", label: "Reports")
                        }
                    }
                }

                HStack {
                    Text(project.updatedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(theme.caption)
                        .foregroundStyle(theme.mutedForeground)

                    Spacer()

                    Label(actionTitle, systemImage: "arrow.up.right")
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
            .shadow(color: .black.opacity(0.05), radius: 16, y: 8)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityIdentifier("library.project.\(project.id)")
    }

    private var projectSubtitle: String {
        switch project.state {
        case .idle:
            return "Room started. Add a photo to move into a realistic preview."
        case .photoAdded:
            return "Photo is ready. Choose the surface you want to repaint next."
        case .surfaceSelected:
            return "Surface is set. Choose colors and then review before rendering."
        case .directionSelected:
            return "Colors are saved. Review the project and generate previews when ready."
        case .rendering:
            return "This project is rendering now. Reopen it to follow the live preview set."
        case .resultsReady:
            return "Previews are ready to compare, save, and reopen."
        case .resultsPartial:
            return "Some previews are ready and some still need attention."
        case .resultsFailed:
            return "The last render set needs review before you continue."
        case .shortlisted:
            return "This project has saved finalists and is ready for a final decision."
        case .optionalConsultation:
            return "Strong options are ready. Consultation can help with the final call."
        }
    }

    private func summaryPill(value: String, label: String) -> some View {
        HStack(spacing: 4) {
            Text(value)
                .font(theme.captionSmall.weight(.bold))
            Text(label)
                .font(theme.captionSmall)
        }
        .foregroundStyle(theme.foreground)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(theme.secondary)
        .clipShape(Capsule())
    }
}

private struct ProjectCardHero: View {
    @Environment(Theme.self) private var theme

    let project: RoomProject
    let leadVisualization: Visualization?

    @State private var projectPhoto: UIImage?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let leadVisualization {
                    VisualizationLoadedImageView(
                        visualization: leadVisualization,
                        role: .after,
                        preset: .savedGrid,
                        contentMode: .fill
                    ) {
                        projectPlaceholder
                    }
                } else if let projectPhoto {
                    Image(uiImage: projectPhoto)
                        .resizable()
                        .scaledToFill()
                } else {
                    projectPlaceholder
                }
            }

            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.08), Color.black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: theme.space4) {
                Text(project.selectedSurface?.userFacingDescription(customSurfaceText: project.customSurfaceText) ?? "Room preview")
                    .font(theme.captionSmall.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.84))
                Text(project.preferredBrand.displayName)
                    .font(theme.micro.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(.white)
            }
            .padding(theme.space16)
        }
        .task(id: project.photoAsset?.id ?? project.photoFileName ?? "none") {
            guard leadVisualization == nil else { return }
            projectPhoto = await loadProjectPhoto(for: project)
        }
    }

    private var projectPlaceholder: some View {
        LinearGradient(
            colors: [theme.secondary, theme.card, theme.secondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            VStack(spacing: theme.space12) {
                Circle()
                    .fill(theme.primary.opacity(0.12))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(theme.primary)
                    )
                Text("Preview saved here")
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
            }
        }
    }

    private func loadProjectPhoto(for project: RoomProject) async -> UIImage? {
        if let photoAsset = project.photoAsset {
            return await PhotoProcessingService.shared.loadDisplayImage(
                for: photoAsset,
                maxPixelSize: 960
            )
        }

        let fileName = project.photoFileName
        guard let fileName else { return nil }
        let url = AppStorage.fileURL(for: "room-project-assets").appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}

private struct ColorLibraryCard: View {
    @Environment(Theme.self) private var theme

    let color: PaintColor
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                RoundedRectangle(cornerRadius: theme.radiusLG)
                    .fill(color.color)
                    .frame(height: 128)
                    .overlay(alignment: .topLeading) {
                        Text(color.family.uppercased())
                            .font(theme.micro.weight(.bold))
                            .tracking(1)
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.16))
                            .clipShape(Capsule())
                            .padding(12)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(color.name)
                        .font(theme.heading3)
                        .foregroundStyle(theme.foreground)
                        .lineLimit(2)
                    Text("\(color.brand.displayName) • \(color.number)")
                        .font(theme.caption)
                        .foregroundStyle(theme.mutedForeground)
                }
                .padding(theme.space12)
            }
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

private struct ReportFeaturedCard: View {
    @Environment(Theme.self) private var theme

    let report: MasterReport
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: theme.space16) {
                HStack(alignment: .top, spacing: theme.space12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(report.status.isReady ? "Latest report" : "Consultation status")
                            .font(theme.micro.weight(.bold))
                            .tracking(1)
                            .foregroundStyle(theme.primary)

                        Text(report.title)
                            .font(theme.heading1)
                            .foregroundStyle(theme.foreground)

                        Text(report.statusMessage ?? report.curatorSubtitle)
                            .font(theme.bodySmall)
                            .foregroundStyle(theme.mutedForeground)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    AppBadge(text: report.status.libraryLabel, isFilled: report.status.isReady)
                }

                LibraryReportHero(report: report)
                    .frame(height: 210)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
            }
            .padding(theme.space16)
            .background(theme.card)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radiusXL)
                    .stroke(theme.borderSubtle, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

private struct LibraryReportHero: View {
    @Environment(Theme.self) private var theme

    let report: MasterReport

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let imageName = report.videoThumbnailName {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [Color(hex: "7A695C"), Color(hex: "344956"), Color(hex: "1E2732")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }

            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.12), Color.black.opacity(0.46)],
                startPoint: .top,
                endPoint: .bottom
            )

            HStack(spacing: theme.space12) {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: report.status.isReady ? "play.fill" : "clock.fill")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(report.videoTitle)
                        .font(theme.heading3)
                        .foregroundStyle(.white)
                    Text(report.status.isReady ? "\(report.recommendations.count) room recommendations" : "We'll update this as the report progresses")
                        .font(theme.caption)
                        .foregroundStyle(.white.opacity(0.82))
                }
            }
            .padding(theme.space16)
        }
    }
}

private struct LibraryReportRow: View {
    @Environment(Theme.self) private var theme

    let report: MasterReport
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: theme.space12) {
                Circle()
                    .fill(report.status == .ready ? theme.primary.opacity(0.12) : theme.secondary)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: report.status == .ready ? "doc.text.fill" : "clock.fill")
                            .foregroundStyle(report.status == .ready ? theme.primary : theme.foreground)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(report.title)
                        .font(theme.heading3)
                        .foregroundStyle(theme.foreground)
                        .lineLimit(2)
                    Text(report.statusMessage ?? report.curatorSubtitle)
                        .font(theme.caption)
                        .foregroundStyle(theme.mutedForeground)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    AppBadge(text: report.status.libraryLabel, isFilled: report.status.isReady)
                    Text((report.updatedAt ?? report.createdAt).formatted(date: .abbreviated, time: .omitted))
                        .font(theme.captionSmall)
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
        .buttonStyle(ScaleButtonStyle())
    }
}

private extension RoomProjectState {
    var libraryLabel: String {
        switch self {
        case .idle:
            return "Room Started"
        case .photoAdded:
            return "Photo Ready"
        case .surfaceSelected:
            return "Surface Ready"
        case .directionSelected:
            return "Direction Ready"
        case .rendering:
            return "Rendering"
        case .resultsReady:
            return "Results Ready"
        case .resultsPartial:
            return "Needs Review"
        case .resultsFailed:
            return "Retry Needed"
        case .shortlisted:
            return "Finalists Saved"
        case .optionalConsultation:
            return "Consultation Ready"
        }
    }

    var isEmphasized: Bool {
        switch self {
        case .rendering, .resultsReady, .shortlisted, .optionalConsultation:
            return true
        default:
            return false
        }
    }
}

private extension ReportStatus {
    var libraryLabel: String {
        switch self {
        case .generating:
            return "Generating"
        case .ready:
            return "Ready"
        case .failed:
            return "Needs Review"
        }
    }
}
