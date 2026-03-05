---
status: pending
priority: p3
issue_id: "010"
tags: [code-review, simplicity, dry]
dependencies: ["002"]
---

# Simplify: Admin Detail Pages Should Be Server Components

## Problem Statement

`admin/clients/[id]/page.tsx` and `admin/proposals/[id]/page.tsx` are client components (`'use client'`) that use `useEffect` + `useState` + `fetch` to load data. These are admin-only pages behind middleware with no user interactivity at load time. Converting them to server components eliminates loading spinners, API round-trips, hydration overhead, and error handling complexity.

## Findings

**proposals/[id]/page.tsx** — 71 lines, client component:
- `useEffect` fetches `/api/proposals/${id}`
- `useState` for proposal, loading
- Manual loading/null checks

As a server component this is ~30 lines: call `getProposal(id)` directly, use `notFound()` for 404, render directly.

The only interactive element is the "Download PDF" button (`window.open(...)`), which can be a tiny client component.

## Proposed Solutions

### Convert to hybrid: server component + small client action buttons

```tsx
// proposals/[id]/page.tsx — server component
import { getProposal } from '@/lib/db';
import { notFound } from 'next/navigation';
import { PrintButton } from './print-button';  // already exists!

export default async function ProposalDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const proposal = await getProposal(id);
  if (!proposal) notFound();
  // render directly
}
```

`print-button.tsx` already exists as a client component — just repurpose it.

For `clients/[id]/page.tsx` — same approach. Extract `<DeleteProposalButton>` as a tiny client component.

**Effort:** Medium
**Risk:** Low

## Technical Details

- **Affected files:** `src/app/admin/proposals/[id]/page.tsx`, `src/app/admin/clients/[id]/page.tsx`
- **LOC reduction:** ~40 lines total

## Acceptance Criteria

- [ ] Both pages render as server components with no `useEffect`
- [ ] Interactive buttons (print, delete) work correctly via client sub-components
- [ ] Pages use `notFound()` for missing data instead of null checks

## Work Log

- 2026-02-25: Identified by code-simplicity-reviewer and architecture-strategist agents
