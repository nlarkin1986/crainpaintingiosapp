import SwiftUI

/// Updated AppTab with "Studio" instead of "Visualize"
/// This eliminates semantic confusion between the tab name and the action verb
enum AppTabUpdated: Int, Identifiable, Hashable, CaseIterable {
    case studio      // ✅ Renamed from .visualize
    case favorites
    case reports
    case expert

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .studio: "Studio"
        case .favorites: "Favorites"
        case .reports: "Reports"
        case .expert: "Expert"
        }
    }

    var iconOutlined: String {
        switch self {
        case .studio: "paintpalette"
        case .favorites: "heart"
        case .reports: "doc.text"
        case .expert: "person.crop.circle"
        }
    }

    var iconFilled: String {
        switch self {
        case .studio: "paintpalette.fill"
        case .favorites: "heart.fill"
        case .reports: "doc.text.fill"
        case .expert: "person.crop.circle.fill"
        }
    }
    
    /// Alternative icon option: Keep the magic wand for continuity
    var alternativeIcon: String {
        switch self {
        case .studio: "wand.and.stars"  // No filled variant, so use same for both states
        case .favorites: "heart"
        case .reports: "doc.text"
        case .expert: "person.crop.circle"
        }
    }

    @ViewBuilder
    func makeContentView() -> some View {
        switch self {
        case .studio: StudioHomeView()
        case .favorites: FavoritesView()
        case .reports: ReportsHomeView()
        case .expert: ExpertHomeView()
        }
    }

    @ViewBuilder
    var label: some View {
        Label(title, systemImage: iconFilled)
    }
    
    /// Accessibility label for VoiceOver
    var accessibilityLabel: String {
        switch self {
        case .studio: "Studio, where you create paint visualizations"
        case .favorites: "Favorites, your saved visualizations"
        case .reports: "Reports, detailed color analysis"
        case .expert: "Expert, professional consultation"
        }
    }
}

// MARK: - Migration Notes
/*
 
 NAMING RATIONALE: "Studio" vs "Visualize"
 ==========================================
 
 OLD PROBLEM:
 - Tab name: "Visualize" (noun? verb?)
 - Action: "Visualize" (verb)
 - Content: "Visualizations" (noun)
 - Result: Semantic confusion → "Go to Visualize to visualize a visualization"
 
 NEW SOLUTION:
 - Tab name: "Studio" (noun - describes place)
 - Action: "Visualize" or "Create" (verb - describes action)
 - Content: "Visualizations" (noun - describes objects)
 - Result: Clear language → "Go to Studio to create a visualization"
 
 
 INDUSTRY EXAMPLES:
 ------------------
 ✅ Photos (not "Take Photo")
 ✅ Messages (not "Send Message")  
 ✅ Music (not "Play Music")
 ✅ Canva → "Design" (not "Create Design")
 ✅ Figma → "Files" (not "Design")
 ✅ Adobe → "Your work" (not "Create")
 
 
 USER MENTAL MODEL:
 ------------------
 "I'm going to my Studio to create a new Visualization"
 ✅ Natural, clear, no confusion
 
 vs. 
 
 "I'm going to Visualize to create a new Visualization"  
 ❌ Awkward, repetitive, confusing
 
 
 ALTERNATIVE NAMES CONSIDERED:
 ------------------------------
 1. Gallery - Too passive (implies view-only)
 2. Create - Verb, breaks tab convention
 3. Projects - Too enterprise-y
 4. My Colors - Ambiguous with Favorites
 5. Workspace - Too generic
 6. Studio - ✅ WINNER: Clear, professional, scalable
 
 
 FUTURE SCALABILITY:
 -------------------
 "Studio" enables clear future features:
 - Studio Templates
 - Studio Collections  
 - Studio Settings
 - Collaborative Studio
 
 All sound natural!
 
 */
