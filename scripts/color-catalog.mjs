import { execFileSync } from "node:child_process";
import { readFile, mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import * as XLSX from "xlsx";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const REPO_ROOT = join(__dirname, "..");

export const PATHS = {
  webBm: join(REPO_ROOT, "src/data/bm-colors.json"),
  webSw: join(REPO_ROOT, "src/data/sw-colors.json"),
  iosDir: join(REPO_ROOT, "CrainPaintVisualizer/Sources/Resources/ColorCatalog"),
  iosBm: join(REPO_ROOT, "CrainPaintVisualizer/Sources/Resources/ColorCatalog/bm-colors.json"),
  iosSw: join(REPO_ROOT, "CrainPaintVisualizer/Sources/Resources/ColorCatalog/sw-colors.json"),
  report: join(REPO_ROOT, "src/data/catalog-refresh-report.json"),
  webColorsSource: join(REPO_ROOT, "src/lib/colors.ts"),
};

export const SOURCES = {
  benjaminMoore: {
    catalogUrl: "https://www.benjaminmoore.com/en-us/paint-colors",
    referenceDetailUrl: "https://www.benjaminmoore.com/en-us/paint-colors/color/100/golden-beige",
    searchApiUrl: "https://api.benjaminmoore.io/service/advancedSearch?version=v1.0",
  },
  sherwinWilliams: {
    landingUrl: "https://www.sherwin-williams.com/architects-specifiers-designers/color/color-tools/downloadable-color-palettes",
    designerEditionZipUrl: "https://images.sherwin-williams.com/content_images/sw-xcl-sherwin-williams-ede.zip",
    colorSnapZipUrl: "https://images.sherwin-williams.com/content_images/SW-XCL-SHERWIN-WILLIAMS-COLORC.zip",
  },
};

const SHERWIN_NUMBER_PATTERN = /^SW\s?(\d{4,})$/i;
const BM_NEXT_DATA_PATTERN = /<script id="__NEXT_DATA__" type="application\/json">([\s\S]*?)<\/script>/;
const BENJAMIN_MOORE_API_KEY = "48c3c3e75b424f97904f9659da65b4d0";

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

function normalizeHex(value) {
  const hex = String(value ?? "").trim().replace(/^#/, "").toUpperCase();
  assert(/^[0-9A-F]{6}$/.test(hex), `Invalid hex value: ${value}`);
  return hex;
}

function normalizeName(value) {
  const name = String(value ?? "").trim().replace(/\s+/g, " ");
  assert(name.length > 0, "Color name cannot be blank");
  return name;
}

export function formatSherwinNumber(value) {
  const normalized = String(value ?? "").trim().toUpperCase().replace(/\s+/g, "");
  const match = normalized.match(SHERWIN_NUMBER_PATTERN);
  assert(match, `Invalid Sherwin-Williams number: ${value}`);
  return `SW ${match[1]}`;
}

function naturalColorNumberSort(a, b) {
  return a.number.localeCompare(b.number, undefined, { numeric: true, sensitivity: "base" });
}

function buildFamilyCounts(colors) {
  const counts = new Map();
  for (const color of colors) {
    counts.set(color.family, (counts.get(color.family) ?? 0) + 1);
  }
  return Object.fromEntries(
    Array.from(counts.entries()).sort((left, right) => left[0].localeCompare(right[0]))
  );
}

function extractNextData(html) {
  const match = html.match(BM_NEXT_DATA_PATTERN);
  assert(match, "Unable to locate Benjamin Moore __NEXT_DATA__ payload");
  return JSON.parse(match[1]);
}

function selectBenjaminMoorePaletteComponent(pageProps) {
  const components = pageProps?.componentData?.components ?? [];
  const component = components.find(
    (candidate) =>
      Array.isArray(candidate?.fields?.family_list) &&
      Array.isArray(candidate?.color_data?.data)
  );
  assert(component, "Unable to locate Benjamin Moore color family payload");
  return component;
}

function buildBenjaminMooreFamilyMap(component) {
  const familyByCode = new Map(
    component.fields.family_list.map((family) => [
      family.family_Code,
      family.ribbon_color,
    ])
  );

  const familyMap = new Map();
  let duplicateFamilyAliasesDropped = 0;
  const seen = new Map();

  for (const familyGroup of component.color_data.data) {
    const family = familyByCode.get(familyGroup.code) ?? normalizeName(familyGroup.name);
    for (const color of familyGroup.colors ?? []) {
      const normalizedColor = {
        number: String(color.number ?? "").trim(),
        name: normalizeName(color.name),
        family,
        hex: normalizeHex(color.hex),
      };

      const existing = seen.get(normalizedColor.number);
      if (!existing) {
        seen.set(normalizedColor.number, normalizedColor);
        familyMap.set(normalizedColor.number, normalizedColor.family);
        continue;
      }

      if (
        existing.name === normalizedColor.name &&
        existing.hex === normalizedColor.hex
      ) {
        duplicateFamilyAliasesDropped += 1;
        continue;
      }

      throw new Error(
        `Benjamin Moore has conflicting entries for ${normalizedColor.number}: ${existing.name}/${existing.hex} vs ${normalizedColor.name}/${normalizedColor.hex}`
      );
    }
  }

  return { familyMap, duplicateFamilyAliasesDropped };
}

async function fetchBenjaminMooreSearchPage(pageNo) {
  const payload = {
    locale: "en-us",
    query: "",
    maxResult: 100,
    pageNo,
    filters: {
      page: {
        type: "Color",
        cdp: "true",
      },
    },
    spelling: "strict",
    searchType: "search",
    options: "simple_color",
  };

  const response = await fetch(SOURCES.benjaminMoore.searchApiUrl, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "Ocp-Apim-Subscription-Key": BENJAMIN_MOORE_API_KEY,
    },
    body: JSON.stringify(payload),
  });

  assert(response.ok, `Failed to fetch Benjamin Moore search page ${pageNo}: ${response.status}`);

  const body = await response.json();
  assert(body.status === "OK", `Benjamin Moore search API returned ${body.status}`);
  return body.data;
}

