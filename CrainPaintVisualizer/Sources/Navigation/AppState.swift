import SwiftUI

@MainActor
@Observable
final class AppState {
    var selectedTab: AppTab = .visualize
    var isAuthenticated = false

    var onboardingComplete: Bool {
        get { UserDefaults.standard.bool(forKey: "onboardingComplete") }
        set { UserDefaults.standard.set(newValue, forKey: "onboardingComplete") }
    }
}
