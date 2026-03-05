---
title: "feat: Add Custom Surface Text Input"
type: feat
status: completed
date: 2026-02-15
brainstorm: docs/brainstorms/2026-02-15-custom-surface-input-brainstorm.md
---

# feat: Add Custom Surface Text Input

## Overview

Add a 7th "Custom / Other" tile to the Surface Picker grid. When selected, an inline text input slides open below the grid so users can describe any surface not in the preset list. This wires up the existing `customInstruction` parameter in `prompt.ts` that is currently unused.

## Files to Modify

| File | Change |
|---|---|
| `src/components/visualizer/surface-picker.tsx` | Add custom tile, inline text input, selection logic |
| `src/app/page.tsx` | Add `customInstruction` state, pass to SurfacePicker and API call |
| `src/app/api/visualize/route.ts` | Read optional `customInstruction` from FormData, pass to prompt builder |

No new files needed.

## Acceptance Criteria

- [x] 7th tile labeled "Custom / Other" with `Pencil` icon appears in the grid
- [x] Tapping "Custom" shows an inline text input below the grid with slide animation
- [x] Placeholder reads: `e.g., garage door, fence, brick exterior...`
- [x] Selecting "Custom" deselects any preset tile; selecting a preset tile hides the text input and clears it
- [x] Tapping the "Custom" tile again while selected collapses the input and deselects it (toggle behavior)
- [x] "Next" button is disabled when "Custom" is selected but text input is empty or whitespace-only (`.trim()`)
- [x] Custom text is trimmed and sent as `customInstruction` in the API FormData
- [x] API route passes `customInstruction` to `buildPaintPrompt()` which already uses it via `surfaceText`
- [x] Grid remains `grid-cols-2` — the 7th tile sits alone on the 4th row (left-aligned)
- [x] Custom instruction state persists when "Add Another Color" returns to Step 1 (same as `selectedSurface` does)
- [x] Input uses `style={{ fontSize: "16px" }}` to prevent iOS keyboard zoom
- [x] Input has `aria-label="Custom surface description"` for screen readers

## Implementation Steps

### Step 1: Update `surface-picker.tsx`

**1a. Add `Pencil` icon import and custom tile constant**

```typescript
// Add to imports
import { Pencil } from "lucide-react";

// Add to SURFACES array or render separately after the grid map
const CUSTOM_LABEL = "Custom / Other";
```

**1b. Add props for custom instruction**

Extend `SurfacePickerProps`:

```typescript
interface SurfacePickerProps {
  selectedSurface: string;
  onSelectSurface: (surface: string) => void;
  customInstruction: string;           // NEW
  onCustomInstructionChange: (value: string) => void;  // NEW
  selectedColors: BMColor[];
  photo: File | null;
  onSubmit: () => void;
  onBack: () => void;
}
```

**1c. Add "Custom / Other" tile to the grid**

After the `SURFACES.map(...)` block inside the grid `div`, render one more `<button>` for "Custom / Other" using the same styling pattern. When clicked, call `onSelectSurface("custom")`.

**1d. Add inline text input with slide animation**

Below the grid `Card`, conditionally render a text input when `selectedSurface === "custom"`:

```tsx
{selectedSurface === "custom" && (
  <div className="animate-in slide-in-from-top-2 fade-in duration-200">
    <Input
      value={customInstruction}
      onChange={(e) => onCustomInstructionChange(e.target.value)}
      placeholder="e.g., garage door, fence, brick exterior..."
      className="h-12 text-base"
      style={{ fontSize: "16px" }}  // prevent iOS zoom
      autoFocus
    />
  </div>
)}
```

**1e. Update disabled logic on submit button**

```typescript
disabled={!selectedSurface || (selectedSurface === "custom" && !customInstruction.trim())}
```

**1f. Mutual exclusivity & toggle**

The `onSelectSurface` callback in `page.tsx` will handle clearing `customInstruction` when a preset tile is selected. When "Custom" is tapped, `selectedSurface` becomes `"custom"` which deselects any preset. Tapping "Custom" again while already selected should deselect it (set `selectedSurface` to `""`) and collapse the input — this is handled by the `handleSelectSurface` function toggling between `"custom"` and `""`.

### Step 2: Update `page.tsx`

**2a. Add state**

```typescript
const [customInstruction, setCustomInstruction] = useState("");
```

**2b. Update SurfacePicker props**

Pass `customInstruction` and `onCustomInstructionChange={setCustomInstruction}` to `<SurfacePicker>`.

**2c. Clear custom instruction when preset selected**

Wrap `setSelectedSurface` so that selecting a non-custom surface clears the custom text:

```typescript
const handleSelectSurface = (surface: string) => {
  setSelectedSurface(surface);
  if (surface !== "custom") {
    setCustomInstruction("");
  }
};
```

**2d. Update `generateResults` to send `customInstruction`**

In the `formData.append` block, add:

```typescript
if (customInstruction.trim()) {
  formData.append("customInstruction", customInstruction.trim());
}
```

**2e. Update `handleStartOver`**

Add `setCustomInstruction("")` to the reset function.

### Step 3: Update `route.ts`

**3a. Read optional `customInstruction` from FormData**

```typescript
const customInstruction = formData.get("customInstruction") as string | null;
```

**3b. Pass to `buildPaintPrompt`**

```typescript
const prompt = buildPaintPrompt({
  surface: surface,
  colorName,
  colorNumber,
  colorHex,
  customInstruction: customInstruction || undefined,
});
```

No changes needed to `prompt.ts` itself — `buildPaintPrompt` already uses `customInstruction` when provided via `const surfaceText = params.customInstruction || params.surface`.

## References

- Brainstorm: `docs/brainstorms/2026-02-15-custom-surface-input-brainstorm.md`
- Prompt builder with existing `customInstruction` support: `src/lib/prompt.ts:5-8`
- Surface picker component: `src/components/visualizer/surface-picker.tsx`
- Root page state management: `src/app/page.tsx:12-17`
- API route FormData handling: `src/app/api/visualize/route.ts:18-24`