async function fetchAllBenjaminMooreSearchRecords() {
  const firstPage = await fetchBenjaminMooreSearchPage(1);
  const totalPages = firstPage.info?.page?.num_pages ?? 1;
  const records = [...(firstPage.records?.page ?? [])];

  for (let pageNo = 2; pageNo <= totalPages; pageNo += 1) {
    const page = await fetchBenjaminMooreSearchPage(pageNo);
    records.push(...(page.records?.page ?? []));
  }

  return {
    records,
    totalResultCount: firstPage.info?.page?.total_result_count ?? records.length,
    totalPages,
  };
}

function mergeBenjaminMooreRecords(records, familyMap) {
  const colors = [];
  let derivedFamilyFallbackCount = 0;
  const seen = new Map();

  for (const record of records) {
    const color = {
      number: String(record.color_number ?? "").trim(),
      name: normalizeName(record.color_name),
      family: familyMap.get(String(record.color_number ?? "").trim()) ?? deriveFamily(record.color_hex),
      hex: normalizeHex(record.color_hex),
    };

    if (!familyMap.has(color.number)) {
      derivedFamilyFallbackCount += 1;
    }

    const existing = seen.get(color.number);
    if (!existing) {
      seen.set(color.number, color);
      colors.push(color);
      continue;
    }

    if (existing.name === color.name && existing.hex === color.hex && existing.family === color.family) {
      continue;
    }

    throw new Error(
      `Benjamin Moore has conflicting search rows for ${color.number}: ${existing.name}/${existing.hex} vs ${color.name}/${color.hex}`
    );
  }

  return {
    colors: colors.sort(naturalColorNumberSort),
    derivedFamilyFallbackCount,
  };
}

async function fetchText(url) {
  const response = await fetch(url, { redirect: "follow" });
  assert(response.ok, `Failed to fetch ${url}: ${response.status}`);
  return response.text();
}

async function fetchBuffer(url) {
  const response = await fetch(url, { redirect: "follow" });
  assert(response.ok, `Failed to fetch ${url}: ${response.status}`);
  return Buffer.from(await response.arrayBuffer());
}

