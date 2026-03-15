# SwiftUI Audit

Baseline used: current shipping target (`iOS 17`, `Swift 5.9`) with separate forward-looking modernization notes. This report follows the `swiftui-pro` format and only includes issues that are either causing current regressions or are likely to create maintainability/accessibility problems soon.

## CrainPaintVisualizer/Sources/Navigation/AppTab.swift

**Lines 10-18, 39-44: Navigation shell uses a different product contract than the rest of the app.**  
Current-baseline issue / test-harness runtime regression.

`AppTab` still exposes semantic aliases for `home`, `saved`, and `expert`, but the visible tab labels and root views are now `Preview`, `Library`, and `More`. That leaves `HomeView`, `SavedHomeView`, and `ExpertHomeView` orphaned from the shell, while the routing coordinator and UI tests still target the older contract. This is the primary reason the current UI suite cannot reach `home.primaryCTA`, `Saved`, or `Expert`.

```swift
// Before
static var home: Self { .preview }
static var saved: Self { .library }
static var expert: Self { .more }

case .preview: PreviewHomeView()
case .library: LibraryHomeView()
case .more: MoreHomeView()

// After
// Pick one shell contract and use it everywhere.
// Example if the legacy product language remains authoritative:
case .home: HomeView()
case .saved: SavedHomeView()
case .expert: ExpertHomeView()
```

## CrainPaintVisualizer/Sources/Features/Preview/PreviewHomeView.swift

**Line 77: Root-screen accessibility identifier drifted from the rest of the app.**  
Current-baseline issue / test-harness runtime regression.

The app now boots into `PreviewHomeView`, but its main CTA uses `previewHome.primaryCTA` while onboarding, home-flow logic, and the UI test harness still look for `home.primaryCTA`. If the new screen is the intended root, its identifiers need to stay compatible or the rest of the app must be renamed in one coordinated pass.

```swift
// Before
.accessibilityIdentifier("previewHome.primaryCTA")

// After
// Keep the shared contract consistent with the shell decision.
.accessibilityIdentifier("home.primaryCTA")
```

## CrainPaintVisualizer/Sources/Features/Expert/ExpertHomeView.swift

**Lines 54-62: The expert tab content exists, but the tab shell no longer routes to it.**  
Current-baseline issue / test-harness runtime regression.

`ExpertHomeView` still owns the expert CTAs the tests and product language expect, but `AppTab` routes `.more` to `MoreHomeView()` instead. That makes the expert purchase entry point unreachable via the expected top-level tab even though the screen and identifiers are still compiled.

```swift
// Before
case .more: MoreHomeView()

// After
// If Expert remains a first-class tab:
case .expert: ExpertHomeView()
```

## CrainPaintVisualizer/Tests/UI/CrainPaintVisualizerUITests.swift

**Lines 39, 53-55, 90-92, 608-616, 632-650, 796-804: UI tests are pinned to a shell the app no longer presents.**  
Test-harness/runtime regression.

The suite still asserts `home.primaryCTA`, `Home`, `Saved`, and `Expert`, but the live shell now exposes `previewHome.primaryCTA`, `Preview`, `Library`, and `More`. These are genuine failures, not flaky timing issues: the app and the harness disagree about the primary navigation model.

```swift
// Before
let homeCTA = app.buttons["home.primaryCTA"]
let savedTab = app.buttons["Saved"]
let expertTab = app.buttons["Expert"]

// After
// Update these only after the shell contract is settled.
let previewCTA = app.buttons["previewHome.primaryCTA"]
let libraryTab = app.buttons["Library"]
let moreTab = app.buttons["More"]
```

## CrainPaintVisualizer/Sources/DesignSystem/TypographyTokens.swift

**Line 22: The shared `micro` token is `.caption2`, but it is used as regular UI text across the app.**  
Current-baseline accessibility issue.

`theme.micro` appears in tab labels, badges, report metadata, and several headers. Making the shared token `.caption2` pushes too much essential text below a comfortable Dynamic Type baseline.

```swift
// Before
static let micro: Font = .system(.caption2, design: .default, weight: .medium)

// After
static let micro: Font = .system(.caption, design: .default, weight: .regular)
// Reserve any smaller token for truly non-essential metadata only.
```

## CrainPaintVisualizer/Sources/Features/Gallery/VisualizationDetailView.swift

