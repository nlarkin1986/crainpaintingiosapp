import StripePaymentSheet
import SwiftUI

@main
struct CrainPaintVisualizerApp: App {
    @State private var appState = AppState()
    @State private var theme = Theme()
    @State private var tabRouter = TabRouter()
    @State private var visualizerVM = VisualizerViewModel()
    @State private var favoritesVM = FavoritesViewModel()
    @State private var reportsVM = ReportsViewModel()

    init() {
        if ProcessInfo.processInfo.arguments.contains("UITEST_DISABLE_ANIMATIONS") {
            UIView.setAnimationsEnabled(false)
        }

        Task(priority: .utility) {
            await SharedColorCatalogStore.shared.prewarm(brand: .benjaminMoore)
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.onboardingComplete {
                    let selectedRouter = tabRouter.router(for: appState.selectedTab)
                    let showsPersistentTabBar = selectedRouter.path.last?.showsPersistentTabBar ?? true

                    ZStack {
                        theme.background.ignoresSafeArea()

                        VStack(spacing: 0) {
                            tabStacks
                                .frame(maxWidth: .infinity, maxHeight: .infinity)

                            if showsPersistentTabBar {
                                CustomTabBar(
                                    selectedTab: $appState.selectedTab,
                                    onDoubleTap: { tab in
                                        tabRouter.router(for: tab).reset()
                                    }
                                )
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                    }
                    .ignoresSafeArea(.keyboard)
                    .animation(.easeInOut(duration: 0.2), value: showsPersistentTabBar)
                } else {
                    WelcomeView()
                }
            }
            .environment(theme)
            .environment(appState)
            .environment(tabRouter)
            .environment(visualizerVM)
            .environment(favoritesVM)
            .environment(reportsVM)
            .onOpenURL { url in
                if StripeAPI.handleURLCallback(with: url) {
                    return
                }
                tabRouter.handle(
                    url: url,
                    appState: appState,
                    activeProjectID: visualizerVM.activeProjectID
                )
            }
        }
    }

    private var tabStacks: some View {
        ZStack {
            tabStack(for: .preview)
                .tabStackVisibility(isActive: appState.selectedTab == .preview)

            tabStack(for: .library)
                .tabStackVisibility(isActive: appState.selectedTab == .library)

            tabStack(for: .more)
                .tabStackVisibility(isActive: appState.selectedTab == .more)
        }
    }

    private func tabStack(for tab: AppTab) -> some View {
        NavigationStack(path: tabRouter.binding(for: tab)) {
            tab.makeContentView()
                .withAppRouter()
        }
        .environment(tabRouter.router(for: tab))
    }
}

private extension View {
    @ViewBuilder
    func tabStackVisibility(isActive: Bool) -> some View {
        self
            .opacity(isActive ? 1 : 0)
            .allowsHitTesting(isActive)
            .accessibilityHidden(!isActive)
            .zIndex(isActive ? 1 : 0)
    }
}
