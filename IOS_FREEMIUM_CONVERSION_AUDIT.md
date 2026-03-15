# iOS Freemium Conversion Audit

Updated: March 8, 2026

## Thesis

The product should be monetized as:

- `Free starter experience`: enough AI renders to prove the product works on the user's real room.
- `Core paid plan`: a recurring subscription for continued AI render usage and better decision-making tools.
- `Curt consultation`: a separate one-off upsell for users who want expert confidence on top of the core app.

Curt should not be the primary monetization path. The subscription has to stand on its own.

## Committee Consensus

### Recommended free allowance

Start with `3 free completed renders`, then gate the `4th render attempt`.

Why `3` is the right starting point for this category:

- One render is not enough to trust an AI paint app.
- Two renders is enough to compare, but not enough to feel committed.
- Three renders maps well to real homeowner behavior: safe option, bolder option, fallback option.
- Gating before the first successful result is too early.
- Giving too many free renders lets users solve the core job without paying.

This should be treated as a starting hypothesis and tested, but it is the strongest default for the home paint use case.

### Recommended upsell sequence

Use a `soft -> stronger -> hard gate` progression.

1. After the first successful render:
   Show a soft prompt, not a hard paywall.

   Suggested message:
   `You have 2 free renders left. Compare a few serious directions before you commit.`

2. After the second successful render:
   Show a stronger comparison-focused upsell.

   Suggested message:
   `Want more options, saved projects, and better side-by-side comparison? Unlock the full app.`

3. On the fourth render attempt:
   Show the hard paywall.

   Suggested message:
   `You used your 3 free room renders. Upgrade to keep testing colors in your space.`

### Recommended Curt upsell timing

Curt should be positioned as `decision confidence`, not `more renders`.

Best moments:

- After a user saves 2 or more finalists.
- After repeated revisits to the same shortlisted renders.
- After a user shares a result.
- After a subscriber still seems stuck between finalists.
- Inside the result detail view after value is already clear.

Best positioning:

- AI helps users `explore`.
- Curt helps users `commit`.

## Current Funnel Audit

### 1. Onboarding is visual, but not monetization-aware

The current welcome flow is a one-time splash that immediately marks onboarding complete when the user taps `Get Started`, with no segmentation, no free allowance framing, and no expectation setting for a recurring paid plan.

Relevant files:

