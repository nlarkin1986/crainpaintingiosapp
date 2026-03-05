import type { BMColor } from "@/types/colors";
import rawBMColors from "@/data/bm-colors.json";
import rawSWColors from "@/data/sw-colors.json";

interface RawBMColor {
  number: string;
  name: string;
  family: string;
  hex: string;
  [key: string]: unknown;
}

export type Brand = 'benjamin_moore' | 'sherwin_williams';

/** Map raw JSON entries to the slim BMColor shape once at module load. */
const bmCatalog: BMColor[] = (rawBMColors as RawBMColor[]).map((c) => ({
  number: c.number,
  name: c.name,
  family: c.family,
  hex: c.hex,
  brand: 'benjamin_moore' as const,
}));

const swCatalog: BMColor[] = (rawSWColors as RawBMColor[]).map((c) => ({
  number: c.number,
  name: c.name,
  family: c.family,
  hex: c.hex,
  brand: 'sherwin_williams' as const,
}));

function getCatalog(brand: Brand = 'benjamin_moore'): BMColor[] {
  return brand === 'sherwin_williams' ? swCatalog : bmCatalog;
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/** Return the full color catalog for the given brand. */
export function getAllColors(brand: Brand = 'benjamin_moore'): BMColor[] {
  return getCatalog(brand);
}

/**
 * Curated list of 24 Benjamin Moore best-sellers.
 */
const POPULAR_BM_NAMES: string[] = [
  "White Dove",
  "Simply White",
  "Chantilly Lace",
  "Swiss Coffee",
  "Revere Pewter",
  "Hale Navy",
  "Kendall Charcoal",
  "Classic Gray",
  "Palladian Blue",
  "Sea Salt",
  "Edgecomb Gray",
  "Balboa Mist",
  "Chelsea Gray",
  "Wrought Iron",
  "Stone Hearth",
  "Newburyport Blue",
  "White Heron",
  "Collingwood",
  "Manchester Tan",
  "Healing Aloe",
  "Gray Owl",
  "Super White",
  "Paper White",
  "Dove Wing",
];

const popularBMColors: BMColor[] = POPULAR_BM_NAMES.reduce<BMColor[]>(
  (acc, name) => {
    const match = bmCatalog.find(
      (c) => c.name.toLowerCase() === name.toLowerCase()
    );
    if (match) acc.push(match);
    return acc;
  },
  []
);

/**
 * Curated list of 24 Sherwin-Williams best-sellers.
 */
const POPULAR_SW_NAMES: string[] = [
  "Agreeable Gray",
  "Accessible Beige",
  "Repose Gray",
  "Alabaster",
  "Sea Salt",
  "Naval",
  "Colonnade Gray",
  "Snowbound",
  "Pure White",
  "White Duck",
  "Mindful Gray",
  "Dovetail",
  "Urbane Bronze",
  "Rainwashed",
  "Pewter Cast",
  "Greek Villa",
  "Peppercorn",
  "Jogging Path",
  "Worldly Gray",
  "Intellectual Gray",
  "Wool Skein",
  "Antique White",
  "Canvas Tan",
  "Kilim Beige",
];

const popularSWColors: BMColor[] = POPULAR_SW_NAMES.reduce<BMColor[]>(
  (acc, name) => {
    const match = swCatalog.find(
      (c) => c.name.toLowerCase() === name.toLowerCase()
    );
    if (match) acc.push(match);
    return acc;
  },
  []
);

/** Return the curated 24 best-selling colors for the given brand. */
export function getPopularColors(brand: Brand = 'benjamin_moore'): BMColor[] {
  return brand === 'sherwin_williams' ? popularSWColors : popularBMColors;
}

/**
 * Client-side search across name, number, and hex.
 * Case-insensitive. Returns up to 50 results.
 */
export function searchColors(query: string, brand: Brand = 'benjamin_moore'): BMColor[] {
  if (!query || !query.trim()) return [];

  const q = query.trim().toLowerCase();
  const results: BMColor[] = [];
  const catalog = getCatalog(brand);

  for (const color of catalog) {
    if (results.length >= 50) break;

    if (
      color.name.toLowerCase().includes(q) ||
      color.number.toLowerCase().includes(q) ||
      color.hex.toLowerCase().includes(q)
    ) {
      results.push(color);
    }
  }

  return results;
}

/**
 * Extract unique color families with their counts,
 * sorted by count descending.
 */
export function getColorFamilies(brand: Brand = 'benjamin_moore'): { family: string; count: number }[] {
  const counts = new Map<string, number>();
  const catalog = getCatalog(brand);

  for (const color of catalog) {
    counts.set(color.family, (counts.get(color.family) ?? 0) + 1);
  }

  return Array.from(counts.entries())
    .map(([family, count]) => ({ family, count }))
    .sort((a, b) => b.count - a.count);
}

/** Filter the catalog by a specific family name (case-insensitive). */
export function filterByFamily(family: string, brand: Brand = 'benjamin_moore'): BMColor[] {
  const f = family.toLowerCase();
  return getCatalog(brand).filter((c) => c.family.toLowerCase() === f);
}
