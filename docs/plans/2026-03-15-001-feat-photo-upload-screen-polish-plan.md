---
title: "feat: Polish PhotoUploadView to Top-10 iOS App Quality"
type: feat
status: completed
date: 2026-03-15
origin: docs/brainstorms/2026-03-15-photo-upload-polish-brainstorm.md
---

# feat: Polish PhotoUploadView to Top-10 iOS App Quality

## Overview

Comprehensive visual polish of the Photo Upload screen (Step 1 of the Visualizer wizard) to replace web-native patterns with premium iOS-native equivalents. This is a **visual-only** change — no new features, no functionality changes, no backend modifications.

The Photo Upload screen is the first interaction in the core visualizer flow. Its perceived quality sets the bar for the entire app experience.

## Problem Statement

The current `PhotoUploadView` uses web-derived patterns that undermine perceived quality:
- Dashed-border upload container (web drag-and-drop pattern, not native iOS)
- Flat anonymous progress bars with no step labels
- Zero animations or micro-interactions (the only animation is `ScaleButtonStyle` inherited from `AppButton`)
- Disconnected helper text floating below the card
- Flat single-color background

These patterns are functional but read as "web port" rather than "premium native app."

## Proposed Solution

Six targeted changes that collectively elevate the screen to top-10 iOS app quality (see brainstorm: `docs/brainstorms/2026-03-15-photo-upload-polish-brainstorm.md`):

1. **Hero illustration card** — replace dashed-border area with solid elevated card
2. **Pill step progress indicator** — replace compact bars with labeled connected pills
3. **Subtle micro-interactions** — spring entrance, press scale+haptic, photo crossfade, CTA animation
4. **Inline helper content** — move tip and Color Matcher inside the hero card
5. **Background gradient** — subtle warm-to-cool vertical gradient
6. **reduceMotion accessibility** — gate all animations behind accessibility check

## Technical Approach

### Architecture

No architectural changes. All modifications are within existing view files and design system components. The `VisualizerViewModel`, `PhotoProcessingService`, `PhotoIntakeCoordinator`, and `CameraView` remain untouched.

### Implementation Phases

#### Phase 1: Design System Additions (Foundation)

**Files:** `StepProgressView.swift`, `ColorTokens.swift`, `Theme.swift`

**1a. Add `.pill` style to `StepProgressView.swift`**

Add a new `DisplayStyle.pill` case alongside existing `.classic` and `.compact` styles.

Pill step indicator spec:
- Four connected pills in an `HStack` with `Spacer()` between
- Each pill: `Capsule()` shape, horizontal padding 12, vertical padding 6
- Active step: `theme.ctaGradient` fill + teal glow shadow (`theme.actionPrimary.opacity(0.3)`, radius 6) + `theme.label` font bold + white text
- Completed steps: `theme.primary` solid fill + checkmark SF Symbol (`checkmark`) + white text + `theme.label` font
- Upcoming steps: `theme.muted` fill + `theme.textSecondary` color + `theme.label` font regular weight
- Connecting lines: 1pt `theme.border` between pills, vertically centered
- Animated fill transition: `withAnimation(Theme.animationDefault)` on step change
- Step labels: ["Photo", "Surface", "Colors", "Review"] (keep "Review" — matches other screens)
- **No tap-to-navigate** — display only, matching current behavior
- Fixed total of 4 steps (per UX audit: step counts must be stable)

**1b. Add background gradient tokens to `ColorTokens.swift`**

```swift
// Background gradient (light mode only)
static let backgroundGradientTop = Color(hex: "FAFAF8")    // warm white (matches cBackground)
static let backgroundGradientBottom = Color(hex: "F5F5F7")  // cool white
```

Dark mode: skip gradient, use flat `cBackground`. The gradient is too subtle to matter in dark mode.

**1c. Add gradient helper to `Theme.swift`**

```swift
var backgroundGradient: LinearGradient {
    LinearGradient(
        colors: [ColorTokens.backgroundGradientTop, ColorTokens.backgroundGradientBottom],
        startPoint: .top,
        endPoint: .bottom
    )
}
```

