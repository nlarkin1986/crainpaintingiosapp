# Second-Board Whole-App UX Audit

Date: March 12, 2026
Method: live iPhone 16 simulator click-through with `xcodebuildmcp`, per-screen screenshots, per-screen accessibility hierarchy captures, and an independent five-lane reviewer board
Evidence packet: `docs/evidence/2026-03-12-second-board/`

## Scope

This pass intentionally reviewed the whole app journey, not only the first-time preview funnel.

Covered live:

- onboarding / welcome
- Preview home
- photo-first entry
- color-first entry
- seeded resume path
- surface selection
- review / generate
- results processing and ready states
- result detail
- saved design card
- share / save overflow
- Library landing
- More landing
- consultation checkout
- consultation success
- latest report card in More

Not cleanly destination-captured live in this pass:

- Color Matcher flow
- actual sample walkthrough destination
- custom surface validation error state

Those remain open from the first board and were not re-verified here.

## Method

The second board reviewed a shared evidence packet created from live simulator states, not only source inspection. Each capture included:

- a screenshot
- a `snapshot-ui` hierarchy file
- the launch profile
- the observed CTA label and actual destination

Independent reviewer lanes:

- mobile UI designer
- UX flow designer
- user journey / service designer
- retention / shareability reviewer
- accessibility / Apple HIG reviewer

## First-Board Findings Brought Forward

The first board had already flagged these issues before the second pass:

- naming drift between `Preview`, `Results`, `Library` / `Saved`, and `Design Card`
- split or contradictory flow order between photo-first and color-first routes
- resume logic that does not reliably go to the first incomplete step
- design-card actions buried too deep relative to the artifact’s importance
- color-matcher handoff clarity concerns
- custom-surface validation / routing concerns

## Second-Board Reviewer Inputs

### Mobile UI Designer

- Primary action clarity is weak on `Choose Direction`, `Add Photo`, and `Current Room`.
- Step framing feels inconsistent across the preview journey.
- The first screenful on `How it works` and `More` sells process more than payoff.
- `Library`, `More`, and `How it works` over-stack chips, tabs, badges, and labels.
- The results-detail screen is visually crowded immediately after the payoff moment.
- Helper text and metadata are too visually quiet to reduce uncertainty.

### UX Flow Designer

- The taught order changes by screen: onboarding teaches photo-first, while `Choose Direction` implies color-first.
- Progress counts are unstable: `Step 2 of 3` becomes `Step 3 of 4`.
- Several primary CTAs name a destination instead of the immediate task.
- `Resume project` is not driven by the first incomplete step.
- The empty results state mixes “waiting” and “nothing yet.”
- Navigation nouns are inconsistent enough to weaken trust in where buttons go.

### User Journey / Service Designer

- Reports are split across `Library` and `More`.
- The consultation handoff does not fully prove room continuity.
- Reopened design cards feel isolated from the broader project case.
- `More` mixes upsell, active work, and help content in one surface.
- The same room is framed differently across Preview, Library, More, and expert surfaces.
- The onboarding promise is not reinforced later as a visible journey model.

### Retention / Shareability Reviewer

- The ready result is not dramatic enough to feel like a share-worthy payoff.
- The design card is conceptually strong but not presented as the hero artifact soon enough.
- Share and save actions are distributed across too many surfaces.
- `Adjust Project` is over-promoted relative to `Open Design Card`.
- Library emphasizes project state more than saved artifacts.
- The export sheet is functional but emotionally flat.

### Accessibility / Apple HIG Reviewer

- `Choose Direction` has conflicting title, step math, and CTA language.
- Saved design-card actions are hidden behind icon-only controls.
- Terms like `direction`, `tight set`, and `Ask Curt only if needed` are less clear than plain task language.
- The consultation purchase summary is dense and partially truncated.
- `Enter the App` is generic for a first-run CTA.
- Curt’s name is surfaced before the user clearly understands his role.

## Live Findings Confirmed In This Pass

### Confirmed By Both Passes

- The app still teaches more than one preview order.
- Step counts and progress headers are inconsistent.
- Resume logic is wrong for at least one seeded draft state.
- Design cards are valuable, but their core actions are hidden.
- Naming drift still exists between tab labels, screen titles, and CTA language.

### Confirmed Only In The Second Pass

