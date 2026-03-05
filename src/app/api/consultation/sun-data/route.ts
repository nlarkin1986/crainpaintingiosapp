import { NextRequest, NextResponse } from 'next/server';
import { calculateSunAnalysis, getLightingDescription } from '@/lib/sun-analysis';

export const maxDuration = 5;

export async function POST(request: NextRequest) {
  try {
    const { latitude, longitude, windowDirection } = await request.json();

    if (typeof latitude !== 'number' || typeof longitude !== 'number') {
      return NextResponse.json(
        { error: 'Valid latitude and longitude are required' },
        { status: 400 }
      );
    }

    const sunData = calculateSunAnalysis(latitude, longitude);
    const lightingDescription = getLightingDescription(windowDirection || 'unknown');

    return NextResponse.json({
      ...sunData,
      lightingDescription,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Sun analysis failed';
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