**Acceptance criteria:**
- [x] `StepProgressView` supports `.pill` style with all three states (active, completed, upcoming)
- [x] Pill transitions animate on step change
- [x] Background gradient tokens exist in `ColorTokens.swift`
- [x] `Theme.backgroundGradient` computed property works

---

#### Phase 2: Hero Card & Layout (Core Visual Change)

**Files:** `PhotoUploadView.swift`, `BrandedHeader.swift`

**2a. Replace dashed-border upload area with hero card**

Remove the entire empty state block (current lines ~119-158) that uses `StrokeStyle(lineWidth: 1.5, dash: [8])` and replace with:

```swift
// Hero illustration card
VStack(spacing: theme.space16) {
    // SF Symbol cluster
    PhotoUploadIllustration()  // extracted subview

    // Title + subtitle
    Text("Take or Upload Photo")
        .font(theme.heading2)
        .foregroundStyle(theme.textPrimary)
    Text("Capture or select the room you want to visualize")
        .font(theme.bodyDefault)
        .foregroundStyle(theme.textSecondary)

    // Camera + Library buttons (existing, restyled)
    HStack(spacing: theme.space12) { /* Camera button */ /* Library button */ }

    // Divider
    Divider().foregroundStyle(theme.border)

    // Inline helper content
    HStack { /* lightbulb.fill icon + tip text */ }
    HStack { /* eyedropper icon + Color Matcher link */ }
}
.padding(theme.space24)
.background(theme.card)
.clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
.overlay(RoundedRectangle(cornerRadius: theme.radiusXL).stroke(theme.border.opacity(0.8), lineWidth: 1))
.shadow(color: .black.opacity(0.12), radius: 12, y: 4)  // theme shadowMD equivalent
```

**SF Symbol cluster (`PhotoUploadIllustration` subview):**
- Three overlapping SF Symbols in a `ZStack`:
  - `photo.on.rectangle.angled` — 44pt, teal opacity 0.3, offset(-12, 8)
  - `paintbrush.pointed` — 38pt, teal opacity 0.5, offset(14, -6)
  - `camera.fill` — 48pt, teal opacity 1.0, centered (front)
- All rendered with `.symbolRenderingMode(.hierarchical)` and `.foregroundStyle(theme.primary)`
- Contained in a 100x80pt frame
- This is a private subview within `PhotoUploadView.swift` — no new file needed

**2b. Update `WizardHeader` to use `.pill` style**

In `BrandedHeader.swift`, update `WizardHeader` to pass `.pill` instead of `.compact` to `StepProgressView`. Remove the "Step X of Y" text label — the pills communicate this information.

Keep the helper text below the pills ("Upload a clear photo of the room you want to repaint.").

**2c. Helper content inside the card**

Move the inline hint (lighting tip) and Color Matcher link from their current positions below the upload area to inside the hero card, below a `Divider()`.

**Important decision (from SpecFlow analysis):** The tip and Color Matcher link are only visible in the empty state. Once a photo is selected, the hero card is replaced by the photo preview. This is acceptable — the lighting tip is most useful *before* taking a photo, and the Color Matcher can be accessed from the tab bar. If this proves problematic in testing, we can add a subtle "Tips" disclosure below the photo preview in a follow-up.

**2d. Background gradient**

Replace the current flat background on the outer `VStack`/`ScrollView` with:
```swift
.background(theme.backgroundGradient.ignoresSafeArea())
```

**Acceptance criteria:**
- [x] Dashed border completely removed from empty state
- [x] Hero card renders with solid background, XL radius, MD shadow
- [x] SF Symbol cluster shows three overlapping teal-tinted symbols
- [x] Camera and Library buttons inside the card with consistent styling
- [x] Tip and Color Matcher link visible inside card footer (below divider)
- [x] Pill step progress shows in WizardHeader
- [x] Background gradient visible (warm top, cool bottom)
- [x] `.contentShape(Rectangle())` on all tappable elements for full hit targets

---

#### Phase 3: Micro-Interactions & Haptics (Polish)

**Files:** `PhotoUploadView.swift`, `FloatingActionBar.swift`

**3a. Card entrance animation**

