import { NextRequest, NextResponse } from 'next/server';
import { getIronSession } from 'iron-session';
import { sessionOptions, type SessionData } from '@/lib/session';

export async function GET(request: NextRequest) {
  const response = NextResponse.redirect(new URL('/admin/login', request.url));
  const session = await getIronSession<SessionData>(request, response, sessionOptions);
  await session.destroy();
  return response;
}
