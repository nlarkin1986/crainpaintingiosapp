# Crain Paint Visualizer - New Screens Full Swarm Spec

## Skill Used
- `sleek-design-mobile-apps` (mobile UI/UX screen and journey specification)

## Scope Reviewed
- `New Screens/Color Matcher-1772761719501.png`
- `New Screens/Favorites-1772761725585.png`
- `New Screens/Design Report-1772761727767.png`
- `New Screens/Sample Output-1772761729934.png`

## Swarm Synthesis (5 lanes)
- Lane 1: Current app routing + tab architecture audit
- Lane 2: Color Matcher UX + capture flow wiring
- Lane 3: Favorites UX + save/retrieve behavior
- Lane 4: Master Report UX + recommendations/reports domain
- Lane 5: Sample Output video/paywall/consultation funnel

---

## 1) Current App Architecture (ground truth)

### Navigation + tabs
- App uses `TabView` with per-tab `NavigationStack` paths via `TabRouter`.
- Tabs today: `visualize`, `gallery`, `favorites`, `expert`.
- Route enum exists and already includes `.colorMatcher`, but no active navigation call reaches it.

Code anchors:
- `CrainPaintVisualizer/Sources/CrainPaintVisualizerApp.swift`
- `CrainPaintVisualizer/Sources/Navigation/AppTab.swift`
- `CrainPaintVisualizer/Sources/Navigation/AppRoute.swift`
- `CrainPaintVisualizer/Sources/DesignSystem/Modifiers/AppRouterModifier.swift`
- `CrainPaintVisualizer/Sources/Navigation/RouterPath.swift`

### Existing feature wiring
- Visualize flow currently: `BrandSelector -> ItemPicker -> PhotoUpload -> SurfacePicker -> ResultsGallery`.
- Favorites tab is live and functional with mock/in-memory data + search.
- Gallery + VisualizationDetail exist and include placeholder CTA `Get Expert Consultation` with no action.
- Expert tab is a placeholder (`Coming Soon`).

### Services/data layer status
- No network/service abstraction yet (no API clients, repository layer).
- Most screens use mock arrays in ViewModels.
- Persistence only used for onboarding flag in `UserDefaults`.

Implication: new screens are product-valid but require a new Reports/Expert data domain and service layer before production wiring.

---

## 2) IA + Navigation Recommendation

### Recommended tab model (v2)
To match the new screen language while minimizing disruption:
1. `Visualize` (existing)
2. `Favorites` (existing)
3. `Reports` (new, from current `gallery` tab role expansion)
4. `Expert` (existing tab, now real consultation funnel)

Notes:
- Keep `Gallery` content inside Reports as a segment (`Visualizations` / `Reports`) or nested entry.
- Preserve existing `Favorites` tab from new mock.

### Route additions
Extend `AppRoute` with:
- `case reportsHome`
- `case masterReport(reportId: String)`
- `case sampleOutput(reportId: String, chapterId: String?)`
- `case consultationCheckout(reportId: String)`

Keep and actively use:
- `case colorMatcher`

---

## 3) User Journey Wiring (end-to-end)

1. Onboarding -> `Visualize` tab
2. User selects brand/colors/photo/surface
3. User can optionally open **Color Matcher** to detect a real-world object color
4. Matched color gets added to selected palette and/or Favorites
5. User generates visualization (existing gallery/result behavior)
6. System generates a **Master Report** (personalized video + room recommendations)
7. User opens report, watches preview/sample output
8. User taps **Book Your Master Consultation**
9. User enters Expert booking/payment flow
10. Completion confirmation + report remains in Reports history

---

## 4) Screen-by-Screen Product Spec

## A. Color Matcher Screen

### Product intent
- Capture real-world color from camera and return cross-brand paint matches.

### Entry points
- `ItemPicker` “Match” filter CTA -> `router.navigate(to: .colorMatcher)`.
- Optional secondary entry from `PhotoUpload` (“Match from object”).

