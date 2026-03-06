---
title: "Wire 9 React/Tailwind Design Screens into Native SwiftUI iOS App"
type: feat
status: active
date: 2026-03-05
deepened: 2026-03-05
---

# Wire 9 React/Tailwind Design Screens into Native SwiftUI iOS App

## Enhancement Summary

**Deepened on:** 2026-03-05
**Research agents used:** SwiftUI UI Patterns skill (app-wiring, navigationstack, tabview, grids, theming, loading-placeholders, controls), Architecture Strategist, Performance Oracle, Code Simplicity Reviewer, Apple SwiftUI docs (Context7), web research (MVVM patterns, LazyVGrid perf, comparison slider, custom fonts)

### Key Improvements
1. **Theme as @Observable class** instead of static Color extensions — enables future dark mode and dynamic theming without refactoring
2. **TabRouter pattern with per-tab RouterPath** — each tab gets its own NavigationStack and @Observable router, injected via environment (not prop-drilled)
3. **Comparison slider uses @GestureState** — separates transient drag state from persistent position for 60fps performance
4. **Color catalog pagination** — load 50 items at a time instead of all 5,300 to prevent scroll lag
5. **Dynamic Type support** — custom fonts use `.relativeTo:` text style for accessibility scaling
6. **Removed BottomNavBar component** — use native SwiftUI `TabView` instead of a custom tab bar

### New Considerations Discovered
- Custom font names in SwiftUI must match the PostScript name (check in Font Book), not the filename
- Do NOT nest @Observable objects inside other @Observable objects — causes double-observation bugs
- `.contentShape(Rectangle())` required on grid cells for full-bleed tap targets
- Image compression must run on background thread via `Task.detached` to avoid blocking UI
- Use `NavigationPath` instead of `[AppRoute]` if routes need heterogeneous types

---

## Overview

Translate 9 high-fidelity React/Tailwind design screens from `export-react/` into a production-ready native SwiftUI iOS app. This includes creating the Xcode project, building a reusable design system layer, implementing all 9 screens as SwiftUI views with MVVM architecture, and wiring up navigation. No Swift code exists yet — this is a greenfield build.

## Problem Statement

The Crain Paint Visualizer has fully designed screens in React/Tailwind (`.tsx` files with exact colors, typography, spacing, layout, and interactions), but no iOS implementation exists. These designs need to be faithfully translated into native SwiftUI while following iOS platform conventions (NavigationStack, SwiftData, @Observable MVVM).

## Proposed Solution

Build the iOS app in 4 implementation phases within Phase 1 (MVP):

1. **Foundation** — Xcode project, design system, shared components
2. **Visualizer Flow** — 6 screens: Welcome → Brand Selector → Item Picker → Photo Upload → Surface Picker → Color Matcher
3. **Results & Gallery** — 2 screens: Results Gallery + Visualization Detail (with before/after slider)
4. **Favorites & Polish** — 1 screen: Favorites + navigation wiring + tab bar

## Technical Approach

### Architecture

```
CrainPaintVisualizer/
├── CrainPaintVisualizerApp.swift          # @main entry, TabView + dependency graph
├── AppState.swift                          # @Observable global state
│
├── Navigation/
│   ├── AppTab.swift                        # Tab enum with labels + content
│   ├── AppRoute.swift                      # Route enum (all destinations)
│   ├── RouterPath.swift                    # @Observable per-tab router
│   └── TabRouter.swift                     # Manages per-tab RouterPath instances
│
├── DesignSystem/
│   ├── Theme.swift                         # @Observable theme (colors, fonts, spacing)
│   ├── Components/
│   │   ├── AppButton.swift                 # .primary, .outline, .ghost, .cta variants
│   │   ├── AppCard.swift                   # White bg, 16pt corners, shadow
│   │   ├── AppBadge.swift                  # Capsule badges
│   │   ├── AppInput.swift                  # 48pt height, rounded border
│   │   ├── StepProgressView.swift          # 3-dot wizard indicator
│   │   ├── FloatingActionBar.swift         # Sticky bottom CTA bar
│   │   └── ShimmerModifier.swift           # Skeleton loading animation
│   └── Modifiers/
│       ├── ToastModifier.swift             # Custom toast overlay
│       └── AppRouterModifier.swift         # Centralized navigationDestination
│
├── Features/
│   ├── Welcome/
│   │   └── WelcomeView.swift               # Screen 1: Hero + CTAs
│   ├── Visualizer/
│   │   ├── BrandSelectorView.swift         # Screen 2: Paint brand cards
│   │   ├── ItemPickerView.swift            # Screen 3: Color catalog browser
│   │   ├── PhotoUploadView.swift           # Screen 4: Camera/library upload
│   │   ├── SurfacePickerView.swift         # Screen 5: Surface selection grid
│   │   ├── ColorMatcherView.swift          # Screen 6: Camera color detection
│   │   ├── ComparisonSliderView.swift      # Reusable before/after slider
│   │   └── CameraView.swift               # UIViewControllerRepresentable wrapper
│   ├── Gallery/
│   │   ├── ResultsGalleryView.swift        # Screen 7: Saved by room
│   │   └── VisualizationDetailView.swift   # Screen 8: Before/after slider
│   └── Favorites/
│       └── FavoritesView.swift             # Screen 9: Saved colors grid
│
├── Models/
│   ├── PaintColor.swift                    # Color catalog model
│   ├── PaintBrand.swift                    # Brand enum
│   ├── Surface.swift                       # Surface type enum
│   └── Visualization.swift                 # Visualization result model
│
├── ViewModels/
│   ├── VisualizerViewModel.swift           # Shared state for visualizer wizard
│   ├── ColorCatalogViewModel.swift         # Search, filter, brand toggle
│   ├── GalleryViewModel.swift              # Room-grouped results
│   └── FavoritesViewModel.swift            # Saved colors management
│
└── Resources/
    ├── Assets.xcassets/                     # Colors, images, app icon
    ├── Fonts/                              # MerriweatherSans, OpenSans bundles
    └── preview-images/                     # Design reference images from export
```

