---
status: pending
priority: p3
issue_id: "011"
tags: [code-review, simplicity, dry]
dependencies: []
---

# Duplicate `results.map()` in SaveProposalModal

## Problem Statement

The `results.map(r => ({ ... }))` transformation is copy-pasted identically in two branches of the payload ternary inside `handleSubmit`. A future field addition to `SaveProposalPayload` must be updated in both places and will silently diverge.

## Findings

**src/components/visualizer/save-proposal-modal.tsx — handleSubmit:**
```ts
const payload = existingClient
  ? {
      ...existingClient fields...,
      results: results.map(r => ({   // ← copy 1
        shareId: r.shareId, originalUrl: r.originalUrl, ...
      })),
    }
  : {
      ...new client fields...,
      results: results.map(r => ({   // ← copy 2 (identical)
        shareId: r.shareId, originalUrl: r.originalUrl, ...
      })),
    };
```

## Proposed Solution

Extract into a variable:
```ts
const mappedResults = results.map(r => ({
  shareId: r.shareId,
  originalUrl: r.originalUrl,
  resultUrl: r.resultUrl,
  colorName: r.color.name,
  colorNumber: r.color.number,
  colorHex: r.color.hex,
  brand: r.color.brand ?? 'benjamin_moore',
  surface,
}));

const payload = existingClient
  ? { ...existingClientFields, results: mappedResults }
  : { ...newClientFields, results: mappedResults };
```

**Effort:** Trivial
**Risk:** None
**LOC reduction:** ~10 lines

## Technical Details

- **Affected file:** `src/components/visualizer/save-proposal-modal.tsx`

## Acceptance Criteria

- [ ] `results.map()` appears exactly once in the file
- [ ] Both payload branches use `mappedResults`

## Work Log

- 2026-02-25: Identified by code-simplicity-reviewer agent
