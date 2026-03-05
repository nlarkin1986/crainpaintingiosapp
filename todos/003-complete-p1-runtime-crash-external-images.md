---
status: pending
priority: p1
issue_id: "003"
tags: [code-review, bug, runtime-crash]
dependencies: []
---

# Runtime Crash: No `images.remotePatterns` for External URLs

## Problem Statement

`next.config.ts` has no `images.remotePatterns` configured. Every admin page and the print page use `<Image src={url}>` where `url` is an external Vercel Blob URL. In production, Next.js Image will throw a runtime error for all external `src` values without an explicit allowlist. Every admin proposal view and print page will crash on load.

## Findings

Pages using `<Image>` with external Blob URLs:
- `src/app/admin/proposals/[id]/page.tsx` — `r.original_url`, `r.result_url`
- `src/app/admin/proposals/[id]/print/page.tsx` — `r.original_url`, `r.result_url`

`next.config.ts` (current content — no images config):
```ts
// No remotePatterns defined
```

Vercel Blob URLs follow the pattern: `https://*.public.blob.vercel-storage.com/...`

## Proposed Solutions

### Option A: Add remotePatterns for Vercel Blob (Recommended)

```ts
// next.config.ts
const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '*.public.blob.vercel-storage.com',
      },
    ],
  },
};
```

**Pros:** Minimal, targeted fix
**Effort:** Small (2 min)
**Risk:** Low

### Option B: Use regular `<img>` tags in admin/print pages

Replace Next.js `<Image>` with plain `<img>` tags in admin views where optimization isn't needed.

**Pros:** No config change
**Cons:** Loses optimization, layout shift risk
**Effort:** Small
**Risk:** Low

## Recommended Action

Option A — add `remotePatterns` to `next.config.ts`. One change, fixes all pages.

## Technical Details

- **Affected files:** `next.config.ts`, `src/app/admin/proposals/[id]/page.tsx`, `src/app/admin/proposals/[id]/print/page.tsx`
- **Error type:** Runtime crash in production (Next.js Image throws `Error: Invalid src prop`)

## Acceptance Criteria

- [ ] `next.config.ts` includes `remotePatterns` covering Vercel Blob hostnames
- [ ] Admin proposal detail page loads without Image errors
- [ ] Print page loads without Image errors

## Work Log

- 2026-02-25: Identified by bug-reviewer agent in code review
