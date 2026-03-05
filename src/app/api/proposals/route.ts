import { NextRequest, NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/session';
import { saveProposal, listProposals, fuzzyMatchClients } from '@/lib/db';
import type { SaveProposalPayload } from '@/types/proposals';
import { rateLimit } from '@/lib/rate-limit';

export async function GET(request: NextRequest) {
  if (!(await requireAdmin(request))) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const { searchParams } = new URL(request.url);
  const clientId = searchParams.get('clientId') ?? undefined;

  const proposals = await listProposals(clientId);
  return NextResponse.json(proposals);
}

export async function POST(request: NextRequest) {
  const ip = request.headers.get('x-forwarded-for') ?? 'unknown';
  const { success } = rateLimit(`proposals:${ip}`);
  if (!success) {
    return NextResponse.json({ error: 'Rate limit exceeded' }, { status: 429 });
  }

  if (!(await requireAdmin(request))) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const body: SaveProposalPayload = await request.json();

  // Validate
  if (!body.existingClientId) {
    if (!body.clientName?.trim() || body.clientName.length > 255) {
      return NextResponse.json({ error: 'Invalid client name' }, { status: 400 });
    }
    if (!body.clientAddress?.trim() || body.clientAddress.length > 512) {
      return NextResponse.json({ error: 'Invalid client address' }, { status: 400 });
    }
  }
  if (!body.results?.length) {
    return NextResponse.json({ error: 'No results to save' }, { status: 400 });
  }
  for (const r of body.results) {
    if (r.colorHex?.length !== 6) {
      return NextResponse.json({ error: 'Invalid color hex' }, { status: 400 });
    }
  }

  // Fuzzy match check (only for new clients, skip if force is set)
  if (!body.existingClientId && !body.forceCreate) {
    const suggestions = await fuzzyMatchClients(body.clientName, body.clientAddress);
    if (suggestions.length > 0) {
      return NextResponse.json({ suggestions }, { status: 422 });
    }
  }

  const result = await saveProposal(body);
  return NextResponse.json({ proposalId: result.proposalId });
}
