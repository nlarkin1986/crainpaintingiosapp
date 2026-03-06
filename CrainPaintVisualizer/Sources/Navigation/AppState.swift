import SwiftUI

@MainActor
@Observable
final class AppState {
    private static let onboardingKey = "onboardingComplete"
    private let userDefaults: UserDefaults

    var selectedTab: AppTab = .visualize
    var onboardingComplete: Bool {
        didSet {
            userDefaults.set(onboardingComplete, forKey: Self.onboardingKey)
        }
    }

    init(userDefaults: UserDefaults = .standard, processInfo: ProcessInfo = .processInfo) {
        self.userDefaults = userDefaults
        let arguments = Set(processInfo.arguments)
        if arguments.contains("UITEST_RESET_STATE") {
            userDefaults.removeObject(forKey: Self.onboardingKey)
            AppStorage.resetAllFiles()
        }

        if arguments.contains("UITEST_SKIP_ONBOARDING") {
            onboardingComplete = true
        } else {
            onboardingComplete = userDefaults.bool(forKey: Self.onboardingKey)
        }
    }
}
