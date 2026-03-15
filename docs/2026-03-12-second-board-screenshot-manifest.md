# Second-Board Screenshot Manifest

Date: March 12, 2026
Tooling: `xcodebuildmcp` on the booted iPhone 16 simulator
Evidence root: `docs/evidence/2026-03-12-second-board/`

## Launch Profiles

- `clean first-run`
  - `UITEST_RESET_STATE`
  - `UITEST_DISABLE_ANIMATIONS`
- `clean skip-onboarding`
  - `UITEST_RESET_STATE`
  - `UITEST_SKIP_ONBOARDING`
  - `UITEST_DISABLE_ANIMATIONS`
- `seeded resume / local preview`
  - `UITEST_RESET_STATE`
  - `UITEST_SKIP_ONBOARDING`
  - `UITEST_SEED_PHOTO`
  - `UITEST_ALLOW_LOCAL_PREVIEW`
  - `UITEST_DISABLE_ANIMATIONS`
  - env overrides as needed:
    - `UITEST_LOCAL_PREVIEW_DELAY_MS`
    - `CRAIN_API_BASE_URL=http://127.0.0.1:1`
- `consultation mock success`
  - `UITEST_RESET_STATE`
  - `UITEST_SKIP_ONBOARDING`
  - `UITEST_SEED_PHOTO`
  - `UITEST_DISABLE_ANIMATIONS`
  - `UITEST_MOCK_CONSULTATION_CHECKOUT_SUCCESS`

## Core Reviewed Screens

