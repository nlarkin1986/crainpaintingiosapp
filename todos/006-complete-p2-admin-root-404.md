---
status: pending
priority: p2
issue_id: "006"
tags: [code-review, bug, routing]
dependencies: []
---

# `/admin` Returns 404 — Missing Root Page and Middleware Gap

## Problem Statement

Visiting `/admin` produces a 404. There is no `page.tsx` at `src/app/admin/`. The middleware matcher `/admin/:path*` requires at least one path segment, so `/admin` also bypasses auth entirely. A user who bookmarks `/admin` gets a confusing 404.

## Findings

1. `src/app/admin/` directory has no `page.tsx` — only `login/`, `dashboard/`, `clients/`, `proposals/` subdirectories
2. Middleware matcher `['/admin/:path*']` does NOT match bare `/admin` in Next.js App Router

## Proposed Solutions

### Fix: Add redirect page + update middleware matcher

**Step 1** — Create `src/app/admin/page.tsx`:
```tsx
import { redirect } from 'next/navigation';
export default function AdminRoot() {
  redirect('/admin/dashboard');
}
```

**Step 2** — Update middleware matcher:
```ts
export const config = {
  matcher: ['/admin', '/admin/:path*'],
};
```

**Effort:** Small
**Risk:** None

## Technical Details

- **Affected files:** `src/app/admin/page.tsx` (create), `src/middleware.ts` (matcher)

## Acceptance Criteria

- [ ] Visiting `/admin` redirects to `/admin/dashboard`
- [ ] An unauthenticated request to `/admin` redirects to `/admin/login`

## Work Log

- 2026-02-25: Identified by architecture-strategist agent