### Research Insights: Architecture

**Best Practices (from SwiftUI UI Patterns skill + Apple docs):**
- Use a `TabRouter` class that lazily creates one `RouterPath` per tab — avoids sharing navigation state across tabs
- Inject `RouterPath` into environment so child views navigate programmatically without prop-drilling
- Centralize all `navigationDestination(for:)` mappings in a single `.withAppRouter()` modifier
- Do NOT nest `@Observable` objects inside other `@Observable` objects — keep them flat and independent
- Use `@State private var viewModel = ViewModel()` in views — @Observable auto-tracks property access

**Anti-patterns to avoid:**
- Sharing one NavigationStack path across all tabs (breaks independent tab history)
- Storing view instances in the navigation path (store lightweight route data only)
- Using `@StateObject` or `ObservableObject` — these are legacy; use `@Observable` on iOS 17+

### Navigation Architecture

```swift
// Navigation/AppRoute.swift
enum AppRoute: Hashable {
    case brandSelector
    case itemPicker
    case photoUpload
    case surfacePicker
    case colorMatcher
    case resultsGallery
    case visualizationDetail(id: String)
}

// Navigation/RouterPath.swift
@MainActor
@Observable
final class RouterPath {
    var path: [AppRoute] = []
    var presentedSheet: SheetDestination?

    func navigate(to route: AppRoute) {
        path.append(route)
    }

    func reset() {
        path = []
    }
}

// Navigation/TabRouter.swift
@MainActor
@Observable
final class TabRouter {
    private var routers: [AppTab: RouterPath] = [:]

    func router(for tab: AppTab) -> RouterPath {
        if let router = routers[tab] { return router }
        let router = RouterPath()
        routers[tab] = router
        return router
    }

    func binding(for tab: AppTab) -> Binding<[AppRoute]> {
        let router = router(for: tab)
        return Binding(get: { router.path }, set: { router.path = $0 })
    }
}

// Navigation/AppTab.swift
@MainActor
enum AppTab: Int, Identifiable, Hashable, CaseIterable {
    case visualize
    case gallery
    case favorites

    var id: Int { rawValue }

    @ViewBuilder
    func makeContentView() -> some View {
        switch self {
        case .visualize: BrandSelectorView()
        case .gallery: ResultsGalleryView()
        case .favorites: FavoritesView()
        }
    }

    var label: some View {
        switch self {
        case .visualize: Label("Visualize", systemImage: "paintbrush")
        case .gallery: Label("Gallery", systemImage: "photo.on.rectangle.angled")
        case .favorites: Label("Favorites", systemImage: "heart")
        }
    }
}

// CrainPaintVisualizerApp.swift — root wiring
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

// Modifiers/AppRouterModifier.swift — centralized destinations
extension View {
    func withAppRouter() -> some View {
        navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .brandSelector: BrandSelectorView()
            case .itemPicker: ItemPickerView()
            case .photoUpload: PhotoUploadView()
            case .surfacePicker: SurfacePickerView()
            case .colorMatcher: ColorMatcherView()
            case .resultsGallery: ResultsGalleryView()
            case .visualizationDetail(let id): VisualizationDetailView(id: id)
            }
        }
    }
}
```

### Design System Token Mapping

| Web Token | iOS Access | Value |
|-----------|-----------|-------|
| `--primary` | `theme.primary` | `#0D9488` (teal) |
| `--accent` | `theme.accent` | `#14B8A6` (light teal) |
| `--background` | `theme.background` | `#FFFFFF` |
| `--foreground` | `theme.foreground` | `#0F172A` (dark slate) |
| `--muted` | `theme.muted` | `#F1F5F9` |
| `--muted-foreground` | `theme.mutedForeground` | `#64748B` |
| `--border` | `theme.border` | `#E2E8F0` |
| `--card` | `theme.card` | `#FFFFFF` |
| `--destructive` | `theme.destructive` | `#EF4444` |
| CTA gradient | `theme.ctaGradient` | `#F6653C → #27CCC0` |

### Research Insights: Theming

