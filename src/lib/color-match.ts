import { getAllColors } from "@/lib/colors";
import type { PaintColor } from "@/types/colors";

export interface RGBColor {
  r: number;
  g: number;
  b: number;
}

export interface LabColor {
  l: number;
  a: number;
  b: number;
}

export interface FocusRect {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface CaptureContext {
  flashUsed?: boolean;
  exposureBias?: number;
  whiteBalanceMode?: string;
  whiteBalanceTemperature?: number;
  whiteBalanceTint?: number;
  whiteBalanceRedGain?: number;
  whiteBalanceGreenGain?: number;
  whiteBalanceBlueGain?: number;
  iso?: number;
  exposureDurationSeconds?: number;
  deviceModel?: string;
  capturedAt?: string;
  latitude?: number;
  longitude?: number;
  source?: string;
}

export type SampleQuality = "good" | "mixed" | "poor";
export type MatchMethod =
  | "ocr_exact"
  | "gemini_shortlist"
  | "deterministic_cv"
  | "learned_awb_deterministic"
  | "learned_awb_vlm_rerank";

export interface SampleDiagnostics {
  coveragePct: number;
  glarePct: number;
  variance: number;
  ocrTextFound: boolean;
  preCorrectionHex?: string;
  postCorrectionHex?: string;
  awbModel?: string;
  deltaETop1?: number;
  deltaEGapTop2?: number;
}

export interface SampleAnalysis {
  sampleHex: string;
  sampleRgb: RGBColor;
  sampleLab: LabColor;
  quality: SampleQuality;
  warnings: string[];
  spread: number;
  diagnostics: SampleDiagnostics;
  keptPixelCount?: number;
  totalPixelCount?: number;
}

export interface RankedCatalogColor {
  color: PaintColor;
  deltaE: number;
  confidence: number;
  rationale: string;
}

export const MATCH_BRANDS = [
  "benjamin_moore",
  "sherwin_williams",
] as const;

export type MatchBrand = (typeof MATCH_BRANDS)[number];

export interface ColorMatchResponseItem {
  brand: MatchBrand;
  number: string;
  name: string;
  family: string;
  hex: string;
  confidence: number;
  rationale: string;
}

interface CatalogColorIndexEntry {
  color: PaintColor & { brand: MatchBrand };
  lab: LabColor;
  normalizedNumber: string;
}

const XYZ_EPSILON = 216 / 24389;
const XYZ_KAPPA = 24389 / 27;
const REF_X = 95.047;
const REF_Y = 100;
const REF_Z = 108.883;

const catalogIndexByBrand: Record<MatchBrand, CatalogColorIndexEntry[]> = {
  benjamin_moore: buildCatalogIndex("benjamin_moore"),
  sherwin_williams: buildCatalogIndex("sherwin_williams"),
};

const catalogLookupByBrand: Record<MatchBrand, Map<string, CatalogColorIndexEntry>> = {
  benjamin_moore: buildCatalogLookup(catalogIndexByBrand.benjamin_moore),
  sherwin_williams: buildCatalogLookup(catalogIndexByBrand.sherwin_williams),
};

function buildCatalogIndex(brand: MatchBrand): CatalogColorIndexEntry[] {
  return getAllColors(brand)
    .map((color): CatalogColorIndexEntry | null => {
      const rgb = rgbFromHex(color.hex);
      if (!rgb) return null;
      return {
        color: {
          ...color,
          brand,
        },
        lab: rgbToLab(rgb),
        normalizedNumber: normalizeCatalogNumber(color.number),
      };
    })
    .filter((entry): entry is CatalogColorIndexEntry => entry !== null);
}

function buildCatalogLookup(entries: CatalogColorIndexEntry[]) {
  return new Map(entries.map((entry) => [entry.normalizedNumber, entry]));
}

export function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

export function defaultSampleDiagnostics(overrides?: Partial<SampleDiagnostics>): SampleDiagnostics {
  return {
    coveragePct: 0,
    glarePct: 0,
    variance: 0,
    ocrTextFound: false,
    preCorrectionHex: undefined,
    postCorrectionHex: undefined,
    awbModel: undefined,
    deltaETop1: undefined,
    deltaEGapTop2: undefined,
    ...overrides,
  };
}

export function normalizeHex(hex: string): string | null {
  const normalized = hex.replace("#", "").trim().toUpperCase();
  return /^[0-9A-F]{6}$/.test(normalized) ? normalized : null;
}

export function normalizeCatalogNumber(value: string): string {
  return value.toUpperCase().replace(/[^A-Z0-9]/g, "");
}

export function rgbFromHex(hex: string): RGBColor | null {
  const normalized = normalizeHex(hex);
  if (!normalized) return null;

  const value = Number.parseInt(normalized, 16);
  return {
    r: (value >> 16) & 0xff,
    g: (value >> 8) & 0xff,
    b: value & 0xff,
  };
}

export function hexFromRgb(rgb: RGBColor): string {
  return [rgb.r, rgb.g, rgb.b]
    .map((channel) => clamp(Math.round(channel), 0, 255).toString(16).padStart(2, "0"))
    .join("")
    .toUpperCase();
}

function srgbToLinear(value: number): number {
  const normalized = value / 255;
  if (normalized <= 0.04045) return normalized / 12.92;
  return ((normalized + 0.055) / 1.055) ** 2.4;
}

function linearToSrgb(value: number): number {
  const normalized = clamp(value, 0, 1);
  if (normalized <= 0.0031308) return normalized * 12.92 * 255;
  return (1.055 * (normalized ** (1 / 2.4)) - 0.055) * 255;
}

function xyzPivot(value: number): number {
  return value > XYZ_EPSILON ? Math.cbrt(value) : ((XYZ_KAPPA * value) + 16) / 116;
}

function inverseXyzPivot(value: number): number {
  const cubed = value ** 3;
  return cubed > XYZ_EPSILON ? cubed : ((116 * value) - 16) / XYZ_KAPPA;
}

export function rgbToLab(rgb: RGBColor): LabColor {
  const r = srgbToLinear(rgb.r);
  const g = srgbToLinear(rgb.g);
  const b = srgbToLinear(rgb.b);

  const x = ((r * 0.4124564) + (g * 0.3575761) + (b * 0.1804375)) * 100;
  const y = ((r * 0.2126729) + (g * 0.7151522) + (b * 0.0721750)) * 100;
  const z = ((r * 0.0193339) + (g * 0.1191920) + (b * 0.9503041)) * 100;

  const fx = xyzPivot(x / REF_X);
  const fy = xyzPivot(y / REF_Y);
  const fz = xyzPivot(z / REF_Z);

  return {
    l: (116 * fy) - 16,
    a: 500 * (fx - fy),
    b: 200 * (fy - fz),
  };
}

export function labToRgb(lab: LabColor): RGBColor {
  const fy = (lab.l + 16) / 116;
  const fx = fy + (lab.a / 500);
  const fz = fy - (lab.b / 200);

  const x = REF_X * inverseXyzPivot(fx);
  const y = REF_Y * inverseXyzPivot(fy);
  const z = REF_Z * inverseXyzPivot(fz);

  const xNorm = x / 100;
  const yNorm = y / 100;
  const zNorm = z / 100;

  const rLinear = (xNorm * 3.2404542) + (yNorm * -1.5371385) + (zNorm * -0.4985314);
  const gLinear = (xNorm * -0.9692660) + (yNorm * 1.8760108) + (zNorm * 0.0415560);
  const bLinear = (xNorm * 0.0556434) + (yNorm * -0.2040259) + (zNorm * 1.0572252);

  return {
    r: clamp(Math.round(linearToSrgb(rLinear)), 0, 255),
    g: clamp(Math.round(linearToSrgb(gLinear)), 0, 255),
    b: clamp(Math.round(linearToSrgb(bLinear)), 0, 255),
  };
}

function degreesToRadians(value: number): number {
  return (value * Math.PI) / 180;
}

function radiansToDegrees(value: number): number {
  return (value * 180) / Math.PI;
}

export function deltaE2000(lhs: LabColor, rhs: LabColor): number {
  const avgLPrime = (lhs.l + rhs.l) / 2;
  const c1 = Math.sqrt((lhs.a ** 2) + (lhs.b ** 2));
  const c2 = Math.sqrt((rhs.a ** 2) + (rhs.b ** 2));
  const avgC = (c1 + c2) / 2;

  const g = 0.5 * (1 - Math.sqrt((avgC ** 7) / ((avgC ** 7) + (25 ** 7))));
  const a1Prime = (1 + g) * lhs.a;
  const a2Prime = (1 + g) * rhs.a;

  const c1Prime = Math.sqrt((a1Prime ** 2) + (lhs.b ** 2));
  const c2Prime = Math.sqrt((a2Prime ** 2) + (rhs.b ** 2));
  const avgCPrime = (c1Prime + c2Prime) / 2;

  const h1Prime = (radiansToDegrees(Math.atan2(lhs.b, a1Prime)) + 360) % 360;
  const h2Prime = (radiansToDegrees(Math.atan2(rhs.b, a2Prime)) + 360) % 360;

  const deltaLPrime = rhs.l - lhs.l;
  const deltaCPrime = c2Prime - c1Prime;

  let deltaHPrime = 0;
  if (c1Prime * c2Prime !== 0) {
    if (Math.abs(h2Prime - h1Prime) <= 180) {
      deltaHPrime = h2Prime - h1Prime;
    } else if (h2Prime <= h1Prime) {
      deltaHPrime = h2Prime - h1Prime + 360;
    } else {
      deltaHPrime = h2Prime - h1Prime - 360;
    }
  }

  const deltaBigHPrime = 2 * Math.sqrt(c1Prime * c2Prime) * Math.sin(degreesToRadians(deltaHPrime / 2));

  let avgHPrime = h1Prime + h2Prime;
  if (c1Prime * c2Prime === 0) {
    avgHPrime = h1Prime + h2Prime;
  } else if (Math.abs(h1Prime - h2Prime) > 180) {
    avgHPrime = (h1Prime + h2Prime + 360) / 2;
  } else {
    avgHPrime = (h1Prime + h2Prime) / 2;
  }

  const t =
    1
    - (0.17 * Math.cos(degreesToRadians(avgHPrime - 30)))
    + (0.24 * Math.cos(degreesToRadians(2 * avgHPrime)))
    + (0.32 * Math.cos(degreesToRadians((3 * avgHPrime) + 6)))
    - (0.20 * Math.cos(degreesToRadians((4 * avgHPrime) - 63)));

  const deltaTheta = 30 * Math.exp(-(((avgHPrime - 275) / 25) ** 2));
  const rC = 2 * Math.sqrt((avgCPrime ** 7) / ((avgCPrime ** 7) + (25 ** 7)));
  const sL = 1 + ((0.015 * ((avgLPrime - 50) ** 2)) / Math.sqrt(20 + ((avgLPrime - 50) ** 2)));
  const sC = 1 + (0.045 * avgCPrime);
  const sH = 1 + (0.015 * avgCPrime * t);
  const rT = -Math.sin(degreesToRadians(2 * deltaTheta)) * rC;

  return Math.sqrt(
    (deltaLPrime / sL) ** 2 +
    (deltaCPrime / sC) ** 2 +
    (deltaBigHPrime / sH) ** 2 +
    (rT * (deltaCPrime / sC) * (deltaBigHPrime / sH))
  );
}

export function confidenceFromDeltaE(deltaE: number): number {
  return clamp(Math.round(99 - (deltaE * 2.6)), 70, 99);
}

export function median(values: number[]): number {
  if (values.length === 0) return 0;
  const sorted = [...values].sort((left, right) => left - right);
  const midpoint = Math.floor(sorted.length / 2);
  if (sorted.length % 2 === 0) {
    return (sorted[midpoint - 1] + sorted[midpoint]) / 2;
  }
  return sorted[midpoint];
}

export function applyGrayWorldBalance(pixels: Uint8Array): Uint8Array {
  if (pixels.length === 0 || pixels.length % 3 !== 0) return pixels;

  let rSum = 0;
  let gSum = 0;
  let bSum = 0;
  let count = 0;

  for (let index = 0; index < pixels.length; index += 3) {
    const r = pixels[index] ?? 0;
    const g = pixels[index + 1] ?? 0;
    const b = pixels[index + 2] ?? 0;
    if ((r + g + b) < 18) continue;
    rSum += r;
    gSum += g;
    bSum += b;
    count += 1;
  }

  if (count === 0) return pixels;

  const rMean = rSum / count;
  const gMean = gSum / count;
  const bMean = bSum / count;
  const target = (rMean + gMean + bMean) / 3;

  const rScale = target / Math.max(rMean, 1);
  const gScale = target / Math.max(gMean, 1);
  const bScale = target / Math.max(bMean, 1);

  const balanced = new Uint8Array(pixels.length);
  for (let index = 0; index < pixels.length; index += 3) {
    balanced[index] = clamp(Math.round((pixels[index] ?? 0) * rScale), 0, 255);
    balanced[index + 1] = clamp(Math.round((pixels[index + 1] ?? 0) * gScale), 0, 255);
    balanced[index + 2] = clamp(Math.round((pixels[index + 2] ?? 0) * bScale), 0, 255);
  }

  return balanced;
}

export function buildSampleAnalysisFromHex(
  sampleHex: string,
  overrides?: Partial<Omit<SampleAnalysis, "sampleHex" | "sampleRgb" | "sampleLab">>
): SampleAnalysis | null {
  const sampleRgb = rgbFromHex(sampleHex);
  if (!sampleRgb) return null;

  return {
    sampleHex: hexFromRgb(sampleRgb),
    sampleRgb,
    sampleLab: rgbToLab(sampleRgb),
    quality: overrides?.quality ?? "good",
    warnings: overrides?.warnings ?? ["Matched from a supplied hex value only; photo analysis was skipped."],
    spread: overrides?.spread ?? 0,
    diagnostics: defaultSampleDiagnostics({
      coveragePct: 100,
      glarePct: 0,
      variance: 0,
      ...overrides?.diagnostics,
    }),
    keptPixelCount: overrides?.keptPixelCount ?? 1,
    totalPixelCount: overrides?.totalPixelCount ?? 1,
  };
}

export function createSampleAnalysisFromPixels(pixels: Uint8Array): SampleAnalysis | null {
  if (pixels.length === 0 || pixels.length % 3 !== 0) return null;

  const filteredLabs: LabColor[] = [];
  const warnings = new Set<string>();
  const lValues: number[] = [];
  const aValues: number[] = [];
  const bValues: number[] = [];

  const totalPixelCount = pixels.length / 3;
  let glareCount = 0;
  let shadowCount = 0;

  for (let index = 0; index < pixels.length; index += 3) {
    const rgb = {
      r: pixels[index] ?? 0,
      g: pixels[index + 1] ?? 0,
      b: pixels[index + 2] ?? 0,
    };

    const rLinear = srgbToLinear(rgb.r);
    const gLinear = srgbToLinear(rgb.g);
    const bLinear = srgbToLinear(rgb.b);
    const luminance = (0.2126 * rLinear) + (0.7152 * gLinear) + (0.0722 * bLinear);

    if (luminance < 0.08) {
      shadowCount += 1;
      continue;
    }
    if (luminance > 0.92) {
      glareCount += 1;
      continue;
    }

    const lab = rgbToLab(rgb);
    filteredLabs.push(lab);
    lValues.push(lab.l);
    aValues.push(lab.a);
    bValues.push(lab.b);
  }

  const coveragePct = totalPixelCount === 0 ? 0 : (filteredLabs.length / totalPixelCount) * 100;
  const glarePct = totalPixelCount === 0 ? 0 : (glareCount / totalPixelCount) * 100;

  if (filteredLabs.length === 0) {
    warnings.add("We could not isolate a clean paint sample. Try flatter lighting and fill the frame with the paint color.");
    return {
      sampleHex: "808080",
      sampleRgb: { r: 128, g: 128, b: 128 },
      sampleLab: rgbToLab({ r: 128, g: 128, b: 128 }),
      quality: "poor",
      warnings: [...warnings],
      spread: 100,
      diagnostics: defaultSampleDiagnostics({
        coveragePct,
        glarePct,
        variance: 100,
      }),
      keptPixelCount: 0,
      totalPixelCount,
    };
  }

  const medianLab = {
    l: median(lValues),
    a: median(aValues),
    b: median(bValues),
  };
  const sampleRgb = labToRgb(medianLab);
  const sampleHex = hexFromRgb(sampleRgb);

  let spreadTotal = 0;
  for (const lab of filteredLabs) {
    spreadTotal += deltaE2000(medianLab, lab);
  }
  const spread = spreadTotal / filteredLabs.length;

  let quality: SampleQuality = "good";
  if (filteredLabs.length < totalPixelCount * 0.15 || spread >= 14 || glarePct >= 22) {
    quality = "poor";
  } else if (filteredLabs.length < totalPixelCount * 0.35 || spread >= 8 || glarePct >= 10) {
    quality = "mixed";
  }

  if (filteredLabs.length < totalPixelCount * 0.35) {
    warnings.add("Strong highlights or shadows reduced the usable paint area.");
  }
  if (shadowCount > totalPixelCount * 0.25) {
    warnings.add("Deep shadow is affecting the sample. Try a brighter, flatter angle.");
  }
  if (glarePct >= 10) {
    warnings.add("Visible glare is affecting the sample. Tilt the phone or move to softer light.");
  }
  if (spread >= 8) {
    warnings.add("This sample includes visible color variation, so the match may be less precise.");
  }
  if (spread >= 14) {
    warnings.add("The sampled area looks mixed or heavily lit. Retake with flatter, even light for a stronger match.");
  }

  return {
    sampleHex,
    sampleRgb,
    sampleLab: medianLab,
    quality,
    warnings: [...warnings],
    spread,
    diagnostics: defaultSampleDiagnostics({
      coveragePct,
      glarePct,
      variance: spread,
    }),
    keptPixelCount: filteredLabs.length,
    totalPixelCount,
  };
}

export function buildShortlists(sampleLab: LabColor, limit = 12): Record<MatchBrand, RankedCatalogColor[]> {
  return {
    benjamin_moore: rankBrand(sampleLab, "benjamin_moore", limit),
    sherwin_williams: rankBrand(sampleLab, "sherwin_williams", limit),
  };
}

function rankBrand(sampleLab: LabColor, brand: MatchBrand, limit: number): RankedCatalogColor[] {
  return catalogIndexByBrand[brand]
    .map((entry) => {
      const deltaE = deltaE2000(sampleLab, entry.lab);
      return {
        color: entry.color,
        deltaE,
        confidence: confidenceFromDeltaE(deltaE),
        rationale: "Closest catalog color by CIEDE2000 distance from the sampled paint area.",
      };
    })
    .sort((left, right) => left.deltaE - right.deltaE)
    .slice(0, limit);
}

export function findOcrNumberMatches(
  sampleLab: LabColor,
  rawCandidates: Iterable<string>,
  maxDeltaE = 12
): Partial<Record<MatchBrand, RankedCatalogColor>> {
  const candidates = [...new Set(Array.from(rawCandidates, normalizeCatalogNumber).filter(Boolean))];
  const matches: Partial<Record<MatchBrand, RankedCatalogColor>> = {};

  for (const brand of MATCH_BRANDS) {
    for (const candidate of candidates) {
      const entry = catalogLookupByBrand[brand].get(candidate);
      if (!entry) continue;

      const deltaE = deltaE2000(sampleLab, entry.lab);
      if (deltaE > maxDeltaE) continue;

      const ranked: RankedCatalogColor = {
        color: entry.color,
        deltaE,
        confidence: Math.max(96, confidenceFromDeltaE(deltaE)),
        rationale: "Detected an exact catalog number in the image and verified it against the sampled color.",
      };

      const current = matches[brand];
      if (!current || ranked.deltaE < current.deltaE) {
        matches[brand] = ranked;
      }
    }
  }

  return matches;
}

export function toResponseItem(match: RankedCatalogColor): ColorMatchResponseItem {
  return {
    brand: (match.color.brand as MatchBrand | undefined) ?? "benjamin_moore",
    number: match.color.number,
    name: match.color.name,
    family: match.color.family,
    hex: match.color.hex,
    confidence: match.confidence,
    rationale: match.rationale,
  };
}

export function mergeWarnings(...warningSets: Array<string[] | undefined>): string[] {
  const merged = new Set<string>();
  for (const warningSet of warningSets) {
    for (const warning of warningSet ?? []) {
      const normalized = warning.trim();
      if (normalized) merged.add(normalized);
    }
  }
  return [...merged];
}