- `Resume project` on a seeded photo-only draft lands in empty `Results` instead of the first incomplete step.
- `Results` ready state makes `Adjust Project` the most explicit next action, not `Open Design Card`.
- `Library` is project-led, not design-card-led, while consultation success says status is tracked in `Saved`.
- `More` is simultaneously a consultation upsell surface, a report-status surface, and a help surface.
- The consultation CTA sits below the initial fold on `More`.
- The design-card share sheet is strong once opened, but discovery depends on a toolbar icon.

### First-Board Issues Not Re-Verified Live Here

- Color Matcher handoff messaging
- Custom surface validation mismatch

Those remain open and should carry forward into implementation planning.

## Screen-By-Screen Button Audit

| Screen | Current Label / Control | Actual Action | Expectation Match | Keep / Change / Remove |
| --- | --- | --- | --- | --- |
| Welcome | `Enter the App` | enters the preview app shell | Partial match. Action works, label is generic. | Change to task-specific wording such as `Start My Free Previews`. |
| Welcome | `How it works` | opens explainer sheet | Match, but low visual prominence. | Keep, but raise contrast and visibility. |
| How it works | `Get My Free Previews` | exits sheet into Preview | Match. Clear and specific. | Keep. |
| Preview home | `Start with my room` | goes to `Add Photo` | Strong match. | Keep as the main first-run CTA. |
| Preview home | `Browse colors by brand` | goes to color-first route | Partial match. Useful, but should read as an alternate path. | Keep as a secondary / expert path. |
| Preview home | `Resume project` | on seeded photo-only draft, lands in empty `Results` | Mismatch. | Change. Make it route to the first incomplete step and name that step. |
| Choose Direction | swatch `+` affordance | selects colors | Weak match. Tiny plus icon hides the real interaction. | Change to full-card tap selection. |
| Choose Direction | `Add room photo` / `Choose surface` footer | moves to next step based on draft state | Partial match, but current wording changes the task model. | Change to one consistent `Continue to …` model tied to stable step names. |
| Add Photo | `Camera` | opens take-photo flow | Match. | Keep. |
| Add Photo | `Library` | opens photo picker | Match. | Keep. |
| Add Photo | `Continue to Surfaces` | moves forward once a photo exists | Partial match. Disabled state is not explained enough. | Keep, but add explicit disabled-state guidance. |
| Choose Surface | surface tiles | selects paint target | Match. | Keep. |
| Choose Surface | `Custom / Other` | enters custom surface path | Partial match. Route exists, but error / validation flow was not re-verified. | Keep, but carry first-board validation concerns forward. |
| Choose Surface | `Review Project` | goes to project review | Match. | Keep. |
| Review Project | `Edit Colors` / `Change Photo` | opens edit routes | Match. | Keep, but standardize verbs across steps. |
| Review Project | `Generate My Previews` | begins render processing | Match. | Keep. |
| Results empty | `Start a Preview` | restart-style action from an in-flight or resumed state | Mismatch when a draft already exists. | Change. Use state-specific `Back to Project` or progress messaging. |
| Results ready | preview card / `Open Preview` | opens the finished comparison view | Match, but under-promoted. | Keep and make it the dominant next action. |
| Results ready | `Adjust Project` | sends user back into editing | Partial match. Useful, but over-prominent. | Keep as secondary. |
| Result detail | `Open Design Card` | opens saved design-card detail | Match and strategically strong. | Keep as the dominant artifact action. |
| Result detail | `Try Another Color` | re-enters color-change path | Match. | Keep, possibly rename to `Change Color`. |
| Saved design card | toolbar share icon | opens explicit share/save sheet | Weak match for first-time users because action is icon-only. | Change. Add visible labeled action. |
| Saved design card | overflow `…` | reveals `Open Before/After Preview`, `Save to Photos`, `Reopen Preview` | Weak match. High-value actions are hidden. | Change. Expose the top 2-3 actions on-screen. |
| Share sheet | `Share Design Card` | share export | Match. | Keep. |
| Share sheet | `Copy Share Link` | copies hosted share link | Match, but secondary. | Keep. |
| Share sheet | `Save to Photos` | saves branded design card | Match. | Keep and consider promoting earlier. |
| Library | project card / `Open Results` or project-action affordance | reopens the room case | Match, but does not foreground the saved artifact strongly enough. | Keep, but add visible latest design-card affordance. |
| More | `Add Curt's Consultation for $149.00` | enters expert checkout | Match once visible, but sits below fold. | Keep and move higher. |
| More | `Preview Sample Walkthrough` | intended to open sample walkthrough | Entry point confirmed. Destination did not cleanly open under this automation pass. | Keep and re-verify in implementation. |
| Consultation success | `Done` | returns to More | Match. | Keep. |
| More latest report | `Check progress` | opens current report status | Match. | Keep, but unify it with Library / project reporting language. |

