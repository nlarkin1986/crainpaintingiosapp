---
status: pending
priority: p2
issue_id: "007"
tags: [code-review, bug, ux]
dependencies: []
---

# `beforeunload` Guard Never Clears After Successful Save

## Problem Statement

After a user saves a proposal via the modal, the `beforeunload` guard on `page.tsx` still fires when they try to navigate away. The guard is keyed on `hasCompleteResults`, which remains `true` after save since `results` is never cleared. Users see a misleading "Leave site? Changes may not be saved" browser prompt even after their data is saved.

## Findings

**src/app/page.tsx:**
```ts
const hasCompleteResults = results.some(r => r.status === 'complete');
useEffect(() => {
  if (!hasCompleteResults) return;
  const handler = (e: BeforeUnloadEvent) => { e.preventDefault(); };
  window.addEventListener('beforeunload', handler);
  return () => window.removeEventListener('beforeunload', handler);
}, [hasCompleteResults]);
```

After a save, `ResultGallery.handleSaved` sets local `savedProposalId` state and shows a success banner — but this state is local to `ResultGallery` and doesn't propagate to `page.tsx`. The `results` array remains populated with complete results, so `hasCompleteResults` stays `true` indefinitely.

**src/components/visualizer/result-gallery.tsx:**
```ts
const [savedProposalId, setSavedProposalId] = useState<string | null>(null);
// savedProposalId never reaches page.tsx
```

## Proposed Solutions

### Option A: Lift `savedProposalId` to `page.tsx` (Recommended)

Add `savedProposalId` state to `page.tsx`, pass `onSaved` callback to `ResultGallery`, update guard:

```ts
// page.tsx
const [savedProposalId, setSavedProposalId] = useState<string | null>(null);
const hasUnsavedResults = results.some(r => r.status === 'complete') && !savedProposalId;
// use hasUnsavedResults in useEffect

// Pass down:
<ResultGallery onSaved={setSavedProposalId} ... />
```

Clear `savedProposalId` on `handleStartOver`.

**Effort:** Small
**Risk:** Low

### Option B: Clear `results` on save (Simpler but loses the gallery view)

On save success, `setResults([])`. This clears the guard but also clears the visual. Not ideal UX.

## Recommended Action

Option A — lift saved state to page.tsx.

## Technical Details

- **Affected files:** `src/app/page.tsx`, `src/components/visualizer/result-gallery.tsx`

## Acceptance Criteria

- [ ] After successful save, navigating away does NOT trigger the beforeunload dialog
- [ ] Before saving, navigating away DOES trigger the beforeunload dialog
- [ ] `handleStartOver` resets both `results` and `savedProposalId`

## Work Log

- 2026-02-25: Identified by architecture-strategist and bug-reviewer agents