On first appear only (not on back-navigation):
```swift
@State private var hasAppeared = false

// On the hero card:
.offset(y: hasAppeared ? 0 : 30)
.opacity(hasAppeared ? 1 : 0)
.animation(reduceMotion ? .none : .spring(response: 0.6, dampingFraction: 0.8), value: hasAppeared)
.onAppear { hasAppeared = true }
```

**3b. Camera/Library button press feedback**

The buttons already use `AppButton` with `ScaleButtonStyle` (scale 0.98 on press). Add haptic feedback:
```swift
.sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.5), trigger: /* button press state */)
```

Since `ScaleButtonStyle` already handles the press animation, we just need to add the haptic. Use `.sensoryFeedback(.impact(.light))` triggered on the tap action rather than modifying the button style.

**3c. Photo selection crossfade**

When `visualizerVM.photo` transitions from nil to a value, animate the content swap:
```swift
// Wrap the content switching in:
.transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.95)))
.animation(reduceMotion ? .none : Theme.animationDefault, value: visualizerVM.hasPhoto)
```

Keep the existing `.sensoryFeedback(.success, trigger: visualizerVM.hasPhoto)`.

**3d. CTA button state animation**

The "Continue to Surface" button is always visible but disabled until a photo is selected. Animate the enabled state transition:
```swift
// On the CTA button:
.opacity(visualizerVM.hasPhoto ? 1.0 : 0.5)
.animation(reduceMotion ? .none : Theme.animationDefault, value: visualizerVM.hasPhoto)
```

No positional slide — the button stays in place but gains full opacity and interactivity. This is cleaner than sliding and avoids the scroll padding complications identified in SpecFlow analysis.

**3e. reduceMotion support**

Add at the top of `PhotoUploadView`:
```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
```

Gate every animation:
- **Card entrance**: `reduceMotion ? .none : .spring(response: 0.6, dampingFraction: 0.8)`
- **Content transitions**: `reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.95))`
- **CTA opacity**: `reduceMotion ? .none : Theme.animationDefault`
- **Haptics still fire** regardless of reduceMotion (haptics are separate from visual motion)

**Acceptance criteria:**
- [x] Hero card slides up with spring on first appear
- [x] Camera/Library buttons have light haptic on tap
- [x] Photo preview crossfades in with subtle scale when photo is selected
- [x] CTA button animates from disabled to enabled state
- [x] All animations are gated behind `reduceMotion` check
- [x] Haptics fire regardless of reduceMotion setting

---

### Files to Modify (Complete List)

| File | What Changes | Lines Affected |
|------|-------------|----------------|
| `Sources/DesignSystem/Components/StepProgressView.swift` | Add `.pill` display style | New case + ~60 lines of pill rendering |
| `Sources/DesignSystem/ColorTokens.swift` | Add `backgroundGradientTop`, `backgroundGradientBottom` | +2 static properties |
| `Sources/DesignSystem/Theme.swift` | Add `backgroundGradient` computed property | +5 lines |
| `Sources/DesignSystem/Components/BrandedHeader.swift` | Update `WizardHeader` to use `.pill`, remove step count text | ~10 lines changed |
| `Sources/Features/Visualizer/PhotoUploadView.swift` | Hero card, SF cluster, inline helpers, animations, gradient bg | Major rewrite of empty state (~80 lines), +20 lines animation |

### Files NOT Modified

| File | Why Unchanged |
|------|--------------|
| `CameraView.swift` | Camera capture flow is out of scope |
| `VisualizerViewModel.swift` | No logic changes |
| `PhotoProcessingService.swift` | No processing changes |
| `FloatingActionBar.swift` | CTA stays in place; opacity animation is on the button, not the bar |
| `AppButton.swift` | Existing `ScaleButtonStyle` is sufficient |
| `AppCard.swift` | Hero card is custom inline, not using `AppCard` (different layout) |

## System-Wide Impact

**Minimal.** This is a visual-only change to one screen.