### Primary actions
- Close (`X`) -> return to previous route.
- Analyze capture (auto or button).
- Add match (`+`) -> add to `VisualizerViewModel.selectedColors` (if < limit) and optionally `FavoritesViewModel`.
- Retake photo.

### Required states
- Camera permission denied.
- Aligning/analyzing.
- Matches found (ranked list).
- No confident match.
- Error/offline.

### Data contract
- Input: frame image + optional crop rect.
- Output: ranked `ColorMatchResult[]` with `{ brand, code, name, hex, confidence }`.

### UX details
- Keep confidence badges visible (`98% match`).
- Highlight top result.
- Use non-blocking toasts for “Added to favorites” / “Added to palette”.

---

## B. Favorites Screen

### Product intent
- Fast retrieval of saved colors, cross-brand sorting/filtering, quick jump to visualize.

### Entry points
- Favorites tab root.
- Deep link from “save color” events after matching/report recommendations.

### Primary actions
- Search favorites.
- Sort by brand/date/recently-used.
- Toggle favorite heart.
- Tap color card -> action sheet: `Visualize`, `View report recommendation`, `Share`.

### Required states
- Empty favorites.
- Search with 0 results.
- Large list (pagination/lazy load).

### Data/persistence
- Move from in-memory list to persistent store (`SwiftData`/CoreData/remote profile sync).

---

## C. Master Report Screen (Design Report)

### Product intent
- High-trust, personalized analysis summary with narrative video + recommended room outcomes.

### Entry points
- Reports tab root list.
- Post-visualization completion CTA: “Generate Master Report”.
- Push notification/deep link when report is ready.

### Primary actions
- Play personalized video.
- Open room recommendation details.
- Save recommended color to Favorites.
- Share report.

### Required states
- Report generating (skeleton/progress).
- Ready with content.
- Partial content (video still processing, recommendations ready).
- Failed generation + retry.

### Data contract
`MasterReport`
- `id`, `curatorName`, `heroVideoUrl`, `duration`, `createdAt`
- `recommendations: [RoomRecommendation]`
- `status: generating | ready | failed`

`RoomRecommendation`
- `roomType`, `beforeImageUrl`, `afterImageUrl`, `suggestedColor`, `rationaleText`

---

## D. Sample Output Video Screen

### Product intent
- Premium conversion surface showing chaptered expert analysis preview + consultation upsell.

### Entry points
- Master Report video card tap.
- Reports -> selected report -> “Watch walkthrough”.

### Primary actions
- Play/pause + scrub timeline.
- View chapter context badge (`Chapter 1: Living Room`).
- CTA: `Book Your Master Consultation`.
- Close and return to report.

### Required states
- Loading/buffering.
- Playback active/paused.
- Playback error.
- Entitlement locked vs unlocked.

### UX requirements
- Keep CTA persistent and visible near bottom.
- Clearly indicate recording/sample included in package.
- Preserve watch progress for resume.

### Tech
- `AVPlayer` + observer for progress.
- Track chapter boundaries as timestamps.

---

## 5) Proposed App Wiring Changes (by file)

## Navigation
- Update `CrainPaintVisualizer/Sources/Navigation/AppTab.swift`
  - Add `reports` case and real `ReportsHomeView`.
  - Replace placeholder-only expert with `ExpertHomeView` + booking flow.

- Update `CrainPaintVisualizer/Sources/Navigation/AppRoute.swift`
  - Add report/video/consultation routes listed above.

- Update `CrainPaintVisualizer/Sources/DesignSystem/Modifiers/AppRouterModifier.swift`
  - Register new destinations.

## Visualizer flow
- Update `CrainPaintVisualizer/Sources/Features/Visualizer/ItemPickerView.swift`
  - Add explicit “Match from Camera” CTA (route to `.colorMatcher`).

- Update `CrainPaintVisualizer/Sources/Features/Visualizer/ColorMatcherView.swift`
  - Replace static mock `matches` with ViewModel-backed async results.
  - Wire `+` action into Favorites + selected palette.

