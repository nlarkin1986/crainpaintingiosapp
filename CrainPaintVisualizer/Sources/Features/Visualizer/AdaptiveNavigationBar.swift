import SwiftUI

// MARK: - Navigation State Management

/// Defines the navigation mode for the app
enum NavigationMode: Equatable {
    case browse                 // Show full tab bar
    case focused(FocusedFlow)   // Hide tabs, show contextual actions
}

/// Focused flows that require full attention
enum FocusedFlow: Equatable {
    case visualization(step: VisualizationStep)
    case reportReading(reportId: String)
    case expertConsultation
}

/// Steps in the visualization workflow
enum VisualizationStep: Equatable {
    case brandSelection
    case colorPicking(selectedCount: Int)
    case photoUpload
    case surfaceSelection
    case results(visualizationId: String)
    
    var stepNumber: Int {
        switch self {
        case .brandSelection: return 0
        case .colorPicking: return 1
        case .photoUpload: return 2
        case .surfaceSelection: return 3
        case .results: return 4
        }
    }
    
    var totalSteps: Int { 3 }
    
    var progressDescription: String {
        switch self {
        case .brandSelection: return "Select Brand"
        case .colorPicking(let count): 
            return count > 0 ? "\(count) color\(count == 1 ? "" : "s") selected" : "Pick Colors"
        case .photoUpload: return "Add Photo"
        case .surfaceSelection: return "Choose Surface"
        case .results: return "Your Visualization"
        }
    }
}

// MARK: - Navigation State Observable

@MainActor
@Observable
final class NavigationState {
    var mode: NavigationMode = .browse
    var currentTab: AppTab = .visualize
    
    // MARK: - Mode Management
    
    func enterFocusedMode(_ flow: FocusedFlow) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            mode = .focused(flow)
        }
    }
    
    func exitFocusedMode() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            mode = .browse
        }
    }
    
    // MARK: - Visualization Flow Helpers
    
    func updateVisualizationStep(_ step: VisualizationStep) {
        mode = .focused(.visualization(step: step))
    }
    
    func beginVisualization() {
        enterFocusedMode(.visualization(step: .brandSelection))
    }
    
    func completeVisualization() {
        exitFocusedMode()
        currentTab = .visualize
    }
    
    // MARK: - Report Flow Helpers
    
    func openReport(id: String) {
        enterFocusedMode(.reportReading(reportId: id))
    }
    
    // MARK: - Expert Flow Helpers
    
    func startExpertConsultation() {
        enterFocusedMode(.expertConsultation)
    }
}

// MARK: - Adaptive Navigation Bar

/// Main navigation component that adapts based on context
struct AdaptiveNavigationBar: View {
    @Environment(NavigationState.self) private var navState
    @Environment(Theme.self) private var theme
    
