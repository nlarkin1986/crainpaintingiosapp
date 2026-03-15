import SwiftUI

enum SavedLandingSection: String, CaseIterable, Identifiable {
    case previews = "Projects"
    case colors = "Colors"
    case reports = "Reports"

    var id: String { rawValue }

    init(_ section: LibrarySection) {
        switch section {
        case .projects:
            self = .previews
        case .colors:
            self = .colors
        case .reports:
            self = .reports
        }
    }

    var librarySection: LibrarySection {
        switch self {
        case .previews:
            return .projects
        case .colors:
            return .colors
        case .reports:
            return .reports
        }
    }
}

@MainActor
@Observable
final class AppState {
    private static let onboardingKey = "onboardingComplete"
    private let userDefaults: UserDefaults

    var selectedTab: AppTab = .preview
    var selectedLibrarySection: LibrarySection = .projects
    var selectedSavedSection: SavedLandingSection {
        get { SavedLandingSection(selectedLibrarySection) }
        set { selectedLibrarySection = newValue.librarySection }
    }

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