async function withTemporaryZipBuffer(zipBuffer, work) {
  const tempDir = await mkdtemp(join(tmpdir(), "color-catalog-"));
  const zipPath = join(tempDir, "source.zip");

  try {
    await writeFile(zipPath, zipBuffer);
    return await work(zipPath);
  } finally {
    await rm(tempDir, { recursive: true, force: true });
  }
}

function readWorkbookFromZip(zipPath) {
  const fileList = execFileSync("unzip", ["-Z1", zipPath], {
    encoding: "utf8",
    maxBuffer: 4 * 1024 * 1024,
  })
    .split("\n")
    .map((entry) => entry.trim())
    .filter(Boolean);

  const workbookPath = fileList.find((entry) => entry.toLowerCase().endsWith(".xlsx"));
  assert(workbookPath, `No workbook found in ${zipPath}`);

  const workbookBuffer = execFileSync("unzip", ["-p", zipPath, workbookPath], {
    encoding: null,
    maxBuffer: 16 * 1024 * 1024,
  });

  return XLSX.read(workbookBuffer, { type: "buffer" });
}

function readWorksheetRows(workbook, { sheetName, range = 0 }) {
  const resolvedSheetName = sheetName ?? workbook.SheetNames[0];
  const sheet = workbook.Sheets[resolvedSheetName];
  assert(sheet, `Missing worksheet ${resolvedSheetName}`);

  return XLSX.utils.sheet_to_json(sheet, {
    defval: "",
    raw: false,
    range,
  });
}

function hexToHsl(hex) {
  const normalized = normalizeHex(hex);
  const r = parseInt(normalized.slice(0, 2), 16) / 255;
  const g = parseInt(normalized.slice(2, 4), 16) / 255;
  const b = parseInt(normalized.slice(4, 6), 16) / 255;
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  let h = 0;
  let s = 0;
  const l = (max + min) / 2;

  if (max !== min) {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    switch (max) {
      case r:
        h = ((g - b) / d + (g < b ? 6 : 0)) / 6;
        break;
      case g:
        h = ((b - r) / d + 2) / 6;
        break;
      case b:
        h = ((r - g) / d + 4) / 6;
        break;
      default:
        break;
    }
  }

  return { h: h * 360, s: s * 100, l: l * 100 };
}

export function deriveFamily(hex) {
  const { h, s, l } = hexToHsl(hex);
  if (l > 90) return "White";
  if (s < 8 && l < 22) return "Black";
  if (s < 12 && l > 35) return "Gray";
  if (s < 12) return "Neutral";
  if (h >= 20 && h < 50 && s < 35) return "Beige";
  if (h >= 20 && h < 50 && s < 60) return "Brown";
  if ((h >= 340 || h < 20) && s > 30) return "Red";
  if (h >= 300 && h < 340 && s > 20) return "Pink";
  if (h >= 20 && h < 40 && s > 50) return "Orange";
  if (h >= 40 && h < 70 && s > 30) return "Yellow";
  if (h >= 70 && h < 165 && s > 15) return "Green";
  if (h >= 165 && h < 260 && s > 15) return "Blue";
  if (h >= 260 && h < 300 && s > 20) return "Purple";
  return "Neutral";
}

function mapSherwinRows(rows, mapping) {
  return rows
    .map((row) => {
      const number = row[mapping.number];
      const name = row[mapping.name];
      const hex = row[mapping.hex];

      if (!number || !name || !hex) {
        return null;
      }

      const normalizedHex = normalizeHex(hex);
      return {
        number: formatSherwinNumber(number),
        name: normalizeName(name),
        family: deriveFamily(normalizedHex),
        hex: normalizedHex,
      };
    })
    .filter(Boolean)
    .sort(naturalColorNumberSort);
}