## New feature modules (recommended)
- `Sources/Features/Reports/ReportsHomeView.swift`
- `Sources/Features/Reports/MasterReportView.swift`
- `Sources/Features/Reports/SampleOutputView.swift`
- `Sources/ViewModels/ReportsViewModel.swift`
- `Sources/ViewModels/VideoPlayerViewModel.swift`
- `Sources/Services/ReportService.swift`
- `Sources/Services/ColorMatchService.swift`
- `Sources/Services/FavoritesStore.swift`

---

## 6) State + Domain Model Additions

## ViewModels
- `ReportsViewModel`
  - list reports, poll generation status, expose loading/error/ready.
- `ColorMatcherViewModel`
  - camera authorization, capture state, analysis progress, ranked matches.
- `VideoPlayerViewModel`
  - chapter mapping, watch progress persistence, CTA state.

## Shared entities
- `ColorMatchResult`
- `MasterReport`
- `RoomRecommendation`
- `ConsultationPackage`

---

## 7) Analytics + Success Metrics

Track at minimum:
- `color_match_opened`, `color_match_completed`, `color_match_saved`
- `favorite_saved`, `favorite_removed`, `favorite_visualize_tap`
- `report_generation_started`, `report_ready`, `report_viewed`
- `sample_output_played`, `sample_output_25_50_75_100`
- `consultation_cta_tapped`, `consultation_booking_started`, `consultation_booking_completed`

Core funnel:
- Visualize completion -> Report view -> Sample play -> Consultation booking

---

## 8) Accessibility + UX Quality Bar

- Dynamic type support for cards, chips, and CTA labels.
- 44pt touch targets for top controls and favorite toggles.
- VoiceOver labels for color cards: brand + name + code + confidence.
- Captions/transcript for personalized video.
- Color contrast check on confidence badges over swatches.

---

## 9) Delivery Scope (engineering)

## Phase 1 (Low risk / 1-1.5 weeks)
- Wire Color Matcher route from visualizer flow.
- Persist Favorites (local store).
- Add empty/error/loading states to Favorites + Matcher.

## Phase 2 (Medium / 1.5-2.5 weeks)
- Introduce Reports tab + Master Report list/detail.
- Build report models/service contracts + mock API integration.

## Phase 3 (Higher / 2-3 weeks)
- Sample Output video playback, chaptering, resume progress.
- Consultation booking funnel + analytics instrumentation.

Total: ~5-7 weeks for production-grade rollout with backend dependencies.

---

## 10) Key Product Decisions Needed

1. Should `Gallery` be replaced by `Reports`, or become a segment inside Reports?
2. Is Color Matcher single-shot capture or continuous live sampling?
3. Are report videos generated per project/session or per room?
4. Is consultation booking in-app checkout or external link flow?
5. Should the tab and IA label be `Favorites` or `Saved` (mocks show both)?

---

## 11) Screen Wiring Matrix (Implementation Handoff)

| Screen | Entry | Primary action(s) | Exit / next route | Owner module |
|---|---|---|---|---|
| Color Matcher | `ItemPicker` -> match CTA | Analyze, Add match, Retake | Back (`pop`), or return selected color(s) to `ItemPicker` state | `Features/Visualizer` + `ColorMatchService` |
| Favorites | Tab root (`favorites` / `saved`) | Search, sort, open card, unfavorite | Open detail, jump to Visualize with preselected color, tab switch | `Features/Favorites` + `FavoritesStore` |
| Master Report | Reports list or post-visualization CTA | Play analysis video, open recommendation, favorite, share | `SampleOutput`, recommendation detail, tab switch | `Features/Reports` + `ReportService` |
| Sample Output | Master Report video card | Play sample, scrub, book consultation | Close -> Master Report, CTA -> checkout/booking | `Features/Reports` + `VideoPlayerViewModel` + booking integration |

### Route-level wiring contract
- `Visualize` flow should publish `reportGenerationRequested` when user finalizes visualization.
- `Reports` flow should subscribe to report generation status and show `generating` row until ready.
- `MasterReportView` owns navigation to `SampleOutputView` and `consultationCheckout`.
- `Favorites` should accept source context (`matcher`, `report`, `detail`) for analytics attribution.