**Lines 180-185: Use `Button` instead of `onTapGesture()` for tappable preview content.**  
Current-baseline accessibility issue.

The comparison preview opens fullscreen when the card is tapped, but the tappable container is implemented with `onTapGesture()` and has no button semantics. VoiceOver users can miss that the preview is actionable, and the gesture is harder to reason about than a proper button wrapper.

```swift
// Before
.contentShape(Rectangle())
.onTapGesture {
    if canExpand {
        showFullscreen = true
    }
}

// After
Button {
    if canExpand {
        showFullscreen = true
    }
} label: {
    comparisonContent
}
```

## CrainPaintVisualizer/Sources/Features/Saved/SavedHomeView.swift

**Lines 451-455: Saved design card uses `onTapGesture()` instead of a button.**  
Current-baseline accessibility issue.

The full design card is a major interactive surface, but it is exposed as a gesture-only container. This creates the same discoverability problem as the visualization detail screen and makes the accessibility tree less clear than a `Button` or explicit accessibility action.

```swift
// Before
.accessibilityIdentifier("savedPreviewDetail.designCard")
.contentShape(Rectangle())
.onTapGesture {
    showFullscreen = true
}

// After
Button {
    showFullscreen = true
} label: {
    designCardContent
}
.accessibilityIdentifier("savedPreviewDetail.designCard")
```

## CrainPaintVisualizer/Sources/Features/Favorites/FavoritesView.swift

**Lines 201-258: Favorite color cards should be real buttons, not gesture-only cards.**  
Current-baseline accessibility issue.

`FavoriteColorCard` combines children and manually adds `.isButton`, but the primary interaction still comes from `onTapGesture()`. That loses default button behavior for Voice Control, switch control, and automated interaction compared with a normal `Button`.

```swift
// Before
.contentShape(RoundedRectangle(cornerRadius: theme.radiusXL))
.onTapGesture(perform: onTap)
.accessibilityElement(children: .combine)
.accessibilityAddTraits(.isButton)

// After
Button(action: onTap) {
    cardContent
}
.buttonStyle(.plain)
```

## CrainPaintVisualizer/Sources/Features/Welcome/HowItWorksView.swift

**Lines 55-68: The dismiss control is icon-only without a user-facing label.**  
Current-baseline accessibility issue.

The close button relies on the SF Symbol alone, so VoiceOver falls back to symbol naming rather than a product label such as “Close”. The control is visually obvious, but its spoken affordance is weaker than it should be.

```swift
// Before
Button(action: onBack) {
    Image(systemName: "xmark")
}

// After
Button("Close", systemImage: "xmark", action: onBack)
    .labelStyle(.iconOnly)
```

## CrainPaintVisualizer/Sources/DesignSystem/Components/CustomTabBar.swift

**Lines 32, 87-90: Avoid global scene-window safe-area lookups inside SwiftUI layout code.**  
Current-baseline layout/accessibility issue.

The tab bar reads the bottom inset through `UIApplication.shared.connectedScenes.first?.windows.first`. In a multi-scene app, sheet, or UI-test context that may not be the active window, which can leave the bar mispositioned and make bottom controls harder to hit.

```swift
// Before
.padding(.bottom, max(safeAreaBottom, theme.space8))

private var safeAreaBottom: CGFloat {
    (UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first?.windows.first?.safeAreaInsets.bottom ?? 0)
}

// After
.safeAreaPadding(.bottom, theme.space8)
// Or move the component into a parent .safeAreaInset(edge: .bottom)
// and remove the UIApplication lookup entirely.
```

## CrainPaintVisualizer/Sources/DesignSystem/Components/FloatingActionBar.swift

**Lines 33, 45-48: The floating action bar repeats the same brittle safe-area lookup.**  
Current-baseline layout/accessibility issue.

This component uses the same global scene/window lookup as `CustomTabBar`, so any inset mismatch affects the largest CTAs in the app as well. That is a more credible explanation for intermittent bottom-button hittability problems than simple timing.

```swift
// Before
.padding(.bottom, max(safeAreaBottom, theme.space4))

private var safeAreaBottom: CGFloat {
    UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first?.windows.first?.safeAreaInsets.bottom ?? 0
}

// After
.safeAreaPadding(.bottom, theme.space4)
// Or host the bar from a parent .safeAreaInset(edge: .bottom)
```

## CrainPaintVisualizer/Sources/Features/Reports/SampleOutputView.swift

