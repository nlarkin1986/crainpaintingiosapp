import { NextRequest, NextResponse } from 'next/server';
import { geocodeAddress } from '@/lib/geocoding';

export const maxDuration = 10;

export async function POST(request: NextRequest) {
  try {
    const { address } = await request.json();

    if (!address || typeof address !== 'string' || address.trim().length < 5) {
      return NextResponse.json(
        { error: 'Please enter a valid address' },
        { status: 400 }
      );
    }

    const result = await geocodeAddress(address.trim());
    return NextResponse.json(result);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Geocoding failed';
    return NextResponse.json({ error: message }, { status: 400 });
  }
}
