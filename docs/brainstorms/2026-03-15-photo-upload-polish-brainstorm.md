# Photo Upload Screen Polish — Top-10 iOS App Quality

**Date:** 2026-03-15
**Status:** Ready for planning
**Screen:** `PhotoUploadView.swift` (Step 1 of 4 in Visualizer flow)

## What We're Building

A comprehensive visual polish pass on the Photo Upload screen to elevate it from "functional web-port" to "premium native iOS app." The current screen works but relies on web-native patterns (dashed borders, flat layout, disconnected helper text) that undermine perceived quality. This redesign preserves all existing functionality while replacing every visual element with iOS-native equivalents.

## Why This Approach

The Photo Upload screen is the **first interaction** in the core visualizer flow — it sets the quality bar for the entire app experience. Users who see a polished, native-feeling first screen trust the AI results more. Every decision below prioritizes native iOS patterns over web conventions while keeping the implementation scope tight (no new features, just polish).

## Key Decisions

### 1. Hero Illustration Card (replaces dashed-border upload area)

**What:** Replace the dashed-border container with a solid, elevated card featuring:
- Teal-tinted SF Symbol cluster at the top (camera.fill + paintbrush.pointed + photo.on.rectangle.angled, overlapping with varying opacity 0.3–1.0)
- "Take or Upload Photo" heading + "Tap to get started" subtext
- Camera and Library buttons as compact action buttons inside the card
- Lighting tip and Color Matcher link integrated as card footer (below a subtle divider)
- Solid background (`cBackgroundElevated`), `radiusXL` (24pt) corners, theme shadow (MD level)

**Why:** Dashed borders are a drag-and-drop web pattern. Native iOS apps use elevated cards with clear hierarchy. Containing everything in one card reduces visual noise and creates a clear call-to-action zone.

### 2. Pill Step Progress Indicator

**What:** Replace compact progress bars with connected pill-shaped steps:
- Four pills: Photo → Surface → Colors → Result
- Active step: teal gradient fill + subtle glow (shadow with teal tint) + bold label
- Completed steps: teal fill + checkmark icon
- Upcoming steps: muted fill (`cSurfaceMuted`) + regular weight label
- Animated fill transition between steps (spring, 0.35s)

**Why:** The current bars are functional but anonymous — users can't tell what's coming next. Labeled pills give context and reduce "how many steps is this?" anxiety, which is critical for conversion in a multi-step flow.

### 3. Subtle & Purposeful Micro-Interactions

**What:**
- **Card entrance:** Spring slide-up animation (response: 0.6, damping: 0.8) on appear
- **Camera/Library buttons:** Scale to 0.97 on press + light haptic (`.impact(.light)`)
- **Photo selected:** Thumbnail crossfades in with scale from 0.95 → 1.0 + `.success` haptic
- **Continue button:** Slides up from below when photo is ready (spring, 0.35s)
- All animations respect `UIAccessibility.isReduceMotionEnabled`

**Why:** Premium apps feel "alive" without being distracting. These four interactions mark the key moments in the screen's lifecycle: arrive, choose, confirm, proceed.

### 4. Inline Helper Content

**What:** Move the lighting tip and Color Matcher link inside the hero card:
- Thin divider (1pt, `cBorder` color) separating action area from helper area
- Lighting tip: `lightbulb.fill` icon + caption text, muted color
- Color Matcher: `eyedropper` icon + teal link text, tappable

**Why:** Floating helper text below the card creates visual orphans. Containing it in the card keeps the screen clean and ensures users see the tips in context.

### 5. Subtle Background Gradient

**What:** Replace flat `#FAFAFA` with a very soft top-to-bottom gradient:
- Top: `#FAFAF8` (warm white)
- Bottom: `#F5F5F7` (cool white)
- Barely perceptible shift that adds subconscious depth

**Why:** Flat single-color backgrounds read as "unfinished." A subtle gradient is one of those invisible polish details that separates good from great — Apple uses this throughout iOS.

### 6. Navigation & Header Refinements

**What:**
- Keep "Add Photo" title and back button
- Step label ("Step 1 of 4") integrated into the pill progress indicator — remove the separate text
- Remove the redundant "Photo" label on the right side of the progress area

**Why:** The current header has redundant information (step number + step name + progress bar). The pill indicator communicates all of this in one element.

## Visual Summary

```
┌─────────────────────────────────┐
│  ← Back       Add Photo         │  nav bar
│                                 │
│  [●Photo]──[Surface]──[Colors]──[Result]  │  pill steps
│                                 │
│  Upload a clear photo of the    │  helper text
│  room you want to repaint.      │
│                                 │
│  ┌───────────────────────────┐  │
│  │     📷  🎨  🖼️            │  │  SF Symbol cluster
│  │   (overlapping, teal)     │  │  (teal tinted)
│  │                           │  │
│  │  Take or Upload Photo     │  │  heading
│  │  Tap to get started       │  │  subtext
│  │                           │  │
│  │  [📷 Camera] [🖼 Library] │  │  action buttons
│  │                           │  │
│  │  ─────────────────────    │  │  divider
│  │  💡 Even lighting = best  │  │  tip (muted)
│  │  🎨 Open Color Matcher    │  │  link (teal)
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │    → Continue to Surface  │  │  CTA (slides up when ready)
│  └───────────────────────────┘  │
└─────────────────────────────────┘
Background: subtle warm→cool gradient
```

## Files to Modify

| File | Changes |
|------|---------|
| `PhotoUploadView.swift` | Replace upload area with hero card, add animations, gradient background |
| `StepProgressView.swift` | Add new `.pill` display style with labeled steps |
| `BrandedHeader.swift` / `WizardHeader` | Update to use pill progress, remove redundant labels |
| `ColorTokens.swift` | Add background gradient colors if not present |
| `FloatingActionBar.swift` | Add slide-up entrance animation |

## Open Questions

None — all design decisions are resolved.

## Out of Scope

- Photo preview state redesign (only the empty/upload state is being polished)
- Camera view redesign (CameraView.swift stays as-is)
- New features or functionality changes
- Dark mode adjustments (existing adaptive tokens should carry over)