**Lines 97-107: The back control is icon-only without a text-backed label.**  
Current-baseline accessibility issue.

Like the onboarding close button, this back affordance is visually clear but VoiceOver must infer its meaning from the symbol. A text-backed button keeps the spoken label correct while preserving the icon-only appearance.

```swift
// Before
Button {
    dismiss()
} label: {
    Image(systemName: "chevron.left")
}

// After
Button("Back", systemImage: "chevron.left", action: dismiss.callAsFunction)
    .labelStyle(.iconOnly)
```

**Lines 166-170: Avoid `Binding(get:set:)` inside view body code.**  
Current-baseline data-flow issue.

The playback slider creates a manual binding inline even though the view model already owns the source of truth. This is harder to maintain and makes follow-up effects less obvious than binding directly to owned state and using `onChange()` or a view-model binding entry point.

```swift
// Before
Slider(value: Binding(get: {
    playerVM.progress
}, set: { newValue in
    playerVM.seek(to: newValue)
}), in: 0...1)

// After
Slider(value: $playerVM.progress, in: 0...1)
    .onChange(of: playerVM.progress) {
        playerVM.seek(to: playerVM.progress)
    }
```

## CrainPaintVisualizer/Sources/DesignSystem/Modifiers/ToastModifier.swift

**Lines 23-26: `DispatchQueue.main.asyncAfter` makes toast dismissal uncancelable.**  
Current-baseline concurrency issue.

Every toast schedules a GCD dismissal on appear. If the same toast state is reused quickly, the old work item can still fire and dismiss a newer toast. Using `Task.sleep(for:)` keeps the lifetime tied to SwiftUI task cancellation instead of an unmanaged queue callback.

```swift
// Before
.onAppear {
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        withAnimation { isPresented = false }
    }
}

// After
.task(id: isPresented) {
    try? await Task.sleep(for: .seconds(3))
    guard isPresented else { return }
    withAnimation { isPresented = false }
}
```

## CrainPaintVisualizer/Sources/Services/VisualizationService.swift

**Lines 309-314: Replace GCD-backed continuations with structured Swift concurrency.**  
Current-baseline concurrency issue.

`runOffMain` wraps `DispatchQueue.global()` in `withCheckedContinuation`. That loses cancellation semantics and keeps image work running even if the caller disappears. Under stricter concurrency rules this is also harder to audit than a plain `Task` or actor-isolated worker.

```swift
// Before
await withCheckedContinuation { continuation in
    DispatchQueue.global(qos: .userInitiated).async {
        continuation.resume(returning: operation())
    }
}

// After
await Task(priority: .userInitiated) {
    operation()
}.value
```

## CrainPaintVisualizer/Sources/Services/ColorMatchService.swift

**Lines 257-262: Replace GCD-backed continuations with structured Swift concurrency.**  
Current-baseline concurrency issue.

This is the same pattern as `VisualizationService`: unstructured queue hopping for CPU-bound image work. The result is harder cancellation, harder reasoning about actor boundaries, and unnecessary duplication of a concurrency helper that should be centralized or replaced.

```swift
// Before
await withCheckedContinuation { continuation in
    DispatchQueue.global(qos: .userInitiated).async {
        continuation.resume(returning: operation())
    }
}

// After
await Task(priority: .userInitiated) {
    operation()
}.value
```

## CrainPaintVisualizer/Sources/Models/Visualization.swift

**Lines 316-321: Replace GCD-backed continuations with structured Swift concurrency.**  
Current-baseline concurrency issue.

The image repository uses the same helper again for thumbnail generation. It works today, but it duplicates the same unstructured queue pattern in the model layer and makes cancellation and performance tuning harder than they need to be.

```swift
// Before
await withCheckedContinuation { continuation in
    DispatchQueue.global(qos: .userInitiated).async {
        continuation.resume(returning: operation())
    }
}

// After
await Task(priority: .userInitiated) {
    operation()
}.value
```

## CrainPaintVisualizer/Sources/ViewModels/VisualizerViewModel.swift

**Lines 1281-1286: Replace GCD-backed continuations with structured Swift concurrency.**  
Current-baseline concurrency issue.

The view model repeats the same queue-backed continuation pattern. Because this type is `@MainActor`, keeping the off-main handoff structured matters even more: it prevents background work from becoming detached from the caller’s lifecycle.