- [WelcomeView.swift](/Users/natelarkin/Crain%20Paint%20Visualizer%20-%20IOS%20app/CrainPaintVisualizer/Sources/Features/Welcome/WelcomeView.swift#L31)
- [AppState.swift](/Users/natelarkin/Crain%20Paint%20Visualizer%20-%20IOS%20app/CrainPaintVisualizer/Sources/Navigation/AppState.swift#L7)

### 2. The app teaches the expert offer too early

The current `HowItWorksView` makes `Expert Review` the third step of the core story. That is wrong for the monetization model you clarified. The first-run story should sell the self-serve visualizer first and keep Curt as an optional next step once the user has a shortlist.

Relevant file:

- [HowItWorksView.swift](/Users/natelarkin/Crain%20Paint%20Visualizer%20-%20IOS%20app/CrainPaintVisualizer/Sources/Features/Welcome/HowItWorksView.swift#L9)

### 3. The first real product step is too abstract

The current flow starts with brand selection, then color browsing, then photo upload, then surface selection. That front-loads catalog decisions before the user sees any value in their own room.

For an AI home visualization product, the highest-intent moment is usually `I want to see my room`, not `I want to choose a paint manufacturer first`.

Relevant files:

- [BrandSelectorView.swift](/Users/natelarkin/Crain%20Paint%20Visualizer%20-%20IOS%20app/CrainPaintVisualizer/Sources/Features/Visualizer/BrandSelectorView.swift#L17)
- [ItemPickerView.swift](/Users/natelarkin/Crain%20Paint%20Visualizer%20-%20IOS%20app/CrainPaintVisualizer/Sources/Features/Visualizer/ItemPickerView.swift#L14)
- [PhotoUploadView.swift](/Users/natelarkin/Crain%20Paint%20Visualizer%20-%20IOS%20app/CrainPaintVisualizer/Sources/Features/Visualizer/PhotoUploadView.swift#L14)
- [SurfacePickerView.swift](/Users/natelarkin/Crain%20Paint%20Visualizer%20-%20IOS%20app/CrainPaintVisualizer/Sources/Features/Visualizer/SurfacePickerView.swift#L11)

### 4. The current results flow is not monetization-ready

The current gallery fabricates visualization objects from selected colors and applies a tinted local preview over the uploaded photo. There is no real render lifecycle, entitlement check, usage accounting, or job status model yet.

That means the app is not currently structured to support a real freemium render meter.

Relevant files:

- [GalleryViewModel.swift](/Users/natelarkin/Crain%20Paint%20Visualizer%20-%20IOS%20app/CrainPaintVisualizer/Sources/ViewModels/GalleryViewModel.swift#L24)
- [VisualizerViewModel.swift](/Users/natelarkin/Crain%20Paint%20Visualizer%20-%20IOS%20app/CrainPaintVisualizer/Sources/ViewModels/VisualizerViewModel.swift#L6)
- [ResultsGalleryView.swift](/Users/natelarkin/Crain%20Paint%20Visualizer%20-%20IOS%20app/CrainPaintVisualizer/Sources/Features/Gallery/ResultsGalleryView.swift#L22)
- [VisualizationDetailView.swift](/Users/natelarkin/Crain%20Paint%20Visualizer%20-%20IOS%20app/CrainPaintVisualizer/Sources/Features/Gallery/VisualizationDetailView.swift#L17)

### 5. Curt is overexposed in the core navigation

The app currently gives `Expert` a full tab and pushes Curt hard from result detail screens. That makes sense if consultation is the main paid product. It is less optimal if consultation is meant to be an add-on upsell to the core subscription product.

Relevant files:

- [AppTab.swift](/Users/natelarkin/Crain%20Paint%20Visualizer%20-%20IOS%20app/CrainPaintVisualizer/Sources/Navigation/AppTab.swift#L3)
- [ExpertHomeView.swift](/Users/natelarkin/Crain%20Paint%20Visualizer%20-%20IOS%20app/CrainPaintVisualizer/Sources/Features/Expert/ExpertHomeView.swift#L8)
- [VisualizationDetailView.swift](/Users/natelarkin/Crain%20Paint%20Visualizer%20-%20IOS%20app/CrainPaintVisualizer/Sources/Features/Gallery/VisualizationDetailView.swift#L117)
- [ConsultationCheckoutView.swift](/Users/natelarkin/Crain%20Paint%20Visualizer%20-%20IOS%20app/CrainPaintVisualizer/Sources/Features/Reports/ConsultationCheckoutView.swift#L18)

## Recommended Product Model

### Free

- 3 completed AI renders.
- Basic before/after compare.
- Save favorites.
- Watermarked share export.
- Limited project history.

### Core subscription

Start with one plan before introducing tiers.

Recommended starting plan:

- `20 renders / month`
- unlimited saved projects
- HD exports
- no watermark
- faster queue priority if supported
- batch compare tools
- richer project history

Only add a second tier later if users frequently hit the cap.

### Curt consultation add-on

One-off purchase, fully separate from subscription entitlement.

Position it as:

- final decision help
- whole-room context
- lighting and coordination judgment
- confidence before buying paint and labor

## Recommended Journey Redesign

### New first-run structure

1. `Welcome`
   Show what the app does, explicitly state `3 free renders`, and set the expectation that users can try it before paying.

2. `Upload your room first`
   Get the user emotionally invested in their own space immediately.

3. `Select surface`
   Keep scope clear so the result feels believable.

4. `Choose a starter direction`
   Let users pick colors, use AI suggestions, or start from popular palettes.

5. `Generate first render`
   This is the first true value moment.

6. `Results and comparison`
   Introduce remaining free renders, shortlist behavior, and the upgrade path.

### Screen-level changes

#### Welcome

Replace generic trust language with product-specific promise:

- `See your room in 3 free realistic paint previews.`
- `No subscription required to try it.`

Add one clear free meter:

- `3 free renders included`

#### How It Works

Change the narrative from:

- pick palette
- snap and upload
- expert review

To:

- upload your room
- test a few color directions
- compare, save, and upgrade if you want more

Curt should appear as an optional secondary section:

- `Need a second opinion? Ask Curt after you shortlist your favorites.`

#### Visualizer setup

Reorder the main flow to reduce pre-value cognitive load.

Recommended order:

- photo
- surface
- colors
- result

Brand should move later, or be folded into color filters instead of becoming a separate first decision.

#### Results gallery

This becomes the most important conversion surface.

Add:

- a persistent `renders remaining` meter
- `Try another color` CTA
- `Unlock 20 renders/month` CTA
- shortlist tools
- project save state

After the first good render, do not interrupt the full screen with a hard paywall. Use a compact inline upgrade card.

#### Result detail

Keep Curt here, but reposition the messaging:

- first CTA: keep exploring or upgrade core plan
- secondary CTA: ask Curt for help choosing between finalists

Suggested consultation copy:

- `Still deciding? Get Curt's expert recommendation on your top options.`

### Navigation changes

If consultation is truly an add-on, `Expert` should likely not remain a permanent primary tab.

Recommended primary tab set:

- `Visualize`
- `Projects`
- `Favorites`
- `Account`

Then surface Curt contextually:

- result detail
- project shortlist screen
- locked comparison tools
- account/services screen

## Recommended Monetization Architecture

### Principles

- The server, not the device, must decide whether a render is allowed.
- Failed renders must not burn usage.
- Consultation purchases must be completely separate from subscription entitlements.
- Paywall copy, timing, and offers should be remotely configurable.

### Backend objects

Add these backend concepts:

- `app_user`
- `subscription_state`
- `usage_allowance`
- `render_job`
- `entitlement_snapshot`
- `consultation_order`
- `experiment_assignment`
- `analytics_event`

### Required app services

- `MonetizationManager`
- `SubscriptionManager`
- `AllowancePolicy`
- `AnalyticsManager`
- `ExperimentManager`

### Required backend endpoints

- `GET /api/mobile/entitlements`
- `GET /api/mobile/config`
- `POST /api/mobile/iap/verify`
- `POST /api/mobile/iap/restore`
- `POST /api/mobile/render/authorize`
- `POST /api/visualize` updated to respect reserved usage
- `POST /api/mobile/events`

### Render accounting model

Use reservation semantics:

1. user taps generate
2. backend reserves one render
3. render job runs
4. if success, mark consumed
5. if failure, release reservation

This is mandatory for trust. Users will churn quickly if failed AI generations still count against their cap.

## Event Instrumentation

Track at minimum:

- `onboarding_started`
- `onboarding_completed`
- `photo_uploaded`
- `surface_selected`
- `render_attempted`
- `render_succeeded`
- `render_failed`
- `free_limit_hit`
- `paywall_impression`
- `paywall_cta_tapped`
- `subscription_started`
- `subscription_converted`
- `subscription_restored`
- `subscription_lapsed`
- `favorite_saved`
- `share_tapped`
- `consultation_cta_viewed`
- `consultation_started`
- `consultation_purchased`

Include with each event:

- install user ID
- current entitlement state
- renders remaining
- source screen
- selected color count
- selected surface
- experiment/paywall variant

## 90-Day Rollout

### Phase 1

- implement real render job lifecycle
- create free render meter
- add StoreKit 2 subscription
- gate on the fourth render attempt
- add analytics and remote config

### Phase 2

- reorder onboarding to photo-first
- redesign results gallery around compare and upgrade
- demote Curt from primary navigation to contextual upsell

### Phase 3

- optimize paywall timing and copy
- test 3 vs 4 free renders
- test 15 vs 20 vs 30 monthly renders
- target Curt upsell only to high-intent segments

## Immediate Recommendations

If you want the shortest path to higher conversion, do these first:

1. Keep the first successful render completely free.
2. Give `3 free completed renders`.
3. Trigger the hard paywall on the `4th render attempt`.
4. Reframe Curt as an add-on consultation for indecisive or high-intent users.
5. Move the core app story away from expert/report language and toward self-serve decision confidence.
6. Rebuild the results screen around remaining usage, comparison, and upgrade.

## Source Notes

These recommendations also align with current platform guidance and subscription best practices:

- Apple subscription guidance says recurring plans need `ongoing value`, which supports bundling monthly renders, saved projects, exports, and continuing feature value rather than selling only one-off access.
  Source: [Apple Auto-renewable Subscriptions](https://developer.apple.com/app-store/subscriptions/)
- Apple App Review allows subscriptions alongside `a la carte offerings`, which supports the model of `core subscription + separate Curt consultation`.
  Source: [Apple App Review Guidelines 3.1.2](https://developer.apple.com/app-store/review/guidelines/)
- RevenueCat's paywall guidance supports using both onboarding paywalls and contextual paywalls, which fits a soft post-value prompt plus a harder limit-triggered paywall.
  Source: [RevenueCat mobile paywall guide](https://www.revenuecat.com/blog/growth/guide-to-mobile-paywalls-subscription-apps/)
- RevenueCat's more recent targeting guidance reinforces that context matters, which is why Curt should appear after shortlist behavior rather than at first launch.
  Source: [RevenueCat contextual paywall targeting](https://www.revenuecat.com/blog/growth/contextual-paywall-targeting/)