**Best Practice (from swiftui-ui-patterns/theming):** Use an `@Observable Theme` class injected at the app root via `.environment(theme)` instead of static `Color` extensions. This enables:
- Dynamic dark mode switching without refactoring
- User-customizable accent colors (future)
- Semantic color names that read naturally in views

```swift
// DesignSystem/Theme.swift
@MainActor
@Observable
final class Theme {
    // Semantic colors
    var primary: Color = Color(hex: "0D9488")
    var accent: Color = Color(hex: "14B8A6")
    var foreground: Color = Color(hex: "0F172A")
    var background: Color = .white
    var card: Color = .white
    var muted: Color = Color(hex: "F1F5F9")
    var mutedForeground: Color = Color(hex: "64748B")
    var border: Color = Color(hex: "E2E8F0")
    var destructive: Color = Color(hex: "EF4444")

    // Gradient
    var ctaGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "F6653C"), Color(hex: "27CCC0")],
            startPoint: .leading, endPoint: .trailing
        )
    }

    // Typography (use .relativeTo for Dynamic Type scaling)
    var largeTitle: Font { .custom("MerriweatherSans-Bold", size: 28, relativeTo: .largeTitle) }
    var title: Font { .custom("MerriweatherSans-Bold", size: 22, relativeTo: .title2) }
    var headline: Font { .custom("MerriweatherSans-Bold", size: 18, relativeTo: .headline) }
    var body: Font { .custom("OpenSans-Regular", size: 16, relativeTo: .body) }
    var bodyMedium: Font { .custom("OpenSans-SemiBold", size: 16, relativeTo: .body) }
    var subhead: Font { .custom("OpenSans-Medium", size: 14, relativeTo: .subheadline) }
    var caption: Font { .custom("OpenSans-Regular", size: 12, relativeTo: .caption) }
    var micro: Font { .custom("OpenSans-Medium", size: 11, relativeTo: .caption2) }

    // Spacing (4pt grid)
    let spacingXS: CGFloat = 4
    let spacingSM: CGFloat = 8
    let spacingMD: CGFloat = 16
    let spacingLG: CGFloat = 24
    let spacingXL: CGFloat = 32

    // Corner radii
    let radiusSM: CGFloat = 8
    let radiusMD: CGFloat = 12
    let radiusLG: CGFloat = 16
    let radiusXL: CGFloat = 20
}

// Usage in views:
struct ExampleView: View {
    @Environment(Theme.self) private var theme

    var body: some View {
        Text("Hello")
            .font(theme.headline)
            .foregroundStyle(theme.foreground)
            .padding(theme.spacingMD)
            .background(theme.card)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
    }
}
```

### Research Insights: Custom Font Loading

**Critical steps (from web research + Apple docs):**
1. Add `.ttf` files to Xcode target (ensure "Copy Bundle Resources" includes them)
2. Register in Info.plist under `UIAppFonts` — use **filename only** (e.g., `MerriweatherSans-Bold.ttf`, not the path)
3. Verify PostScript name in Font Book app — SwiftUI's `Font.custom()` uses the **PostScript name**, not the filename
4. Use `.relativeTo:` parameter for Dynamic Type scaling:
   ```swift
   Font.custom("MerriweatherSans-Bold", size: 28, relativeTo: .largeTitle)
   ```
5. Add fallback: if custom font fails to load, SwiftUI silently falls back to system font — no crash, but test early

### Icon Mapping (Lucide/Solar → SF Symbols)

| Design Icon | SF Symbol | Screen |
|-------------|-----------|--------|
| paintbrush | `paintbrush` | Tab bar |
| camera | `camera` | Photo upload, color matcher |
| photo.on.rectangle | `photo.on.rectangle` | Library button |
| magnifyingglass | `magnifyingglass` | Search bars |
| heart / heart.fill | `heart` / `heart.fill` | Favorites |
| checkmark | `checkmark` | Selected states |
| xmark | `xmark` | Close/dismiss |
| arrow.right | `arrow.right` | Next step |
| arrow.left | `arrow.left` | Back |
| square.and.arrow.up | `square.and.arrow.up` | Share |
| bolt | `bolt` | Flashlight toggle |
| paintpalette | `paintpalette` | Brand/color icons |
| door.left.hand.open | `door.left.hand.open` | Surface: doors |
| square.3.layers.3d | `square.3.layers.3d` | Surface: walls |

### Implementation Phases

#### Phase 1: Foundation (Files: 11)

**Goal**: Xcode project, design system, shared components — everything screens depend on.

**Tasks:**

- [ ] Create Xcode project `CrainPaintVisualizer` with iOS 17.0 deployment target
- [ ] Configure project structure matching architecture above
- [ ] Add custom fonts: MerriweatherSans (Bold), OpenSans (Regular, Medium, SemiBold) to bundle
- [ ] Register fonts in Info.plist `UIAppFonts` array (filenames only, verify PostScript names in Font Book)
- [ ] Add `Color(hex:)` initializer in a `HexColor.swift` utility

**Design System Files:**

- [ ] `DesignSystem/Theme.swift` — `@Observable` theme with all colors, fonts, spacing, radii (see code above)