| Capture ID | Journey / State | Launch Profile | Screenshot | Hierarchy | Primary CTA | Secondary / Other Visible Actions | Observed Destination / Note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `welcome_clean` | Onboarding welcome | `clean first-run` | `docs/evidence/2026-03-12-second-board/screenshots/welcome_clean.jpg` | `docs/evidence/2026-03-12-second-board/snapshots/welcome_clean.json` | `Enter the App` | `How it works` / learn-more link | CTA leads into `Preview` home. Label is generic rather than task-specific. |
| `how_it_works` | Onboarding explainer | `clean first-run` | `docs/evidence/2026-03-12-second-board/screenshots/how_it_works.jpg` | `docs/evidence/2026-03-12-second-board/snapshots/how_it_works.json` | `Get My Free Previews` | `Close` | CTA returns user to the main preview journey. Sheet teaches `upload room -> shortlist colors -> ask Curt only if needed`. |
| `preview_home_clean` | Preview home, empty state | `clean first-run` | `docs/evidence/2026-03-12-second-board/screenshots/preview_home_clean.jpg` | `docs/evidence/2026-03-12-second-board/snapshots/preview_home_clean.json` | `Start with my room` | `Match a real object`, `Browse colors by brand` | Primary CTA went to `Add Photo`. `Browse colors by brand` was verified separately. |
| `photo_upload_primary` | Photo-first path after home CTA | `clean skip-onboarding` | `docs/evidence/2026-03-12-second-board/screenshots/photo_upload_primary.jpg` | `docs/evidence/2026-03-12-second-board/snapshots/photo_upload_primary.json` | `Continue to Surfaces` (disabled) | `Camera`, `Library`, `Open Color Matcher` | Confirms photo-first route. Disabled footer does not explain what enables it beyond the visual state. |
| `direction_picker_alt` | Alternate color-first entry | `clean skip-onboarding` | `docs/evidence/2026-03-12-second-board/screenshots/direction_picker_alt.jpg` | `docs/evidence/2026-03-12-second-board/snapshots/direction_picker_alt.json` | `Add room photo` (disabled) | Swatch cards with `+` affordances | `Browse colors by brand` lands here. Header says `Step 2 of 3`, while the top-right label still says `Photo`. |
| `preview_home_seeded_resume` | Preview home with seeded draft | `seeded resume / local preview` | `docs/evidence/2026-03-12-second-board/screenshots/preview_home_seeded_resume.jpg` | `docs/evidence/2026-03-12-second-board/snapshots/preview_home_seeded_resume.json` | `Resume project` | `Browse colors by brand` | Hero says `Resume your strongest direction`, but status pills show `No directions yet` and `Photo ready`. |
| `results_empty_resume` | Resume misroute target | `seeded resume / local preview` | `docs/evidence/2026-03-12-second-board/screenshots/results_empty_resume.jpg` | `docs/evidence/2026-03-12-second-board/snapshots/results_empty_resume.json` | `Start a Preview` | none visible above fold | Live click-through confirmed the seeded resume CTA lands in empty `Results` rather than the first incomplete step. |
| `direction_picker_selected` | Color-first flow with one color selected | `seeded resume / local preview` | `docs/evidence/2026-03-12-second-board/screenshots/direction_picker_selected.jpg` | `docs/evidence/2026-03-12-second-board/snapshots/direction_picker_selected.json` | `Choose surface` | Selected-color chip removal `x` | Confirms the footer CTA changes with draft state once one color is chosen. |
| `surface_picker` | Surface selection, no surface chosen yet | `seeded resume / local preview` | `docs/evidence/2026-03-12-second-board/screenshots/surface_picker.jpg` | `docs/evidence/2026-03-12-second-board/snapshots/surface_picker.json` | `Review Project` (disabled) | Surface tiles, `Custom / Other` row | Confirms surface step sits after color when a photo already exists. |
| `surface_picker_selected` | Surface selection, `Full Walls` chosen | `seeded resume / local preview` | `docs/evidence/2026-03-12-second-board/screenshots/surface_picker_selected.jpg` | `docs/evidence/2026-03-12-second-board/snapshots/surface_picker_selected.json` | `Review Project` | `Custom / Other` remains available | CTA unlocks once a surface is selected. |
| `project_review` | Pre-generation review | `seeded resume / local preview` | `docs/evidence/2026-03-12-second-board/screenshots/project_review.jpg` | `docs/evidence/2026-03-12-second-board/snapshots/project_review.json` | `Generate My Previews` | `Edit Colors`, `Change Photo` | Review screen clearly shows the pending preview bundle before generation. |
| `results_processing` | Results screen while local preview is processing | `seeded resume / local preview` | `docs/evidence/2026-03-12-second-board/screenshots/results_processing.jpg` | `docs/evidence/2026-03-12-second-board/snapshots/results_processing.json` | none above fold | Back to `Review Project` | Processing state was live-captured before the ready card appeared. |
| `results_ready` | Results screen with first preview ready | `seeded resume / local preview` | `docs/evidence/2026-03-12-second-board/screenshots/results_ready.jpg` | `docs/evidence/2026-03-12-second-board/snapshots/results_ready.json` | preview card acts as primary open action | `Adjust Project` | One ready card is visible. The only explicit footer action is `Adjust Project`. |
| `visualization_detail` | Result detail / comparison view | `seeded resume / local preview` | `docs/evidence/2026-03-12-second-board/screenshots/visualization_detail.jpg` | `docs/evidence/2026-03-12-second-board/snapshots/visualization_detail.json` | `Open Design Card` | `Try Another Color`, compare toggle, `View Larger` | Live click-through confirmed this is the first place where the design-card concept is explicitly introduced. |
| `saved_design_card_detail` | Saved design-card detail | `seeded resume / local preview` | `docs/evidence/2026-03-12-second-board/screenshots/saved_design_card_detail.jpg` | `docs/evidence/2026-03-12-second-board/snapshots/saved_design_card_detail.json` | none as visible text CTA | top-right share icon, top-right overflow icon, `View Larger` on card | Confirms the design card itself looks like a strong artifact, but its key actions are icon-first. |
| `saved_design_card_overflow` | Saved design-card overflow menu | `seeded resume / local preview` | `docs/evidence/2026-03-12-second-board/screenshots/saved_design_card_overflow.jpg` | `docs/evidence/2026-03-12-second-board/snapshots/saved_design_card_overflow.json` | `Open Before/After Preview` | `Save to Photos`, `Reopen Preview`, `Cancel` | Confirms save/reopen actions exist but are hidden behind overflow. |
| `saved_design_card_share_sheet` | Saved design-card export sheet | `seeded resume / local preview` | `docs/evidence/2026-03-12-second-board/screenshots/saved_design_card_share_sheet.jpg` | `docs/evidence/2026-03-12-second-board/snapshots/saved_design_card_share_sheet.json` | `Share Design Card` | `Copy Share Link`, `Save to Photos`, `Done` | Confirms explicit export options only appear after the user discovers the toolbar share icon. |
| `library_design_cards` | Library landing with persisted project/report state | relaunch without reset | `docs/evidence/2026-03-12-second-board/screenshots/library_design_cards.jpg` | `docs/evidence/2026-03-12-second-board/snapshots/library_design_cards.json` | project card open action (`Open Results` / room card) | section picker `Projects`, `Colors`, `Reports` | Library leads with room projects, not design cards. Persisted state also showed `1 Reports`, which diverges from consultation success copy that says `Saved`. |
| `more_home` | More top-of-screen | `consultation mock success` | `docs/evidence/2026-03-12-second-board/screenshots/more_home.jpg` | `docs/evidence/2026-03-12-second-board/snapshots/more_home.json` | none above fold | consultation card preview | The consultation hero is partially above fold; the paid CTA sits just below the initial fold. |
| `more_consultation_cta` | More consultation CTA zone | `consultation mock success` | `docs/evidence/2026-03-12-second-board/screenshots/more_consultation_cta.jpg` | `docs/evidence/2026-03-12-second-board/snapshots/more_consultation_cta.json` | `Add Curt's Consultation for $149.00` | `Preview Sample Walkthrough` | Confirms both expert entry points exist, but the CTA is below the initial fold. |
| `consultation_checkout` | Expert consultation checkout | `consultation mock success` | `docs/evidence/2026-03-12-second-board/screenshots/consultation_checkout.jpg` | `docs/evidence/2026-03-12-second-board/snapshots/consultation_checkout.json` | `Continue to Secure Checkout` | `Apple Pay or Card`, email field | Checkout clearly frames trusted payment and room context, but the offer title block is dense and partly truncated. |
| `consultation_success` | Mocked post-purchase success screen | `consultation mock success` | `docs/evidence/2026-03-12-second-board/screenshots/consultation_success.jpg` | `docs/evidence/2026-03-12-second-board/snapshots/consultation_success.json` | `Done` | none above fold | Success copy says report status is tracked in `Saved`, which conflicts with live `Library` / `More` report surfaces. |
| `more_latest_report` | More with latest report card shown | `consultation mock success` | `docs/evidence/2026-03-12-second-board/screenshots/more_latest_report.jpg` | `docs/evidence/2026-03-12-second-board/snapshots/more_latest_report.json` | `Check progress` on report card | consultation CTA and help rows remain on same screen | Confirms `More` becomes both an upsell surface and a live report-status surface. |

