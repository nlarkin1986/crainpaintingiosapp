---
status: pending
priority: p1
issue_id: "002"
tags: [code-review, architecture, dry]
dependencies: []
---

# `sessionOptions` Duplicated in 6 Files Instead of Imported

## Problem Statement

The `sessionOptions` object is copy-pasted identically into `middleware.ts` and every API route file (5 total). `src/lib/session.ts` already exports this object as the single source of truth — but nothing imports it. Any change to cookie name, TTL, or env key requires 6 simultaneous edits and will inevitably drift.

## Findings

Identical 9-line block redeclared in:
- `src/middleware.ts` (lines 6–15)
- `src/app/api/proposals/route.ts` (lines 8–17)
- `src/app/api/proposals/[id]/route.ts` (lines 6–15)
- `src/app/api/admin/auth/route.ts` (lines 7–16)
- `src/app/api/admin/logout/route.ts` (lines 5–14)
- `src/app/api/clients/route.ts` (lines 6–15)

`src/lib/session.ts` exports `sessionOptions` and `SessionData` but is never imported by any of these files.

## Proposed Solutions

### Option A: Import from session.ts everywhere (Recommended)

Remove the inline `sessionOptions` declaration from each file and replace with:
```ts
import { sessionOptions } from '@/lib/session';
```
`iron-session` works in both Edge and Node runtimes, so the import is safe from middleware.

**Pros:** ~45 lines deleted, single source of truth, already have the module
**Cons:** None
**Effort:** Small
**Risk:** Low

### Option B: Also add `requireAdmin()` helper to session.ts

While fixing the duplication, add a shared auth check:
```ts
export async function requireAdmin(request: NextRequest): Promise<boolean> {
  const res = new NextResponse();
  const session = await getIronSession<SessionData>(request, res, sessionOptions);
  return session.isAdmin === true;
}
```

Consolidates the repeated `checkAuth` helper in every route into a single import.

**Pros:** Further reduces duplication, consistent auth pattern
**Effort:** Small (additional)
**Risk:** Low

## Recommended Action

Do both A and B together — same PR, same effort, eliminates all session config duplication.

## Technical Details

- **Affected files:** `src/lib/session.ts`, all 5 API route files, `src/middleware.ts`
- **LOC reduction:** ~45 lines from sessionOptions + ~15 lines from checkAuth helpers

## Acceptance Criteria

- [ ] `session.ts` exports `sessionOptions` and `requireAdmin()`
- [ ] No route file declares a local `sessionOptions` const
- [ ] All routes import and use the shared helpers
- [ ] Build passes with no TypeScript errors

## Work Log

- 2026-02-25: Identified by architecture-strategist and code-simplicity-reviewer agents
