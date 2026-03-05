---
status: pending
priority: p3
issue_id: "012"
tags: [code-review, architecture, ux]
dependencies: []
---

# Dashboard Has No Search — `searchClients` DB Function Is Unused in Admin UI

## Problem Statement

The admin dashboard renders a static server-rendered list of all clients with no filtering. The plan specified a search bar with debounced `GET /api/clients?q=` calls. The `searchClients()` DB function exists and the API endpoint supports `?q=`, but the dashboard has no search input.

## Findings

**src/app/admin/dashboard/page.tsx** — pure server component, renders static list, no search input.

**src/lib/db.ts** — `searchClients(query)` exists and is correctly implemented.

**src/app/api/clients/route.ts** — correctly handles `?q=` and calls `searchClients`.

The `SaveProposalModal` already uses the same search endpoint with debounce. The pattern is proven and reusable.

## Proposed Solution

Add a `<DashboardSearch>` client component to the dashboard:

1. Takes initial `clients` list as prop (from server component render)
2. Filters locally on the pre-loaded list (instant, no network)
3. For large datasets: debounced fetch to `/api/clients?q=` (same pattern as modal)

Since this is a small single-operator tool, local filtering of the server-loaded list is likely sufficient with no extra API calls.

**Effort:** Small
**Risk:** Low

## Technical Details

- **Affected files:** `src/app/admin/dashboard/page.tsx` (add search client component)

## Acceptance Criteria

- [ ] Dashboard has a search/filter input
- [ ] Typing in the input filters the visible client list
- [ ] Empty search shows all clients

## Work Log

- 2026-02-25: Identified by architecture-strategist agent
