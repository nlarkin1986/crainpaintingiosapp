---
status: pending
priority: p2
issue_id: "008"
tags: [code-review, bug, error-handling]
dependencies: []
---

# Admin Pages Crash or Hang on API Error Responses

## Problem Statement

Two admin client pages have broken error handling:
1. `proposals/[id]/page.tsx` — stores the API error response object directly as the proposal, then crashes when accessing `.client.id`
2. `clients/[id]/page.tsx` — passes the API error response to `.find()`, which may throw "not a function" if the error JSON is not an array; also has no `.catch()` so network failures leave the page loading forever

## Findings

**src/app/admin/proposals/[id]/page.tsx (lines 18–22):**
```ts
useEffect(() => {
  fetch(`/api/proposals/${id}`)
    .then(r => r.json())              // if 401/404, r.json() = { error: 'Not found' }
    .then(data => { setProposal(data); setLoading(false); });
    // no .catch() — network error = eternal loading spinner
    // no ok check — { error: 'Not found' } stored as proposal
    // then router.push(`/admin/clients/${proposal.client.id}`) crashes: .client is undefined
}, [id]);
```

**src/app/admin/clients/[id]/page.tsx (lines 19–27):**
```ts
const clients = await clientsRes.json();   // could be { error: '...' } on 401
const found = clients.find((c: Client) => c.id === id);  // .find is not a function if object
```

## Proposed Solutions

### Fix both pages with proper error handling

For `proposals/[id]/page.tsx`:
```ts
const [error, setError] = useState(false);

fetch(`/api/proposals/${id}`)
  .then(r => { if (!r.ok) throw new Error(r.statusText); return r.json(); })
  .then(data => { setProposal(data); setLoading(false); })
  .catch(() => { setError(true); setLoading(false); });

// Render:
if (error) return <ErrorMessage />;
```

For `clients/[id]/page.tsx` — same pattern on both fetches.

**Effort:** Small
**Risk:** Low

## Alternative: Convert to Server Components

Convert both pages to server components (they have no user interactivity that requires client-side rendering). Server components get automatic error boundaries via Next.js `error.tsx` and `notFound()`. This is cleaner and also resolves the over-fetch issue (#009).

**Effort:** Medium
**Risk:** Low

## Recommended Action

Fix error handling now (small fix). Consider converting to server components as a follow-up.

## Technical Details

- **Affected files:** `src/app/admin/proposals/[id]/page.tsx`, `src/app/admin/clients/[id]/page.tsx`

## Acceptance Criteria

- [ ] Both pages show an error message instead of crashing when the API returns an error
- [ ] Both pages show an error message instead of hanging when a network error occurs
- [ ] Loading state resolves in all paths (success, error, network failure)

## Work Log

- 2026-02-25: Identified by bug-reviewer and architecture-strategist agents