- [ ] `DesignSystem/Components/AppButton.swift` — 4 variants: `.primary`, `.outline`, `.ghost`, `.cta`
  - Primary: `theme.primary` bg, white text, `theme.radiusMD` corners, 48pt height
  - Outline: `theme.border` stroke, `theme.foreground` text
  - Ghost: transparent bg, `theme.primary` text
  - CTA: `theme.ctaGradient` bg, white text, shadow
  - All: `ButtonStyle` with `configuration.isPressed ? 0.98 : 1.0` scaleEffect (spring), disabled opacity 0.5
  - Minimum height 44pt for accessibility tap targets

- [ ] `DesignSystem/Components/AppCard.swift` — `theme.card` bg, `theme.radiusLG` corners, subtle shadow (color: .black.opacity(0.08), radius: 8, y: 2)
- [ ] `DesignSystem/Components/AppInput.swift` — 48pt height, `theme.border` rounded border, `theme.primary` ring on focus via `@FocusState`
- [ ] `DesignSystem/Components/AppBadge.swift` — Capsule shape, filled or outlined variant
- [ ] `DesignSystem/Components/StepProgressView.swift` — 3-dot horizontal progress (completed=filled circle, active=outlined+pulse, upcoming=gray dot)
- [ ] `DesignSystem/Components/FloatingActionBar.swift` — Sticky bottom bar with selected count + CTA, use `.safeAreaInset(edge: .bottom)` for proper layout
- [ ] `DesignSystem/Modifiers/ShimmerModifier.swift` — Use `.redacted(reason: .placeholder)` with gradient overlay animation (1.8s loop)

### Research Insights: Loading States

**Best practice (from swiftui-ui-patterns/loading-placeholders):**
- Render the real layout with placeholder data, then apply `.redacted(reason: .placeholder)` — preserves layout stability
- Show 3-6 placeholder rows max to reduce jank on low-end devices
- Use `ContentUnavailableView` for empty states after loading completes (e.g., "No favorites yet")
- Avoid nesting multiple spinners — one loading indicator per section

```swift
// Recommended loading pattern
if isLoading {
    ForEach(0..<6, id: \.self) { _ in
        ColorSwatchCard(color: .placeholder)
    }
    .redacted(reason: .placeholder)
} else if colors.isEmpty {
    ContentUnavailableView("No colors found", systemImage: "paintpalette")
} else {
    ForEach(colors) { color in
        ColorSwatchCard(color: color)
    }
}
```

---

#### Phase 2: Visualizer Flow Screens (Files: 9)

**Goal**: All 6 screens in the paint visualizer wizard, wired with NavigationStack.

**Screen 1 — `WelcomeView.swift`** (from `welcome.tsx`)
- [ ] Full-screen hero image background with gradient overlay (bottom → top, black 0% → 60%)
- [ ] "Aura Finishes" branding badge (white/semi-transparent, capsule)
- [ ] "Trusted Craftsmanship Since 1952" tagline (theme.caption, white)
- [ ] "Visualize your perfect space" headline (theme.largeTitle, white, 32pt)
- [ ] Subheading paragraph (theme.body, white/70%)
- [ ] "Get Started" button (AppButton .cta, full-width) — sets `appState.onboardingComplete = true`
- [ ] "Sign In" button (AppButton .outline, white border, full-width)
- [ ] Security badge at bottom: shield icon + "Secure & Trusted" (theme.micro)
- [ ] Fade-in + slide-up animation on appear (0.6s, spring)
- [ ] No tab bar on this screen (standalone entry, shown conditionally by app root)

**Screen 2 — `BrandSelectorView.swift`** (from `brand-selector.tsx`)
- [ ] "Select a Paint Brand" heading (theme.title)
- [ ] Subtitle description (theme.body, theme.mutedForeground)
- [ ] 4 brand cards as vertical list:
  - Benjamin Moore: logo placeholder + "Quality you can trust" + blue accent
  - Sherwin-Williams: globe icon + "Color for every vision" + SW blue
  - Behr: "BEHR" text + "Reliable color" + orange
  - Other Brand: palette icon + "Enter custom brand" + dashed border + chevron
- [ ] Selected state: theme.primary border (2pt) + theme.primary.opacity(0.05) bg + checkmark badge top-right
- [ ] Fixed bottom "Continue" AppButton (.cta, full-width)
- [ ] Navigation: `@Environment(RouterPath.self) var router` then `router.navigate(to: .itemPicker)`

**Screen 3 — `ItemPickerView.swift`** (from `item-picker.tsx`)
- [ ] StepProgressView (Step 1 active: Color → Photo → Surface)
- [ ] Brand toggle: "Signature" | "Heritage" — use `Picker("", selection:).pickerStyle(.segmented)` (segmented is appropriate for 2 options per swiftui-ui-patterns/controls)
- [ ] Filter tabs: "Popular" | "All Colors" | "Match" (camera icon on Match)
- [ ] Search bar (AppInput with magnifyingglass icon + clear button)
- [ ] Results counter: "Showing X results" (theme.caption, theme.mutedForeground)
- [ ] 2-column LazyVGrid of color cards (see performance insights below):
  - Color swatch rectangle (64pt height, rounded top corners)
  - Color name (theme.subhead, bold) + code (theme.caption, theme.mutedForeground)
  - Selected: theme.primary border + checkmark badge
  - **Add `.contentShape(Rectangle())` for full-bleed tap targets**
