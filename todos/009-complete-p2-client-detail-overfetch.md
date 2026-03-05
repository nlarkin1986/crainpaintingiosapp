---
status: pending
priority: p2
issue_id: "009"
tags: [code-review, performance, architecture]
dependencies: ["008"]
---

# Client Detail Page Fetches All Clients to Find One

## Problem Statement

`src/app/admin/clients/[id]/page.tsx` fetches the entire client list (with a `COUNT(proposals)` GROUP BY join) just to extract one client's name and address. No `GET /api/clients/[id]` endpoint exists. This is a full table scan for a single record lookup.

## Findings

```ts
// src/app/admin/clients/[id]/page.tsx lines 19-24
const [clientsRes, proposalsRes] = await Promise.all([
  fetch(`/api/clients`),           // runs: SELECT + COUNT + GROUP BY on all clients
  fetch(`/api/proposals?clientId=${id}`),
]);
const clients = await clientsRes.json();
const found = clients.find((c: Client) => c.id === id);  // discards everything else
```

## Proposed Solutions

### Option A: Add `GET /api/clients/[id]` endpoint

Add to `src/lib/db.ts`:
```ts
export async function getClient(id: string): Promise<Client | null> {
  const result = await sql<Client>`
    SELECT id, name, address, created_at FROM clients WHERE id = ${id}
  `;
  return result.rows[0] ?? null;
}
```

Add `src/app/api/clients/[id]/route.ts` with session check. Update client page to `fetch(\`/api/clients/${id}\`)`.

**Effort:** Small
**Risk:** Low

### Option B: Convert to Server Component (Best)

The page is behind auth middleware and has only one interactive element (delete button). Convert to a server component that calls `getClient()` and `listProposals()` directly from `db.ts`. Extract the delete button as a small client component.

**Effort:** Medium
**Risk:** Low
**Bonus:** Also fixes bug #008 (error handling) naturally via `notFound()`

## Recommended Action

Option B if refactoring to server components; Option A as a minimal patch.

## Technical Details

- **Affected files:** `src/app/admin/clients/[id]/page.tsx`, `src/lib/db.ts`, `src/app/api/clients/route.ts`

## Acceptance Criteria

- [ ] Client detail page fetches only the single client record, not all clients
- [ ] Page displays the same information as before

## Work Log

- 2026-02-25: Identified by architecture-strategist and code-simplicity-reviewer agents