function mergeSherwinCatalogs(colorsnapColors, designerColors) {
  const merged = new Map();
  let duplicatesDropped = 0;

  for (const color of [...colorsnapColors, ...designerColors]) {
    const existing = merged.get(color.number);
    if (!existing) {
      merged.set(color.number, color);
      continue;
    }

    if (
      existing.name === color.name &&
      existing.hex === color.hex &&
      existing.family === color.family
    ) {
      duplicatesDropped += 1;
      continue;
    }

    throw new Error(
      `Conflicting Sherwin-Williams rows for ${color.number}: ${existing.name}/${existing.hex} vs ${color.name}/${color.hex}`
    );
  }

  return {
    colors: Array.from(merged.values()).sort(naturalColorNumberSort),
    duplicatesDropped,
  };
}

export function validateCatalogShape(colors, brand) {
  const seen = new Set();

  for (const color of colors) {
    assert(color.number && color.number.trim(), `${brand}: blank number encountered`);
    assert(color.name && color.name.trim(), `${brand}: blank name encountered`);
    assert(color.family && color.family.trim(), `${brand}: blank family encountered for ${color.number}`);
    assert(/^[0-9A-F]{6}$/.test(color.hex), `${brand}: invalid hex for ${color.number}`);

    const key = `${brand}:${color.number}`;
    assert(!seen.has(key), `${brand}: duplicate number ${color.number}`);
    seen.add(key);
  }
}

export async function fetchBenjaminMooreCatalog() {
  const [html, searchResults] = await Promise.all([
    fetchText(SOURCES.benjaminMoore.catalogUrl),
    fetchAllBenjaminMooreSearchRecords(),
  ]);
  const payload = extractNextData(html);
  const component = selectBenjaminMoorePaletteComponent(payload.props.pageProps);
  const familyMapping = buildBenjaminMooreFamilyMap(component);
  const mapped = mergeBenjaminMooreRecords(searchResults.records, familyMapping.familyMap);
  const colors = mapped.colors;

  validateCatalogShape(colors, "Benjamin Moore");

  return {
    colors,
    metadata: {
      sourceUrl: SOURCES.benjaminMoore.catalogUrl,
      referenceDetailUrl: SOURCES.benjaminMoore.referenceDetailUrl,
      familyCounts: buildFamilyCounts(colors),
      searchApiUrl: SOURCES.benjaminMoore.searchApiUrl,
      searchResultCount: searchResults.totalResultCount,
      searchPageCount: searchResults.totalPages,
      duplicateFamilyAliasesDropped: familyMapping.duplicateFamilyAliasesDropped,
      derivedFamilyFallbackCount: mapped.derivedFamilyFallbackCount,
    },
  };
}

export async function fetchSherwinWilliamsCatalog() {
  const [colorsnapZip, designerZip] = await Promise.all([
    fetchBuffer(SOURCES.sherwinWilliams.colorSnapZipUrl),
    fetchBuffer(SOURCES.sherwinWilliams.designerEditionZipUrl),
  ]);

  const colorsnapRows = await withTemporaryZipBuffer(colorsnapZip, async (zipPath) => {
    const workbook = readWorkbookFromZip(zipPath);
    return readWorksheetRows(workbook, { range: 1 });
  });

  const designerRows = await withTemporaryZipBuffer(designerZip, async (zipPath) => {
    const workbook = readWorkbookFromZip(zipPath);
    return readWorksheetRows(workbook, { range: 0 });
  });

  const colorsnapColors = mapSherwinRows(colorsnapRows, {
    number: "COLOR #",
    name: "COLOR NAME",
    hex: "HEX",
  });

  const designerColors = mapSherwinRows(designerRows, {
    number: "Color ID",
    name: "Color Name",
    hex: "HEX",
  });

  const merged = mergeSherwinCatalogs(colorsnapColors, designerColors);
  validateCatalogShape(merged.colors, "Sherwin-Williams");

  return {
    colors: merged.colors,
    metadata: {
      sourceUrl: SOURCES.sherwinWilliams.landingUrl,
      colorsnapZipUrl: SOURCES.sherwinWilliams.colorSnapZipUrl,
      designerEditionZipUrl: SOURCES.sherwinWilliams.designerEditionZipUrl,
      sourceCounts: {
        colorsnapWorkbookRows: colorsnapColors.length,
        designerWorkbookRows: designerColors.length,
      },
      duplicatesDropped: merged.duplicatesDropped,
      familyCounts: buildFamilyCounts(merged.colors),
    },
  };
}

