---
status: pending
priority: p1
issue_id: "005"
tags: [code-review, bug, ui]
dependencies: []
---

# Save Modal "Save Proposal" Button Stuck Disabled After Success

## Problem Statement

In `SaveProposalModal`, when `handleSubmit` succeeds, `setSaving(false)` is never called. The button remains permanently disabled in "Saving…" state. On a successful save, `onSaved(data.proposalId)` is called which closes the modal — but if the modal stays open for any reason (e.g., animation), or if the parent component re-mounts it, the button is broken.

More importantly: on a 422 response (fuzzy match suggestions), `setSaving(false)` IS called correctly. The missing call is specifically on the success path, making this inconsistent behavior.

## Findings

**src/components/visualizer/save-proposal-modal.tsx — handleSubmit:**
```ts
const res = await fetch('/api/proposals', { ... });

if (res.status === 422) {
  const data = await res.json();
  setSuggestions(data.suggestions || []);
  setSaving(false);   // ✅ correctly reset on 422
  return;
}

if (!res.ok) {
  const data = await res.json();
  setError(data.error || 'Failed to save');
  setSaving(false);   // ✅ correctly reset on error
  return;
}

const data = await res.json();
onSaved(data.proposalId);
// ← setSaving(false) never called on success path
```

## Proposed Solutions

### Fix: Add `setSaving(false)` before `onSaved`

```ts
const data = await res.json();
setSaving(false);
onSaved(data.proposalId);
```

**Effort:** Trivial
**Risk:** None

## Recommended Action

Add the missing `setSaving(false)` call.

## Technical Details

- **Affected file:** `src/components/visualizer/save-proposal-modal.tsx` (after `const data = await res.json()`)

## Acceptance Criteria

- [ ] After a successful save, the "Save Proposal" button is re-enabled before the modal closes
- [ ] The button shows correct state on all paths: loading, 422, error, success

## Work Log

- 2026-02-25: Identified by bug-reviewer agent