- [ ] FloatingActionBar: selected count + color previews + "Next Step" button
- [ ] `ColorCatalogViewModel` — search, filter by family, brand toggle, selection state (max 5)

### Research Insights: LazyVGrid Performance (5,300 items)

**Key finding:** LazyVGrid only creates views on-demand as they scroll into view, so 5,300 items is feasible. But several optimizations are critical:

1. **Keep cell views lightweight** — extract the color swatch + name + code into a small, focused `ColorSwatchCard` subview. Avoid heavy overlays.
2. **Use `.adaptive` columns** for device-adaptive layout:
   ```swift
   let columns = [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 12)]
   ```
3. **Filter in the ViewModel** — don't filter in the view body. Use a computed property or debounced search:
   ```swift
   // ColorCatalogViewModel
   @Observable
   final class ColorCatalogViewModel {
       var searchText = ""
       var selectedBrand: PaintBrand = .benjaminMoore
       var allColors: [PaintColor] = []

       var filteredColors: [PaintColor] {
           let branded = allColors.filter { $0.brand == selectedBrand }
           guard !searchText.isEmpty else { return branded }
           return branded.filter {
               $0.name.localizedCaseInsensitiveContains(searchText) ||
               $0.number.localizedCaseInsensitiveContains(searchText)
           }
       }
   }
   ```
4. **Consider pagination** if scrolling stutters — load 100 items initially, append on scroll near bottom via `.onAppear` on the last visible item
5. **Profile with Instruments** — use Time Profiler and Memory Allocations to verify

**Screen 4 — `PhotoUploadView.swift`** (from `photo-upload.tsx`)
- [ ] StepProgressView (Step 2 active)
- [ ] "Step 2: Upload your space" header (theme.title)
- [ ] Large dashed-border upload zone (200pt height, theme.radiusLG corners)
  - Empty: Camera icon (48pt, theme.mutedForeground) + "Take or Upload Photo" + description
  - Two buttons in HStack: "Camera" + "Library" (AppButton .outline, with icons)
- [ ] "Pro Tip" info box: lightbulb icon + yellow-tinted bg + tip text (theme.caption)
- [ ] FloatingActionBar: "Next Step" (disabled until photo loaded)
- [ ] Photo loaded state: full-width Image preview + "Change Photo" overlay button
- [ ] Camera: UIImagePickerController via UIViewControllerRepresentable (fullScreenCover)
- [ ] Library: SwiftUI PhotosPicker (load as `Data.self`, not `Image.self`)
- [ ] Auto-compress on background thread:
  ```swift
  // Run compression off main thread
  Task.detached(priority: .userInitiated) {
      let compressed = ImageCompressor.compress(
          imageData: rawData,
          maxDimension: 2048,
          quality: 0.8,
          maxBytes: 3_500_000
      )
      await MainActor.run { self.photo = compressed }
  }
  ```

**Screen 5 — `SurfacePickerView.swift`** (from `surface-picker.tsx`)
- [ ] StepProgressView (Step 3 active, Steps 1-2 completed)
- [ ] "Where do you want to apply the color?" heading (theme.title)
- [ ] 2-column LazyVGrid of 6 surface buttons (80pt height):
  - Full Walls (square.3.layers.3d), Trim & Base (ruler), Accent Wall (rectangle.split.2x1),
    Doors (door.left.hand.open), Cabinets (cabinet), Ceiling (rectangle.topthird.inset.filled)
  - Selected: theme.primary border + theme.primary.opacity(0.05) bg
  - **Add `.contentShape(Rectangle())` for full tap target**
- [ ] 7th tile: "Custom / Other" spanning full width, dashed border (see brainstorm: `docs/brainstorms/2026-02-15-custom-surface-input-brainstorm.md`)
  - When selected: AppInput slides in below with placeholder "e.g., garage door, fence..."
  - Mutually exclusive with preset tiles
  - "Next" disabled until custom text has content
- [ ] FloatingActionBar: "Visualize Now" with magic wand icon (AppButton .cta)

**Screen 6 — `ColorMatcherView.swift`** (from `color-matcher.tsx`)
- [ ] Full-screen dark background (Color.black)
- [ ] Camera preview layer (AVCaptureSession, UIViewRepresentable)
- [ ] Centered crop frame: white border square with animated corner brackets (theme.primary)
- [ ] Crosshair: white circle center + pulsing theme.primary dot
- [ ] Top bar (frosted glass via `.ultraThinMaterial`): Close button + "Align object in frame" + Flashlight toggle
- [ ] Analysis indicator: "Analyzing Color..." pulsing badge
- [ ] Bottom sheet (white, drag handle):
  - "Matches Found" heading + "3 closest cross-brand matches"
  - Large color swatch preview of primary match
  - 3 match cards: swatch + match % + color name + brand code + "Add" button
  - Primary match highlighted with theme.primary.opacity(0.05) bg
  - "Retake Photo" button at bottom
