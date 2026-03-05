import SunCalc from 'suncalc';

export interface SunPathPoint {
  time: string; // ISO datetime
  altitude: number; // degrees
  azimuth: number; // degrees
  isVisible: boolean;
}

export interface SunAnalysis {
  sunrise: string;
  sunset: string;
  solarNoon: string;
  goldenHour: string;
  goldenHourEnd: string;
  dayLengthHours: number;
  sunPath: SunPathPoint[];
}

/**
 * Calculate sun data for a given location and date.
 * Returns sun times + hourly positions from sunrise to sunset.
 */
export function calculateSunAnalysis(
  latitude: number,
  longitude: number,
  date: Date = new Date()
): SunAnalysis {
  const times = SunCalc.getTimes(date, latitude, longitude);

  const dayLengthMs = times.sunset.getTime() - times.sunrise.getTime();
  const dayLengthHours = Math.round((dayLengthMs / (1000 * 60 * 60)) * 10) / 10;

  // Generate hourly sun positions from sunrise to sunset
  const sunPath: SunPathPoint[] = [];
  const startTime = times.sunrise.getTime();
  const endTime = times.sunset.getTime();

  for (let time = startTime; time <= endTime; time += 30 * 60 * 1000) {
    const d = new Date(time);
    const position = SunCalc.getPosition(d, latitude, longitude);

    sunPath.push({
      time: d.toISOString(),
      altitude: Math.round((position.altitude * 180) / Math.PI * 10) / 10,
      azimuth: Math.round((position.azimuth * 180) / Math.PI * 10) / 10,
      isVisible: position.altitude > 0,
    });
  }

  return {
    sunrise: times.sunrise.toISOString(),
    sunset: times.sunset.toISOString(),
    solarNoon: times.solarNoon.toISOString(),
    goldenHour: times.goldenHour.toISOString(),
    goldenHourEnd: times.goldenHourEnd.toISOString(),
    dayLengthHours,
    sunPath,
  };
}

/**
 * Get a human-readable lighting description based on window direction.
 */
export function getLightingDescription(windowDirection: string): string {
  const descriptions: Record<string, string> = {
    N: 'North-facing rooms receive consistent, cool indirect light throughout the day. Colors tend to appear cooler and slightly muted. Warmer tones can help counterbalance this.',
    NE: 'Northeast-facing rooms get gentle morning light that fades to cool indirect light by afternoon. Colors will shift from warm to cool as the day progresses.',
    E: 'East-facing rooms are bathed in bright, warm morning sunlight and transition to cooler indirect light in the afternoon. Colors look their warmest in the morning.',
    SE: 'Southeast-facing rooms enjoy warm light from morning through midday. Colors will appear warm and vibrant for most of the day, cooling slightly in late afternoon.',
    S: 'South-facing rooms receive the strongest, warmest light throughout most of the day. Colors appear warm and saturated. Cooler tones can help balance intense light.',
    SW: 'Southwest-facing rooms get intense afternoon and evening light with warm golden tones. Colors become increasingly warm and dramatic as the day progresses.',
    W: 'West-facing rooms are bathed in intense, warm afternoon and evening light. Colors shift dramatically from cool morning tones to warm, golden hues by evening.',
    NW: 'Northwest-facing rooms receive late afternoon light with a warm quality. Morning light is cool and indirect, transitioning to warmer tones by late afternoon.',
    unknown: 'Without knowing your window direction, we\'ll analyze the lighting from your photos. The AI will assess visible light quality, window placement, and room brightness.',
  };

  return descriptions[windowDirection] || descriptions.unknown;
}
