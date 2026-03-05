import { NextRequest, NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/session';
import { listClients, searchClients } from '@/lib/db';

export async function GET(request: NextRequest) {
  if (!(await requireAdmin(request))) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const { searchParams } = new URL(request.url);
  const q = searchParams.get('q');

  const clients = q ? await searchClients(q) : await listClients();
  return NextResponse.json(clients);
}