- [ ] Use `.presentationDetents([.fraction(0.35), .large])` for the bottom sheet snap points

**Navigation wiring:**
- [ ] `Navigation/RouterPath.swift` — @Observable per-tab router (see code above)
- [ ] `Navigation/TabRouter.swift` — manages per-tab routers
- [ ] `Navigation/AppRoute.swift` — all route cases
- [ ] `Modifiers/AppRouterModifier.swift` — centralized `.withAppRouter()` destination mapping
- [ ] `VisualizerViewModel.swift` — Shared @Observable across wizard: selectedBrand, selectedColors[], photo, surface, customSurface. **Not nested inside another @Observable** — injected via `.environment()` separately.

---

#### Phase 3: Results & Gallery (Files: 3)

**Goal**: Results gallery with room grouping + detail view with before/after slider.

**Screen 7 — `ResultsGalleryView.swift`** (from `results-gallery.tsx`)
- [ ] Header: "Gallery" (theme.title) + "Add folder" button + search icon
- [ ] Vertical sections per room (LazyVStack):
  - Room icon + heading + count badge (AppBadge) + "View All" link
  - Horizontal ScrollView (.horizontal, showsIndicators: false):
    - Visualization cards (240pt wide, 3:4 aspect):
      - Image thumbnail (AsyncImage or cached)
      - Fullscreen icon overlay (top-right)
      - Color info below: small swatch circle + name + code (theme.caption)
  - Cards: AppCard style, theme.radiusMD corners
- [ ] Native TabView tab (Gallery tab active) — no custom BottomNavBar needed
- [ ] `GalleryViewModel` — groups visualizations by room, handles sections

**Screen 8 — `VisualizationDetailView.swift`** (from `visualization-detail.tsx`)
- [ ] Navigation header: back button + title + menu (ellipsis)
- [ ] Toggle: "After Only" | "Before & After" (segmented control, `.pickerStyle(.segmented)`)
- [ ] Before/After comparison slider — extracted to `ComparisonSliderView.swift`:

### Research Insights: Before/After Comparison Slider

**Key finding (from web research + Apple docs):** Use `@GestureState` for transient drag tracking and `@State` for persistent slider position. This separation ensures smooth 60fps updates.

```swift
// Features/Visualizer/ComparisonSliderView.swift
struct ComparisonSliderView: View {
    let beforeImage: Image
    let afterImage: Image

    @State private var sliderPosition: CGFloat = 0.5  // 0.0 to 1.0
    @GestureState private var isDragging = false

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let xPos = sliderPosition * width

            ZStack {
                // After image (full width, bottom layer)
                afterImage
                    .resizable()
                    .aspectRatio(3/4, contentMode: .fill)
                    .frame(width: width)

                // Before image (masked to left of slider)
                beforeImage
                    .resizable()
                    .aspectRatio(3/4, contentMode: .fill)
                    .frame(width: width)
                    .mask(
                        HStack {
                            Rectangle().frame(width: xPos)
                            Spacer(minLength: 0)
                        }
                    )

                // Divider line
                Rectangle()
                    .fill(.white)
                    .frame(width: 2)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                    .position(x: xPos, y: geo.size.height / 2)

                // Drag handle
                Circle()
                    .fill(.white)
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(Color(hex: "0D9488"), lineWidth: 2))
                    .shadow(radius: 4)
                    .position(x: xPos, y: geo.size.height / 2)

                // Labels
                HStack {
                    Text("Before")
                        .font(.caption).bold()
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    Spacer()
                    Text("After")
                        .font(.caption).bold()
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 12)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 12)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isDragging) { _, state, _ in state = true }
                    .onChanged { value in
                        sliderPosition = min(max(value.location.x / width, 0), 1)
                    }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .drawingGroup()  // GPU-accelerated rendering for 60fps
        }
        .aspectRatio(3/4, contentMode: .fit)
    }
}
```

**Performance notes:**
- `.drawingGroup()` composites the ZStack into a Metal texture — critical for smooth drag
- `@GestureState` auto-resets on gesture end (good for transient drag tracking)
- `DragGesture(minimumDistance: 0)` ensures instant response with no delay
- Snap to edges: clamp to 0 or 1 when within 10% of edges
- 2025 SwiftUI added `.velocity` on DragGesture.Value — can use for momentum-based sliding

- [ ] Color info card (AppCard):
  - Color swatch (40pt circle) + name (theme.headline) + brand/code (theme.caption)
  - Heart favorite button (toggle heart/heart.fill, theme.destructive when filled)
  - Divider
  - Target surface + Lighting condition in HStack
- [ ] Action buttons (2-column HStack): "Order Swatch" (outline) + "Share Result" (outline)
- [ ] Fixed bottom CTA: "Get Expert Consultation" (AppButton .cta, full-width) — use `.safeAreaInset(edge: .bottom)`

---

#### Phase 4: Favorites & Final Wiring (Files: 3)

