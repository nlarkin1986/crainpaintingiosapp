---
status: pending
priority: p1
issue_id: "004"
tags: [code-review, bug, auth]
dependencies: []
---

# `session.destroy()` Not Awaited — Logout Never Clears Cookie

## Problem Statement

In `api/admin/logout/route.ts`, `session.destroy()` is called without `await`. The session cookie is never actually cleared, so "logout" does nothing — the user's session remains valid until it naturally expires (8 hours). This is a critical auth bug.

## Findings

**src/app/api/admin/logout/route.ts:**
```ts
export async function GET(request: NextRequest) {
  const response = NextResponse.redirect(new URL('/admin/login', request.url));
  const session = await getIronSession<SessionData>(request, response, sessionOptions);
  session.destroy();   // ← missing await — destroy() returns a Promise
  return response;
}
```

`iron-session`'s `session.destroy()` is an async function that clears the cookie by writing a `Set-Cookie` header on the response. Without `await`, the cookie header is never written before `return response`. The redirect happens, but the session cookie is still valid.

## Proposed Solutions

### Fix (one-line change)

```ts
await session.destroy();
```

**Effort:** Trivial
**Risk:** None

## Recommended Action

Add `await`. Done.

## Technical Details

- **Affected file:** `src/app/api/admin/logout/route.ts` (line 19)
- **Impact:** Logout is completely broken — clicking logout redirects to login but the session remains active

## Acceptance Criteria

- [ ] After visiting `/api/admin/logout`, the `admin_session` cookie is cleared
- [ ] Visiting any `/admin/*` page after logout redirects to `/admin/login`

## Work Log

- 2026-02-25: Identified by bug-reviewer agent