```swift
// Before
await withCheckedContinuation { continuation in
    DispatchQueue.global(qos: .userInitiated).async {
        continuation.resume(returning: operation())
    }
}

// After
await Task(priority: .userInitiated) {
    operation()
}.value
```

## CrainPaintVisualizer/Sources/DesignSystem/Components/FullscreenImageViewer.swift

**Lines 179-199: Photo save UI reports success before the save result is known.**  
Current-baseline correctness/concurrency issue.

`saveToPhotos()` calls `UIImageWriteToSavedPhotosAlbum()` without a completion callback, then immediately shows “Saved to Photos”. If the write fails, the user still sees success. The toast dismissal also uses unmanaged GCD timers rather than cancellable tasks.

```swift
// Before
UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
DispatchQueue.main.async {
    savedAlertMessage = "Saved to Photos"
    withAnimation { showSavedAlert = true }
    dismissToast()
}

// After
Task { @MainActor in
    do {
        try await saveImageToLibrary(img)
        savedAlertMessage = "Saved to Photos"
    } catch {
        savedAlertMessage = "Couldn't save photo"
    }
    withAnimation { showSavedAlert = true }
    try? await Task.sleep(for: .seconds(2))
    withAnimation { showSavedAlert = false }
}
```

## CrainPaintVisualizer/Sources/ViewModels/ColorCatalogViewModel.swift

**Lines 89-90: Avoid `Task.detached()` inside the actor-backed catalog cache.**  
Modernize-next issue.

`SharedColorCatalogStore` already owns task coordination. Spawning catalog loads as detached tasks throws away actor inheritance and cancellation for little benefit. A regular `Task(priority:)` is easier to reason about and still keeps the work asynchronous.

```swift
// Before
Task.detached(priority: priority) {
    let index = try ColorCatalogViewModel.buildBrandIndex(for: brand)
    return index
}

// After
Task(priority: priority) {
    try ColorCatalogViewModel.buildBrandIndex(for: brand)
}
```

## Summary

1. **Fix first:** Settle the tab-shell contract. Right now the codebase mixes `Home/Saved/Expert` semantics with a `Preview/Library/More` shell, and that is the root cause behind the current onboarding, tab reachability, and `home.primaryCTA` failures.
2. **Fix first:** Update the UI harness only after that shell decision. The current UI failures are deterministic contract mismatches, not timing flakes.
3. **Should fix:** Replace gesture-only tappable media and cards (`VisualizationDetailView`, `SavedHomeView`, `FavoritesView`) with real buttons so the interaction is discoverable to VoiceOver and easier to test.
4. **Should fix:** Raise the shared `micro` text token and add real labels to icon-only dismiss/back controls (`HowItWorksView`, `SampleOutputView`) so the UI remains readable and correctly announced.
5. **Should fix:** Remove the global `UIApplication.shared` safe-area lookups from sticky bottom controls (`CustomTabBar`, `FloatingActionBar`) so bottom hit targets are positioned from SwiftUI layout rather than a guessed window.
6. **Should fix:** Remove the repeated GCD continuation helpers and move the off-main work and transient UI timers to structured Swift concurrency.
7. **Modernize next:** Clean up the remaining manual bindings and detached tasks once the runtime shell regression is resolved.

## Verification Appendix

- Project configuration observed: `IPHONEOS_DEPLOYMENT_TARGET = 17.0`, `SWIFT_VERSION = 5.9`.
- `xcodebuild test -project CrainPaintVisualizer/CrainPaintVisualizer.xcodeproj -scheme CrainPaintVisualizer -destination 'platform=iOS Simulator,id=BD79ED14-9AED-438E-A41B-C5F14AD01D0E'`
- Unit-test baseline: `59/59` unit tests passed.
- UI-test baseline: failures reproduced immediately in onboarding/home/tab flows, including:
  - `testLearnMoreFlowCanDismissOrEnterVisualizer`
  - `testHomeDraftShowsStartNewPreviewAndDiscardCanCancelOrConfirm`
  - `testHomeWithoutDraftShowsOnlyPrimaryStartCTA`
  - `testHomeOpenSavedResetsToDesignCardsSection`
  - `testExpertHomePrimaryCTAShowsConsultationPrice`
- Runtime note: these failures line up with missing or renamed elements (`home.primaryCTA`, `Saved`, `Expert`) rather than flaky waits. I did not treat them as timing issues.