- **Interaction graph**: No new callbacks, no middleware, no observers. The view still calls the same `VisualizerViewModel` methods.
- **Error propagation**: Unchanged. (Note: SpecFlow identified silent `try?` on photo import as a pre-existing issue — out of scope for this polish pass but flagged for follow-up.)
- **State lifecycle**: No new state management. One `@State private var hasAppeared` added for entrance animation.
- **API surface parity**: No API changes.
- **Integration test scenarios**: Manual visual QA only — no unit-testable behavior changes.

## Acceptance Criteria

### Functional Requirements
- [x] All existing functionality preserved (Camera, Library, Color Matcher navigation, photo preview, Continue CTA)
- [x] Step progress shows labeled pills (Photo, Surface, Colors, Review) with correct active/completed/upcoming states
- [x] Hero card displays with solid background, rounded corners, shadow, and SF Symbol cluster
- [x] Tip and Color Matcher link visible inside hero card footer
- [x] Background shows subtle warm-to-cool gradient

### Non-Functional Requirements
- [x] All animations gated behind `@Environment(\.accessibilityReduceMotion)`
- [x] Haptics fire on button press and photo selection
- [x] `.contentShape(Rectangle())` on all tappable card elements
- [x] No layout issues on iPhone SE (smallest supported screen)
- [x] Dark mode renders correctly (gradient skipped, adaptive card colors)

### Quality Gates
- [x] Visual QA on iPhone 16 simulator
- [x] Visual QA on iPhone SE simulator (small screen)
- [x] Test with reduceMotion enabled in Accessibility settings
- [x] Test Camera flow end-to-end
- [x] Test Library flow end-to-end
- [x] Test Color Matcher navigation and return

## Resolved Questions (from SpecFlow)

| Question | Resolution |
|----------|-----------|
| SF Symbol cluster composition | `camera.fill` (front), `paintbrush.pointed` (mid), `photo.on.rectangle.angled` (back) — overlapping with teal tint at varying opacities |
| Helper text visibility after photo selection | Acceptable to lose in photo preview state — tip is most useful before capture, Color Matcher accessible via tab bar |
| Silent photo import failure | Out of scope — pre-existing issue, flagged for separate fix |
| reduceMotion fallback strategy | All spring/scale animations become `.none`. Opacity transitions become instant. Haptics still fire. |
| "Change Photo" behavior | Returns to empty hero card (matches current behavior) |
| Step label "Review" vs "Result" | Keep "Review" to match other screens |
| Background gradient dark mode | Skip gradient in dark mode, use flat `theme.background` |
| Pill steps tappable? | No — display only, matching current behavior |
| Card entrance on back-navigation | Only on first appear (`@State hasAppeared` flag) |
| CTA slide vs opacity | Opacity only — avoids scroll padding complications |

## Sources & References

### Origin
- **Brainstorm document:** [docs/brainstorms/2026-03-15-photo-upload-polish-brainstorm.md](docs/brainstorms/2026-03-15-photo-upload-polish-brainstorm.md) — Key decisions: hero card over dashed border, pill progress over bars, subtle animations over flashy, inline helpers over floating
- **UX Audit:** [docs/2026-03-12-second-board-whole-app-ux-audit.md](docs/2026-03-12-second-board-whole-app-ux-audit.md) — Step count stability requirement, full-card tap targets, CTA naming

### Internal References
- `PhotoUploadView.swift` — current implementation (231 lines)
- `StepProgressView.swift:1-114` — existing `.classic` and `.compact` styles
- `BrandedHeader.swift:155-179` — `WizardHeader` using `.compact`
- `AppButton.swift:117-123` — `ScaleButtonStyle` pattern
- `Theme.swift:138-152` — shadow tiers and animation definitions
- `ColorTokens.swift` — existing background tokens (`cBackground`, `cBackgroundElevated`)

### Existing Patterns to Follow
- Card styling: `theme.card` bg + `theme.radiusLG` corners + 1px border + shadow (used in `AppCard`, `ConsultationCheckoutView`)
- Spring animations: `Theme.animationDefault` (`.spring(response: 0.35)`) for standard, `.spring(response: 0.6)` for page-level
- Transitions: `.opacity.combined(with: .scale(scale: 0.98))` for content swaps
- Haptics: `.sensoryFeedback(.impact(.light))` for interactions, `.sensoryFeedback(.success)` for confirmations