    var body: some View {
        Group {
            switch navState.mode {
            case .browse:
                // Standard tab bar for browsing
                CustomTabBar(
                    selectedTab: Binding(
                        get: { navState.currentTab },
                        set: { newValue in
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                navState.currentTab = newValue
                            }
                        }
                    ),
                    onDoubleTap: { _ in
                        // Could scroll to top or refresh
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                
            case .focused(let flow):
                // Context-aware footer for focused tasks
                FocusedModeFooter(flow: flow)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: navState.mode)
    }
}

// MARK: - Focused Mode Footer

/// Compact, context-aware navigation for focused flows
struct FocusedModeFooter: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @Environment(VisualizerViewModel.self) private var visualizerVM
    @Environment(NavigationState.self) private var navState
    
    let flow: FocusedFlow
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: theme.spacingMD) {
                contextContent
            }
            .padding(.horizontal, theme.spacingLG)
            .padding(.vertical, theme.spacingMD)
            .background(.ultraThinMaterial)
        }
        .frame(minHeight: 52)
    }
    
    @ViewBuilder
    private var contextContent: some View {
        switch flow {
        case .visualization(let step):
            visualizationFooter(for: step)
        case .reportReading(let reportId):
            reportFooter(reportId: reportId)
        case .expertConsultation:
            expertFooter
        }
    }
    
    // MARK: - Visualization Footer Variants
    
    @ViewBuilder
    private func visualizationFooter(for step: VisualizationStep) -> some View {
        switch step {
        case .brandSelection:
            brandSelectionFooter
            
        case .colorPicking(let count):
            colorPickingFooter(count: count)
            
        case .photoUpload:
            photoUploadFooter
            
        case .surfaceSelection:
            surfaceSelectionFooter
            
        case .results(let visualizationId):
            resultsFooter(visualizationId: visualizationId)
        }
    }
    
    private var brandSelectionFooter: some View {
        HStack {
            stepProgress(current: 0, total: 3)
            
            Spacer()
            
            Button {
                router.navigate(to: .itemPicker)
                navState.updateVisualizationStep(.colorPicking(selectedCount: 0))
            } label: {
                HStack(spacing: 6) {
                    Text("Continue")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .foregroundStyle(.white)
                .padding(.horizontal, theme.spacingLG)
                .padding(.vertical, 10)
                .background(theme.actionPrimary)
                .clipShape(Capsule())
            }
            .disabled(visualizerVM.selectedBrand == nil)
        }
    }
    
    private func colorPickingFooter(count: Int) -> some View {
        HStack(spacing: theme.spacingMD) {
            if count > 0 {
                // Mini color preview
                HStack(spacing: -8) {
                    ForEach(visualizerVM.selectedColors.prefix(5)) { color in
                        Circle()
                            .fill(color.color)
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                    }
                }
                
                Text("\(count) Selected")
                    .font(theme.body)
                    .foregroundStyle(theme.foreground)
            } else {
                stepProgress(current: 1, total: 3)
            }
            
            Spacer()
            
            Button {
                router.navigate(to: .photoUpload)
                navState.updateVisualizationStep(.photoUpload)
            } label: {
                HStack(spacing: 6) {
                    Text("Next Step")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .foregroundStyle(.white)
                .padding(.horizontal, theme.spacingLG)
                .padding(.vertical, 10)
                .background(count > 0 ? theme.actionPrimary : theme.muted)
                .clipShape(Capsule())
            }
            .disabled(count == 0)
        }
    }
    
    private var photoUploadFooter: some View {
        HStack {
            Button {
                router.pop()
                navState.updateVisualizationStep(.colorPicking(selectedCount: visualizerVM.selectedColors.count))
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundStyle(theme.foreground)
            }
            
            stepProgress(current: 2, total: 3)
            
            Spacer()
            
            Button {
                // Upload photo action
                router.navigate(to: .surfacePicker)
                navState.updateVisualizationStep(.surfaceSelection)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "photo")
                    Text("Upload Photo")
                }
                .foregroundStyle(.white)
                .padding(.horizontal, theme.spacingLG)
                .padding(.vertical, 10)
                .background(theme.actionPrimary)
                .clipShape(Capsule())
            }
        }
    }
    
    private var surfaceSelectionFooter: some View {
        HStack {
            Button {
                router.pop()
                navState.updateVisualizationStep(.photoUpload)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundStyle(theme.foreground)
            }
            
            stepProgress(current: 3, total: 3)
            
            Spacer()
            
            Button {
                router.navigate(to: .resultsGallery)
                navState.updateVisualizationStep(.results(visualizationId: UUID().uuidString))
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("Visualize")
                }
                .foregroundStyle(.white)
                .padding(.horizontal, theme.spacingLG)
                .padding(.vertical, 10)
                .background(theme.actionPrimary)
                .clipShape(Capsule())
            }
        }
    }
    
    private func resultsFooter(visualizationId: String) -> some View {
        HStack(spacing: theme.spacingLG) {
            // Cross-feature actions appear here!
            footerActionButton("Save", icon: "heart") {
                // Save to favorites
            }
            
            footerActionButton("Share", icon: "square.and.arrow.up") {
                // Share visualization
            }
            
            footerActionButton("Expert", icon: "person.crop.circle") {
                // Open expert consultation
                navState.startExpertConsultation()
            }
            
            Spacer()
            
            Button {
                visualizerVM.reset()
                router.reset()
                navState.completeVisualization()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("New")
                }
                .foregroundStyle(.white)
                .padding(.horizontal, theme.spacingMD)
                .padding(.vertical, 10)
                .background(theme.actionPrimary)
                .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Report Footer
    
    private func reportFooter(reportId: String) -> some View {
        HStack {
            Button {
                navState.exitFocusedMode()
                router.pop()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Close")
                }
                .foregroundStyle(theme.foreground)
            }
            
            Spacer()
            
            Button {
                router.navigate(to: .consultationCheckout(reportId: reportId))
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle")
                    Text("Request Consultation")
                }
                .foregroundStyle(.white)
                .padding(.horizontal, theme.spacingLG)
                .padding(.vertical, 10)
                .background(theme.actionPrimary)
                .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Expert Footer
    
    private var expertFooter: some View {
        HStack {
            Button {
                navState.exitFocusedMode()
                router.pop()
            } label: {
                Text("Cancel")
                    .foregroundStyle(theme.foreground)
            }
            
            Spacer()
            
            Button {
                // Schedule call action
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "video")
                    Text("Schedule Call")
                }
                .foregroundStyle(.white)
                .padding(.horizontal, theme.spacingLG)
                .padding(.vertical, 10)
                .background(theme.actionPrimary)
                .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func footerActionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption2)
            }
            .foregroundStyle(theme.foreground)
        }
    }
    
    private func stepProgress(current: Int, total: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index <= current ? theme.actionPrimary : theme.muted)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

