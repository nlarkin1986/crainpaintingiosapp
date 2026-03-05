/**
 * Calculate how a paint color appears at different times of day
 * based on the lighting conditions from sun position and window direction.
 *
 * Uses simplified color temperature adjustment:
 * - Morning (low sun, warm): shifts hex toward warm (add red/yellow)
 * - Afternoon (high sun, neutral): closest to true color
 * - Evening (low sun, very warm): shifts hex toward warm golden
 * - North-facing: always slightly cooler
 * - South-facing: always slightly warmer
 */

interface TimeOfDayShift {
  morningHex: string;
  afternoonHex: string;
  eveningHex: string;
}

function hexToRgb(hex: string): { r: number; g: number; b: number } {
  const clean = hex.replace('#', '');
  return {
    r: parseInt(clean.substring(0, 2), 16),
    g: parseInt(clean.substring(2, 4), 16),
    b: parseInt(clean.substring(4, 6), 16),
  };
}

function rgbToHex(r: number, g: number, b: number): string {
  const clamp = (v: number) => Math.max(0, Math.min(255, Math.round(v)));
  return `${clamp(r).toString(16).padStart(2, '0')}${clamp(g).toString(16).padStart(2, '0')}${clamp(b).toString(16).padStart(2, '0')}`.toUpperCase();
}

/**
 * Apply a color temperature shift to an RGB color.
 * warmth: -1.0 (cool blue) to +1.0 (warm golden)
 * intensity: 0.0 to 1.0 (how strong the shift is)
 */
function applyTemperatureShift(
  rgb: { r: number; g: number; b: number },
  warmth: number,
  intensity: number = 0.08
): { r: number; g: number; b: number } {
  const shift = warmth * intensity * 255;

  return {
    r: rgb.r + shift * 0.6,
    g: rgb.g + shift * 0.3,
    b: rgb.b - shift * 0.4,
  };
}

/**
 * Calculate time-of-day color shifts for a given paint color and window direction.
 */
export function calculateColorShifts(
  hex: string,
  windowDirection: string
): TimeOfDayShift {
  const rgb = hexToRgb(hex);

  // Base shifts by time of day
  const morningWarmth = 0.3;   // Warm morning light
  const afternoonWarmth = 0.0;  // Neutral midday
  const eveningWarmth = 0.5;    // Very warm evening

  // Direction modifier: north is cooler, south is warmer
  const directionModifier: Record<string, number> = {
    N: -0.2,
    NE: -0.1,
    E: 0.1,
    SE: 0.15,
    S: 0.2,
    SW: 0.25,
    W: 0.15,
    NW: -0.05,
    unknown: 0,
  };

  const dirMod = directionModifier[windowDirection] ?? 0;

  const morning = applyTemperatureShift(rgb, morningWarmth + dirMod);
  const afternoon = applyTemperatureShift(rgb, afternoonWarmth + dirMod, 0.04);
  const evening = applyTemperatureShift(rgb, eveningWarmth + dirMod);

  return {
    morningHex: rgbToHex(morning.r, morning.g, morning.b),
    afternoonHex: rgbToHex(afternoon.r, afternoon.g, afternoon.b),
    eveningHex: rgbToHex(evening.r, evening.g, evening.b),
  };
}