**Goal**: Favorites screen + app entry point + tab bar integration.

**Screen 9 — `FavoritesView.swift`** (from `favorites.tsx`)
- [ ] Header: "Favorite Colors" (theme.title) + "Your curated collection..." (theme.body, theme.mutedForeground)
- [ ] Search bar (AppInput, same as ItemPicker)
- [ ] Filter chips HStack: "Brand" dropdown + "Latest" sort toggle
- [ ] Results counter: "X Colors Saved" (theme.caption)
- [ ] 2-column LazyVGrid of color cards:
  - Large color swatch (96pt height, rounded top)
  - Brand name (theme.micro, uppercase, theme.mutedForeground)
  - Color name (theme.subhead, bold)
  - Color code (theme.caption, theme.mutedForeground)
  - Heart button (top-right, heart.fill in theme.destructive)
  - **`.contentShape(Rectangle())` on each card**
- [ ] Empty state: `ContentUnavailableView("No favorites yet", systemImage: "heart", description: Text("Tap the heart on any color to save it here"))`
- [ ] Native TabView (Favorites tab active)
- [ ] `FavoritesViewModel` — search, sort, brand filter, toggle favorite

**App Entry:**
- [ ] `CrainPaintVisualizerApp.swift` — @main with TabView, TabRouter, Theme, AppState (see full code in Navigation Architecture section)
- [ ] `AppState.swift` — @Observable: isAuthenticated, selectedTab, onboardingComplete (persisted via @AppStorage)
- [ ] Conditional: show WelcomeView if !onboardingComplete, else TabView

---

## Screen-to-File Reference Table

| # | Screen | Design Source | SwiftUI File | Phase |
|---|--------|--------------|-------------|-------|
| 1 | Welcome/Onboarding | `welcome.tsx` | `WelcomeView.swift` | 2 |
| 2 | Brand Selector | `brand-selector.tsx` | `BrandSelectorView.swift` | 2 |
| 3 | Color Picker | `item-picker.tsx` | `ItemPickerView.swift` | 2 |
| 4 | Photo Upload | `photo-upload.tsx` | `PhotoUploadView.swift` | 2 |
| 5 | Surface Picker | `surface-picker.tsx` | `SurfacePickerView.swift` | 2 |
| 6 | Color Matcher | `color-matcher.tsx` | `ColorMatcherView.swift` | 2 |
| 7 | Results Gallery | `results-gallery.tsx` | `ResultsGalleryView.swift` | 3 |
| 8 | Visualization Detail | `visualization-detail.tsx` | `VisualizationDetailView.swift` | 3 |
| 9 | Favorites | `favorites.tsx` | `FavoritesView.swift` | 4 |

## System-Wide Impact

### Interaction Graph

This is a greenfield build — no existing system to impact. The key interaction chain:
- WelcomeView → (sets onboardingComplete) → TabView → VisualizerTab → BrandSelector → ItemPicker → PhotoUpload → SurfacePicker → ResultsGallery
- ColorMatcher is accessible from ItemPicker's "Match" tab (presented as sheet via `router.presentedSheet = .colorMatcher`)
- Favorites is a standalone tab, reads from shared SwiftData store
- Each tab has independent NavigationStack via TabRouter — tapping a tab resets to that tab's root

### State Lifecycle

- `VisualizerViewModel` is shared across the wizard flow via `.environment()` — not nested inside another @Observable
- If user abandons mid-flow, state is ephemeral (no draft saving in Phase 1)
- Favorites persist via SwiftData — toggling a heart writes immediately
- Gallery items persist via SwiftData — saved visualizations are durable
- `AppState.onboardingComplete` persisted via `@AppStorage` — survives app restart

### API Surface Parity

No existing API surface — this establishes the initial iOS interface layer. Web app parity will come when backend integration is added (Phase 1 weeks 5-8 per PRD).

## Acceptance Criteria

### Functional Requirements

- [ ] All 9 screens render with layout matching design files (spacing, typography, colors within 2pt tolerance)
- [ ] NavigationStack wizard flow works: Welcome → Brand → Colors → Photo → Surface → Results
- [ ] Color picker supports search, brand filter, and multi-select (1-5 colors)
- [ ] Photo upload works via both camera and photo library
- [ ] Surface picker supports 6 presets + custom text input
- [ ] Before/after comparison slider is draggable at 60fps (verified with Instruments)
- [ ] Favorites toggle persists across app launches (SwiftData)
- [ ] Results gallery groups by room with horizontal scroll
- [ ] Tab bar switches between Visualize, Gallery, and Favorites (native TabView)
- [ ] Custom fonts (MerriweatherSans, OpenSans) load correctly and scale with Dynamic Type

### Non-Functional Requirements

- [ ] iOS 17.0 minimum deployment target
- [ ] All tap targets >= 44x44pt (enforced via AppButton minHeight + `.contentShape(Rectangle())`)
- [ ] VoiceOver labels on all interactive elements (color swatches include name + brand, not color-only)
- [ ] Supports Dynamic Type via `.relativeTo:` on custom fonts
- [ ] No hardcoded strings (prepare for localization)
- [ ] Dark mode support via @Observable Theme (future-ready, no refactoring needed)