export async function fetchOfficialCatalogs() {
  const [benjaminMoore, sherwinWilliams] = await Promise.all([
    fetchBenjaminMooreCatalog(),
    fetchSherwinWilliamsCatalog(),
  ]);

  return { benjaminMoore, sherwinWilliams };
}

function stringifyJson(value) {
  return `${JSON.stringify(value, null, 2)}\n`;
}

export async function ensureCatalogDirectories() {
  await mkdir(dirname(PATHS.webBm), { recursive: true });
  await mkdir(PATHS.iosDir, { recursive: true });
}

export async function writeCanonicalCatalogs({ benjaminMoore, sherwinWilliams }) {
  await ensureCatalogDirectories();

  const bmJson = stringifyJson(benjaminMoore.colors);
  const swJson = stringifyJson(sherwinWilliams.colors);

  await Promise.all([
    writeFile(PATHS.webBm, bmJson),
    writeFile(PATHS.webSw, swJson),
    writeFile(PATHS.iosBm, bmJson),
    writeFile(PATHS.iosSw, swJson),
  ]);
}

export async function readCatalogFile(path) {
  return JSON.parse(await readFile(path, "utf8"));
}

function compareCatalogs(localColors, officialColors, brand) {
  const localMap = new Map(localColors.map((color) => [color.number, color]));
  const officialMap = new Map(officialColors.map((color) => [color.number, color]));

  const missing = [];
  const extra = [];
  const mismatched = [];

  for (const [number, officialColor] of officialMap) {
    const localColor = localMap.get(number);
    if (!localColor) {
      missing.push(number);
      continue;
    }

    if (
      localColor.name !== officialColor.name ||
      localColor.family !== officialColor.family ||
      localColor.hex !== officialColor.hex
    ) {
      mismatched.push({
        number,
        local: localColor,
        official: officialColor,
      });
    }
  }

  for (const number of localMap.keys()) {
    if (!officialMap.has(number)) {
      extra.push(number);
    }
  }

  return {
    brand,
    localCount: localColors.length,
    officialCount: officialColors.length,
    missing,
    extra,
    mismatched,
  };
}

function parsePopularColorNames(sourceText, constantName) {
  const pattern = new RegExp(`const ${constantName}: string\\[] = \\[(.*?)\\];`, "s");
  const match = sourceText.match(pattern);
  assert(match, `Unable to find ${constantName} in src/lib/colors.ts`);
  return Array.from(match[1].matchAll(/"([^"]+)"/g), (group) => group[1]);
}

