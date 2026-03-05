---
status: pending
priority: p3
issue_id: "013"
tags: [code-review, performance, simplicity]
dependencies: []
---

# `getProposal` Makes Two Sequential Database Round-Trips

## Problem Statement

`db.ts:getProposal()` runs two sequential SQL queries: one for the proposal+client join, and a second for proposal_results. These could be combined into a single query with `json_agg`, cutting the DB round-trips in half for every proposal detail page load.

## Findings

**src/lib/db.ts:**
```ts
// Query 1
const proposalResult = await sql`SELECT p.*, c.name, c.address, c.created_at
  FROM proposals p JOIN clients c ON c.id = p.client_id WHERE p.id = ${id}`;

// Query 2 (sequential, not parallel)
const resultsResult = await sql`SELECT * FROM proposal_results WHERE proposal_id = ${id}`;
```

These cannot be parallelized with `Promise.all` since the second depends on the first only for the `deleted_at` check. But they could be combined into one query.

## Proposed Solution

```sql
SELECT p.id, p.client_id, p.title, p.notes, p.deleted_at, p.created_at,
       c.name AS client_name, c.address AS client_address, c.created_at AS client_created_at,
       COALESCE(json_agg(pr ORDER BY pr.created_at) FILTER (WHERE pr.id IS NOT NULL), '[]') AS results
FROM proposals p
JOIN clients c ON c.id = p.client_id
LEFT JOIN proposal_results pr ON pr.proposal_id = p.id
WHERE p.id = ${id} AND p.deleted_at IS NULL
GROUP BY p.id, c.id
```

This returns one row with results as a JSON array. Parse `row.results` directly.

**Effort:** Small
**Risk:** Low (requires testing the json_agg output shape)

## Alternative

Run the two queries in parallel using `Promise.all`:
```ts
const [proposalResult, resultsResult] = await Promise.all([
  sql`SELECT ... FROM proposals WHERE id = ${id} AND deleted_at IS NULL`,
  sql`SELECT * FROM proposal_results WHERE proposal_id = ${id}`,
]);
if (proposalResult.rows.length === 0) return null;
```

This is simpler to implement and still cuts wall-clock time in half.

**Recommended for now:** Parallel queries (Option B — simpler, safe)
**Recommended long-term:** Single `json_agg` query (Option A — optimal)

## Technical Details

- **Affected file:** `src/lib/db.ts` — `getProposal()` function

## Acceptance Criteria

- [ ] `getProposal()` makes one DB round-trip (or two in parallel)
- [ ] Return type and shape is unchanged

## Work Log

- 2026-02-25: Identified by code-simplicity-reviewer agent
