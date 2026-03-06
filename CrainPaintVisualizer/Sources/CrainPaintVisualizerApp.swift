import SwiftUI

@main
struct CrainPaintVisualizerApp: App {
    @State private var appState = AppState()
    @State private var theme = Theme()
    @State private var tabRouter = TabRouter()

    var body: some Scene {
        WindowGroup {
            if appState.onboardingComplete {
                TabView(selection: $appState.selectedTab) {
                    ForEach(AppTab.allCases) { tab in
                        NavigationStack(path: tabRouter.binding(for: tab)) {
                            tab.makeContentView()
                                .withAppRouter()
                        }
                        .environment(tabRouter.router(for: tab))
                        .tabItem { tab.label }
                        .tag(tab)
                    }
                }
                .environment(theme)
                .environment(appState)
            } else {
                WelcomeView()
                    .environment(theme)
                    .environment(appState)
            }
        }
    }
}
