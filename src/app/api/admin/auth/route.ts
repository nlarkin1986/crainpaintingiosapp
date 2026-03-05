import { NextRequest, NextResponse } from 'next/server';
import { getIronSession } from 'iron-session';
import { timingSafeEqual } from 'crypto';
import { sessionOptions, type SessionData } from '@/lib/session';
import { rateLimit } from '@/lib/rate-limit';

export async function POST(request: NextRequest) {
  const ip = request.headers.get('x-forwarded-for') ?? 'unknown';
  const { success } = rateLimit(`auth:${ip}`);
  if (!success) {
    return NextResponse.json({ error: 'Too many attempts' }, { status: 429 });
  }

  const { password } = await request.json();
  const adminPassword = process.env.ADMIN_PASSWORD;

  if (!adminPassword || !password) {
    return NextResponse.json({ error: 'Invalid password' }, { status: 401 });
  }

  let matches = false;
  try {
    const a = Buffer.from(password.padEnd(64).slice(0, 64));
    const b = Buffer.from(adminPassword.padEnd(64).slice(0, 64));
    matches = timingSafeEqual(a, b) && password === adminPassword;
  } catch {
    matches = false;
  }

  if (!matches) {
    return NextResponse.json({ error: 'Invalid password' }, { status: 401 });
  }

  const response = NextResponse.json({ ok: true });
  const session = await getIronSession<SessionData>(request, response, sessionOptions);
  session.isAdmin = true;
  await session.save();

  return response;
}
