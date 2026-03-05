---
status: pending
priority: p1
issue_id: "001"
tags: [code-review, architecture, auth]
dependencies: []
---

# Print Page Is Completely Unauthenticated

## Problem Statement

The print page at `/admin/proposals/[id]/print` is accessible to anyone with a proposal UUID — no session check, no token verification. The middleware unconditionally bypasses auth for any path containing `/print`. The spec mentioned a signed URL token, which was never implemented. Client names, addresses, proposal notes, and all before/after images are exposed publicly.

## Findings

**middleware.ts line 21:**
```ts
if (pathname === '/admin/login' || pathname.includes('/print')) {
  return NextResponse.next();  // completely bypasses auth
}
```

**print/page.tsx** — calls `getProposal(id)` directly and renders full client PII with zero authentication. Comment says "print uses token auth" but no token is generated, stored, or validated anywhere.

## Proposed Solutions

### Option A: Remove the `/print` bypass (Recommended — 3 lines changed)
Remove the `pathname.includes('/print')` condition from the middleware. The print page opens via `window.open(...)` from the admin detail page, which has an active session cookie. Same-origin page opens inherit the browser's cookie jar, so `iron-session` will authenticate correctly.

**Pros:** Zero new infrastructure, works immediately
**Cons:** Cannot share PDF link with unauthenticated recipients
**Effort:** Small
**Risk:** Low

### Option B: Short-lived HMAC signed token
Generate a token server-side when clicking "Download PDF", store it in DB or KV with a 15-minute TTL, validate it in the print page server component.

**Pros:** Enables sending links to clients
**Cons:** Requires KV storage or DB token table, more complex
**Effort:** Large
**Risk:** Medium

## Recommended Action

Option A — just remove the bypass. This is an internal admin tool; the open() call inherits the session cookie automatically.

**Specific change:**
```ts
// middleware.ts — change this:
if (pathname === '/admin/login' || pathname.includes('/print')) {

// to this:
if (pathname === '/admin/login') {
```

## Technical Details

- **Affected files:** `src/middleware.ts` (line 21), `src/app/admin/proposals/[id]/print/page.tsx`
- **Data exposed:** Client name, address, proposal title, notes, before/after image URLs

## Acceptance Criteria

- [ ] Visiting `/admin/proposals/[id]/print` without a session cookie redirects to `/admin/login`
- [ ] Visiting the print page from within an authenticated admin session renders the proposal
- [ ] `window.open()` from the proposal detail page opens the print page successfully

## Work Log

- 2026-02-25: Identified by architecture-strategist and bug-reviewer agents in code review