export async function validateLocalCatalogsAgainstOfficial({ benjaminMoore, sherwinWilliams }) {
  const [localBm, localSw, iosBmRaw, iosSwRaw, colorsSource] = await Promise.all([
    readCatalogFile(PATHS.webBm),
    readCatalogFile(PATHS.webSw),
    readFile(PATHS.iosBm, "utf8"),
    readFile(PATHS.iosSw, "utf8"),
    readFile(PATHS.webColorsSource, "utf8"),
  ]);

  const bmResult = compareCatalogs(localBm, benjaminMoore.colors, "Benjamin Moore");
  const swResult = compareCatalogs(localSw, sherwinWilliams.colors, "Sherwin-Williams");

  const popularBmNames = parsePopularColorNames(colorsSource, "POPULAR_BM_NAMES");
  const popularSwNames = parsePopularColorNames(colorsSource, "POPULAR_SW_NAMES");

  const bmNames = new Set(localBm.map((color) => color.name.toLowerCase()));
  const swNames = new Set(localSw.map((color) => color.name.toLowerCase()));

  const missingPopularBm = popularBmNames.filter((name) => !bmNames.has(name.toLowerCase()));
  const missingPopularSw = popularSwNames.filter((name) => !swNames.has(name.toLowerCase()));

  const swSyntheticNumbers = localSw
    .map((color) => color.number)
    .filter((number) => /^SW\d{4,}$/.test(number));

  assert(bmResult.missing.length === 0, `Benjamin Moore missing ${bmResult.missing.length} official colors`);
  assert(bmResult.extra.length === 0, `Benjamin Moore has ${bmResult.extra.length} extra colors`);
  assert(bmResult.mismatched.length === 0, `Benjamin Moore has ${bmResult.mismatched.length} mismatched colors`);
  assert(swResult.missing.length === 0, `Sherwin-Williams missing ${swResult.missing.length} official colors`);
  assert(swResult.extra.length === 0, `Sherwin-Williams has ${swResult.extra.length} extra colors`);
  assert(swResult.mismatched.length === 0, `Sherwin-Williams has ${swResult.mismatched.length} mismatched colors`);
  assert(swSyntheticNumbers.length === 0, "Sherwin-Williams catalog still contains synthetic numbers without a space");
  assert(missingPopularBm.length === 0, `Missing Benjamin Moore popular colors: ${missingPopularBm.join(", ")}`);
  assert(missingPopularSw.length === 0, `Missing Sherwin-Williams popular colors: ${missingPopularSw.join(", ")}`);
  assert(
    iosBmRaw === stringifyJson(localBm),
    "Bundled iOS Benjamin Moore catalog is out of sync with src/data/bm-colors.json"
  );
  assert(
    iosSwRaw === stringifyJson(localSw),
    "Bundled iOS Sherwin-Williams catalog is out of sync with src/data/sw-colors.json"
  );

  return {
    benjaminMoore: bmResult,
    sherwinWilliams: swResult,
    missingPopularBm,
    missingPopularSw,
  };
}

export function buildRefreshReport({ generatedAt, benjaminMoore, sherwinWilliams, validation }) {
  return {
    generatedAt,
    status: "passed",
    sources: SOURCES,
    benjaminMoore: {
      importedCount: benjaminMoore.colors.length,
      excludedReasons: {
        duplicate_family_aliases: benjaminMoore.metadata.duplicateFamilyAliasesDropped,
        missing_family_fallbacks: benjaminMoore.metadata.derivedFamilyFallbackCount,
        stain_or_nonpaint: 0,
        missing_required_fields: 0,
        duplicate_numbers: 0,
      },
      familyCounts: benjaminMoore.metadata.familyCounts,
    },
    sherwinWilliams: {
      importedCount: sherwinWilliams.colors.length,
      excludedReasons: {
        duplicate_numbers: sherwinWilliams.metadata.duplicatesDropped,
        missing_required_fields: 0,
      },
      sourceCounts: sherwinWilliams.metadata.sourceCounts,
      familyCounts: sherwinWilliams.metadata.familyCounts,
    },
    validation: {
      benjaminMoore: {
        localCount: validation.benjaminMoore.localCount,
        officialCount: validation.benjaminMoore.officialCount,
        missing: validation.benjaminMoore.missing.length,
        extra: validation.benjaminMoore.extra.length,
        mismatched: validation.benjaminMoore.mismatched.length,
      },
      sherwinWilliams: {
        localCount: validation.sherwinWilliams.localCount,
        officialCount: validation.sherwinWilliams.officialCount,
        missing: validation.sherwinWilliams.missing.length,
        extra: validation.sherwinWilliams.extra.length,
        mismatched: validation.sherwinWilliams.mismatched.length,
      },
      popularColorChecks: {
        benjaminMooreMissing: validation.missingPopularBm.length,
        sherwinWilliamsMissing: validation.missingPopularSw.length,
      },
    },
    notes: [
      "Benjamin Moore colors come from the vendor's published advanced-search API, with family labels overlaid from the official paint-colors page when available.",
      "Sherwin-Williams family labels are derived from official hex values because the downloadable workbooks do not publish a single canonical family column.",
      "The iOS bundled JSON files are exact copies of the canonical web JSON artifacts.",
    ],
  };
}

export async function writeRefreshReport(report) {
  await writeFile(PATHS.report, stringifyJson(report));
}