// MARK: - View Modifiers for Easy Adoption

extension View {
    /// Automatically enters focused mode when view appears
    func focusedMode(_ flow: FocusedFlow) -> some View {
        modifier(FocusedModeModifier(flow: flow))
    }
}

private struct FocusedModeModifier: ViewModifier {
    @Environment(NavigationState.self) private var navState
    let flow: FocusedFlow
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                navState.enterFocusedMode(flow)
            }
            .onDisappear {
                // Only exit if we're still in this flow
                if case .focused(let currentFlow) = navState.mode, currentFlow == flow {
                    navState.exitFocusedMode()
                }
            }
    }
}

// MARK: - Preview Helpers

#Preview("Color Picking") {
    @Previewable @State var navState = NavigationState()
    @Previewable @State var router = RouterPath()
    @Previewable @State var theme = Theme()
    @Previewable @State var visualizerVM = VisualizerViewModel()
    
    VStack {
        Spacer()
        AdaptiveNavigationBar()
    }
    .environment(navState)
    .environment(router)
    .environment(theme)
    .environment(visualizerVM)
    .onAppear {
        navState.updateVisualizationStep(.colorPicking(selectedCount: 3))
    }
}

#Preview("Results") {
    @Previewable @State var navState = NavigationState()
    @Previewable @State var router = RouterPath()
    @Previewable @State var theme = Theme()
    @Previewable @State var visualizerVM = VisualizerViewModel()
    
    VStack {
        Spacer()
        AdaptiveNavigationBar()
    }
    .environment(navState)
    .environment(router)
    .environment(theme)
    .environment(visualizerVM)
    .onAppear {
        navState.updateVisualizationStep(.results(visualizationId: "123"))
    }
}

#Preview("Browse Mode") {
    @Previewable @State var navState = NavigationState()
    @Previewable @State var router = RouterPath()
    @Previewable @State var theme = Theme()
    @Previewable @State var visualizerVM = VisualizerViewModel()
    
    VStack {
        Spacer()
        AdaptiveNavigationBar()
    }
    .environment(navState)
    .environment(router)
    .environment(theme)
    .environment(visualizerVM)
}
