import SwiftUI
import StripePaymentSheet

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
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.onboardingComplete {
                    VStack(spacing: 0) {
                        ZStack {
                            ForEach(AppTab.allCases) { tab in
                                NavigationStack(path: tabRouter.binding(for: tab)) {
                                    tab.makeContentView()
                                        .withAppRouter()
                                }
                                .environment(tabRouter.router(for: tab))
                                .opacity(appState.selectedTab == tab ? 1 : 0)
                                .allowsHitTesting(appState.selectedTab == tab)
                            }
                        }

                        CustomTabBar(
                            selectedTab: $appState.selectedTab,
                            onDoubleTap: { tab in
                                tabRouter.router(for: tab).reset()
                            }
                        )
                    }
                    .ignoresSafeArea(.keyboard)
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
                tabRouter.handle(url: url, appState: appState)
            }
        }
    }
}
