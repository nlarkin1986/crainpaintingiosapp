import { sql } from '@/lib/postgres';
import type { Client, Proposal, ProposalResult, SaveProposalPayload } from '@/types/proposals';

export async function saveProposal(payload: SaveProposalPayload): Promise<{ proposalId: string; clientId: string }> {
  let clientId: string;

  if (payload.existingClientId) {
    clientId = payload.existingClientId;
  } else {
    const result = await sql<{ id: string }>`
      INSERT INTO clients (name, address)
      VALUES (${payload.clientName}, ${payload.clientAddress})
      RETURNING id
    `;
    clientId = result.rows[0].id;
  }

  const proposalResult = await sql<{ id: string }>`
    INSERT INTO proposals (client_id, title, notes)
    VALUES (${clientId}, ${payload.proposalTitle ?? null}, ${payload.notes ?? null})
    RETURNING id
  `;
  const proposalId = proposalResult.rows[0].id;

  for (const r of payload.results) {
    await sql`
      INSERT INTO proposal_results
        (proposal_id, share_id, original_url, result_url, color_name, color_number, color_hex, brand, surface)
      VALUES
        (${proposalId}, ${r.shareId}, ${r.originalUrl}, ${r.resultUrl}, ${r.colorName}, ${r.colorNumber}, ${r.colorHex}, ${r.brand}, ${r.surface})
    `;
  }

  return { proposalId, clientId };
}

export async function searchClients(query: string): Promise<Client[]> {
  const result = await sql<Client>`
    SELECT id, name, address, created_at
    FROM clients
    WHERE name ILIKE ${'%' + query + '%'}
    ORDER BY created_at DESC
    LIMIT 10
  `;
  return result.rows;
}

export async function listClients(): Promise<(Client & { proposal_count: number })[]> {
  const result = await sql<Client & { proposal_count: number }>`
    SELECT c.id, c.name, c.address, c.created_at,
           COUNT(p.id) FILTER (WHERE p.deleted_at IS NULL)::int AS proposal_count
    FROM clients c
    LEFT JOIN proposals p ON p.client_id = c.id
    GROUP BY c.id
    ORDER BY MAX(p.created_at) DESC NULLS LAST, c.created_at DESC
  `;
  return result.rows;
}

export async function getProposal(id: string): Promise<(Proposal & { client: Client; results: ProposalResult[] }) | null> {
  const [proposalResult, resultsResult] = await Promise.all([
    sql<Proposal & { client_name: string; client_address: string; client_created_at: string }>`
      SELECT p.id, p.client_id, p.title, p.notes, p.deleted_at, p.created_at,
             c.name AS client_name, c.address AS client_address, c.created_at AS client_created_at
      FROM proposals p
      JOIN clients c ON c.id = p.client_id
      WHERE p.id = ${id} AND p.deleted_at IS NULL
    `,
    sql<ProposalResult>`
      SELECT * FROM proposal_results WHERE proposal_id = ${id} ORDER BY created_at ASC
    `,
  ]);

  if (proposalResult.rows.length === 0) return null;

  const row = proposalResult.rows[0];

  return {
    id: row.id,
    client_id: row.client_id,
    title: row.title,
    notes: row.notes,
    deleted_at: row.deleted_at,
    created_at: row.created_at,
    client: {
      id: row.client_id,
      name: row.client_name,
      address: row.client_address,
      created_at: row.client_created_at,
    },
    results: resultsResult.rows,
  };
}

export async function listProposals(clientId?: string): Promise<Proposal[]> {
  if (clientId) {
    const result = await sql<Proposal>`
      SELECT id, client_id, title, notes, deleted_at, created_at
      FROM proposals
      WHERE client_id = ${clientId} AND deleted_at IS NULL
      ORDER BY created_at DESC
    `;
    return result.rows;
  }
  const result = await sql<Proposal>`
    SELECT id, client_id, title, notes, deleted_at, created_at
    FROM proposals
    WHERE deleted_at IS NULL
    ORDER BY created_at DESC
  `;
  return result.rows;
}

export async function softDeleteProposal(id: string): Promise<void> {
  await sql`UPDATE proposals SET deleted_at = now() WHERE id = ${id}`;
}

export async function getClient(id: string): Promise<Client | null> {
  const result = await sql<Client>`
    SELECT id, name, address, created_at FROM clients WHERE id = ${id}
  `;
  return result.rows[0] ?? null;
}

export async function fuzzyMatchClients(name: string, address: string): Promise<Client[]> {
  const result = await sql<Client>`
    SELECT id, name, address, created_at
    FROM clients
    WHERE name ILIKE ${'%' + name.split(' ')[0] + '%'}
      OR address ILIKE ${'%' + address.split(' ').slice(0, 2).join(' ') + '%'}
    LIMIT 5
  `;
  return result.rows;
}