## Supplemental Captures

These files were useful for internal interpretation but were not treated as canonical state proofs in the final synthesis.

| Capture ID | Why It Was Supplemental |
| --- | --- |
| `direction_picker_selected_context` | Intermediate pre-selection state used to confirm `White Dove` coordinates and CTA enablement. |
| `more_home_consultation_section` | Overscrolled past the consultation entry into `Help & learn`; retained as a hierarchy reference only. |
| `reopened_preview_detail` | Captured the full-screen before/after comparison after an ambiguous overflow-dialog tap; useful for artifact context, not for the canonical reopen path. |
| `sample_output` | `xcodebuildmcp` repeatedly reported the tap, but the simulator remained on `More`; not treated as a valid sample-walkthrough destination capture. |
| `seeded_preview_home` | Earlier duplicate of the seeded preview-home state before the final evidence packet was normalized. |

## Coverage Notes

- Live-confirmed end-to-end:
  - welcome -> how-it-works -> preview home
  - preview home -> photo-first path
  - preview home -> color-first path
  - preview home resume misroute -> empty results
  - color selection -> surface -> review -> results -> result detail -> saved design card -> overflow -> share sheet
  - More -> consultation CTA zone -> checkout -> mock success -> latest report card
- Live-confirmed as entry points, but not cleanly destination-captured in this pass:
  - `Match a real object`
  - `Preview Sample Walkthrough`
- The second board used the entry-point evidence for those routes, but did not treat those destinations as confirmed live screens in the synthesis.