## Board Synthesis

### Canonical First-Time Flow

Board decision:

1. `Welcome`
2. `Add Photo`
3. `Choose Surface`
4. `Choose Colors`
5. `Review Project`
6. `Results`
7. `Design Card`

Why:

- it matches the clearest first-run CTA already present in the app
- it matches the onboarding teaching more closely than the current color-first route
- it anchors every later step to the user’s real room first

Color-first should remain available, but only as a visible secondary route for users who already know they want to start by palette or brand.

### Canonical Resume Flow

Board decision:

- Resume must always route to the first incomplete step.
- The resume module must say exactly what is done and what is next.
- Example:
  - `Photo ready`
  - `No colors selected`
  - CTA: `Choose Colors`

`Resume project` is too generic unless the destination really is the next unfinished step.

### Naming And IA Recommendations

Board decision:

- Use one noun system everywhere:
  - `Preview` = the top-level start / create tab
  - `Project` = the working room case
  - `Results` = rendered outputs for the current project
  - `Design Card` = the saved, shareable artifact
  - `Saved` = recommended top-level name instead of `Library`
- Inside `Saved`, keep the project as the canonical container.
- Recommended sections inside `Saved`:
  - `Projects`
  - `Colors`
  - `Reports`

The board did not recommend leading with a standalone `Design Cards` tab by default because the second pass showed stronger continuity when the room project remains the main case container. Instead, the design card should become the hero artifact inside each project.

### Design-Card Strategy

Board decision:

- The design card should be the key preview output artifact.
- After the first successful render, the result detail should immediately emphasize:
  - `Open Design Card`
  - `Change Color`
  - `Share Design Card`
  - `Save to Photos`
- The saved design-card detail should show those actions as explicit labeled controls, not only toolbar icons or overflow actions.
- The export sheet is directionally correct and should be preserved once opened.

### Route And Layout Fixes

Board decision:

- Keep one fixed progress model across the preview journey.
- Replace tiny `+` affordances on color cards with full-card selection.
- Reduce chip and badge density on `Library` / `Saved`, `More`, and `How it works`.
- Move the consultation CTA above the fold or shrink the consultation card so the CTA is visible without scrolling.
- Make the first screenful on onboarding and More show payoff first, not only process.

## Top 10 Highest-Impact Updates

1. Lock the preview journey to one canonical order and one fixed total step count.
2. Make resume state-driven and route to the first incomplete step, not to empty `Results`.
3. Rename the working nouns consistently across tabs, screens, success states, and CTAs.
4. Make primary CTAs describe the immediate task, not the eventual destination.
5. Promote the ready result into an artifact moment by elevating `Open Design Card` over `Adjust Project`.
6. Expose `Share Design Card`, `Save to Photos`, and `Reopen Preview` as visible labeled actions on the design-card screen.
7. Keep the room project as the canonical container across Preview, Saved, consultation, and reports.
8. Stop splitting report status between `Saved` / `Library`, `More`, and success-copy language.
9. Simplify the first screenful on high-stakes screens by reducing chips, helper labels, and badge clutter.
10. Replace insider phrasing like `direction`, `tight set`, and `Ask Curt only if needed` with plain task language.

## Final Board Decision

This second board does not recommend incremental label tweaks on top of the current flow. The evidence shows a deeper contract problem:

- the app teaches one order
- routes another way
- names the same object three different ways
- and hides the most valuable artifact actions until too late

The highest-impact fix is to treat the preview journey as one stable case:

- room first
- surface second
- colors third
- result fourth
- design card as the payoff artifact
- saved project as the long-term container
- consultation as an optional next stage attached to that same project

That direction preserves what is already strong:

- calm premium visual tone
- generous card layout
- a genuinely strong design-card concept
- a credible before/after comparison

It also resolves the clearest failures confirmed live in this pass:

- wrong resume destination
- unstable step math
- naming drift
- action discoverability problems
- fragmented project / report continuity

## Implementation Hand-Off Notes

- Use this document together with `docs/2026-03-12-second-board-screenshot-manifest.md`.
- Carry forward first-board open items that were not re-verified live:
  - Color Matcher handoff
  - custom surface validation
- Re-run the second-board evidence packet after any routing or naming overhaul so the board can validate the revised flow against the same checkpoints.
