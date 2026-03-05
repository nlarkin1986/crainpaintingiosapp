# Custom Surface Text Input

**Date:** 2026-02-15
**Status:** Ready for planning

## What We're Building

Add a "Custom / Other" option as a 7th tile in the Surface Picker grid (Step 3). When tapped, a text input slides open inline below the grid so users can type a custom surface description (e.g., "garage door", "fence", "brick exterior"). The existing 6 tiles remain visible, letting users switch back at any time.

## Why This Approach

The current Surface Picker limits users to 6 predefined surfaces. Real painting projects often involve surfaces not in the list — garage doors, fences, exterior siding, fireplace mantels, etc. Adding a "Custom" tile with inline expansion:

- Follows the existing grid pattern (no new UI paradigm)
- Keeps the common options one-tap accessible
- Lets power users describe exactly what they want
- Wires up the already-existing `customInstruction` parameter in `prompt.ts`

## Key Decisions

| Decision | Choice | Rationale |
|---|---|---|
| How to add the option | 7th tile in the existing grid | Consistent with the current UI pattern; no new components needed |
| Text input behavior | Inline expansion below grid | Tiles stay visible so user can switch back easily |
| Input constraints | Placeholder text only, no char limit | Keep it simple; the prompt builder handles formatting |
| Selection logic | Tapping "Custom" deselects any tile; tapping a tile hides the text input and clears it | Mutual exclusivity — one surface selection at a time |

## Scope

**In scope:**
- Add "Custom / Other" tile with a `Pencil` or `MessageSquare` icon
- Inline text field that slides open when "Custom" is selected
- Placeholder: "e.g., garage door, fence, brick exterior..."
- Wire `customInstruction` through to the prompt builder
- Disable "Next" button until text field has content (when custom is selected)

**Out of scope:**
- Suggestion chips or autocomplete
- Multiple custom surfaces
- Saving custom entries for reuse