### Quality Gates

- [ ] Each screen compiles and renders in Xcode Preview
- [ ] Navigation flow testable in Simulator
- [ ] No layout warnings in Xcode canvas
- [ ] Design system components are reusable across all screens
- [ ] Profile color catalog scrolling with Instruments Time Profiler — no dropped frames

## Dependencies & Prerequisites

- **Xcode 16+** with iOS 17 SDK
- **Custom fonts**: MerriweatherSans-Bold.ttf, OpenSans-Regular/Medium/SemiBold.ttf (Google Fonts — verify PostScript names in Font Book)
- **No backend required** for this plan — all screens use mock/static data
- **Images**: Reference images from `export-react/images/` copied to Assets.xcassets for previews

## Risk Analysis & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Custom fonts fail to load | Typography breaks silently | Verify PostScript names in Font Book, test in Preview early, SwiftUI falls back to system font gracefully |
| Color matcher camera requires real device | Can't test in Simulator | Mock camera layer for Previews, test on device for camera features |
| Before/after slider choppy | Poor UX | `.drawingGroup()` for GPU rendering, `@GestureState` for transient tracking, `DragGesture(minimumDistance: 0)` |
| LazyVGrid with 5,300 colors stutters | Scroll lag | Filter in ViewModel (not view body), use `.adaptive` columns, paginate if needed, profile with Instruments |
| Design fidelity drift | Screens don't match designs | Side-by-side comparison during review, screenshot tests |
| Nested @Observable causes double-observation | Unexpected re-renders, bugs | Keep all @Observable objects flat, inject via `.environment()` separately |
| Image compression blocks main thread | UI freeze during photo processing | Use `Task.detached(priority: .userInitiated)` for compression |

## Future Considerations

- **Phase 1 weeks 5-8**: Wire up actual API calls (Supabase, Firebase Gemini) to replace mock data
- **Phase 2**: Add Consultation flow screens (Quiz, Form, Report) — same design system and Theme
- **SwiftData models**: Will be formalized when backend integration begins
- **Dark mode**: Theme is @Observable — add a `colorScheme` property and toggle color values
- **iPad**: Consider `.adaptive` grid columns and `NavigationSplitView` for future iPad support

## Sources & References

### Internal References

- PRD & Engineering Spec: `docs/PRD_AND_ENGINEERING_SPEC.md`
- SwiftUI Design System Guide: `SWIFTUI_DESIGN_SYSTEM_GUIDE.md`
- UI/UX Design Prompt: `docs/UI_UX_DESIGN_PROMPT.md`
- Custom Surface Brainstorm: `docs/brainstorms/2026-02-15-custom-surface-input-brainstorm.md`

### Design Source Files

- `export-react/welcome.tsx` — Welcome/onboarding hero
- `export-react/brand-selector.tsx` — Paint brand selection
- `export-react/item-picker.tsx` — Color catalog browser
- `export-react/photo-upload.tsx` — Camera/library upload
- `export-react/surface-picker.tsx` — Surface type selection
- `export-react/color-matcher.tsx` — Camera color detection
- `export-react/results-gallery.tsx` — Room-grouped gallery
- `export-react/visualization-detail.tsx` — Before/after detail
- `export-react/favorites.tsx` — Saved colors collection
- `export-react/globals.css` — Design tokens (colors, fonts, radii)
- `export-react/icons/` — 51 SVG icons (mapped to SF Symbols)
- `export-react/images/` — 8 reference images

### External References

- [SwiftUI NavigationStack (Apple)](https://developer.apple.com/documentation/swiftui/understanding-the-navigation-stack)
- [Modern MVVM in SwiftUI 2025](https://medium.com/@minalkewat/modern-mvvm-in-swiftui-2025-the-clean-architecture-youve-been-waiting-for-72a7d576648e)
- [SwiftUI NavigationStack Best Practices 2025](https://ravi6997.medium.com/swiftui-navigationstack-multi-screen-apps-best-practices-ccfa346fc7a3)
- [Tuning Lazy Stacks and Grids Performance](https://medium.com/@wesleymatlock/tuning-lazy-stacks-and-grids-in-swiftui-a-performance-guide-2fb10786f76a)
- [Before/After Slider in SwiftUI](https://medium.com/@ortayevnn/how-we-built-a-smooth-before-after-slider-in-swiftui-1dd3f0c2c355)
- [Custom Fonts in SwiftUI Pitfalls](https://blog.eidinger.info/what-can-go-wrong-when-using-custom-fonts-in-swiftui)
- [SwiftUI Custom Fonts (Kodeco)](https://www.kodeco.com/books/swiftui-cookbook/v1.0/chapters/6-use-custom-fonts-in-swiftui)
- [Tips for Lazy Containers in SwiftUI](https://fatbobman.com/en/posts/tips-and-considerations-for-using-lazy-containers-in-swiftui/)

### Skills & Patterns Applied

- `swiftui-ui-patterns` skill: app-wiring, navigationstack, tabview, grids, theming, loading-placeholders, controls references
