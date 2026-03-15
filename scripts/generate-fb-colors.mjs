import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { deriveFamily } from "./color-catalog.mjs";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const TOTAL_PAGES = 4;
const EXPECTED_RAW_LISTING_COUNT = 303;
const EXPECTED_UNIQUE_COLOR_COUNT = 301;
const DEFAULT_CONCURRENCY = Number.parseInt(process.env.FB_FETCH_CONCURRENCY ?? "6", 10);
const REQUEST_HEADERS = {
  "user-agent": "CrainPaintVisualizer FarrowBall importer/1.0",
  accept: "text/html,application/xhtml+xml",
};

const OUTPUT_DIRECTORY = path.resolve(
  __dirname,
  "../CrainPaintVisualizer/Sources/Resources/ColorCatalog"
);
const CATALOG_OUTPUT_PATH = path.join(OUTPUT_DIRECTORY, "fb-colors.json");
const POPULAR_OUTPUT_PATH = path.join(OUTPUT_DIRECTORY, "fb-popular-colors.json");

const POPULAR_NAMES = [
  "All White",
  "School House White",
  "Strong White",
  "Slipper Satin",
  "Skimming Stone",
  "Ammonite",
  "Cornforth White",
  "Elephant's Breath",
  "Drop Cloth",
  "Joa's White",
  "Pointing",
  "Dimity",
  "Wimborne White",
  "Setting Plaster",
  "Sulking Room Pink",
  "Hague Blue",
  "Stiffkey Blue",
  "De Nimes",
  "Parma Gray",
  "French Gray",
  "Green Smoke",
  "Card Room Green",
  "Railings",
  "Down Pipe",
];

const SPOT_CHECKS = [
  { number: "No. 317", name: "Kakelugn", hex: "C5D1D8" },
  { number: "No. 311", name: "Scallop", hex: "D9C8BA" },
  { number: "No. 30", name: "Hague Blue", hex: "3F4D57" },
];

function decodeHtmlEntities(value) {
  return value
    .replace(/&#x([0-9a-f]+);/gi, (_, hex) => String.fromCodePoint(Number.parseInt(hex, 16)))
    .replace(/&#(\d+);/g, (_, decimal) => String.fromCodePoint(Number.parseInt(decimal, 10)))
    .replace(/&quot;/g, '"')
    .replace(/&apos;|&#39;|&#039;/g, "'")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&nbsp;/g, " ");
}

function stripTags(value) {
  return value.replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim();
}

function normalizeNumber(value) {
  const digits = decodeHtmlEntities(stripTags(value)).match(/(\d+)/)?.[1];
  if (!digits) {
    throw new Error(`Unable to derive color number from ${JSON.stringify(value)}`);
  }
  return `No. ${digits}`;
}

function naturalColorNumberSort(left, right) {
  const leftNumber = Number.parseInt(left.number.replace(/\D/g, ""), 10);
  const rightNumber = Number.parseInt(right.number.replace(/\D/g, ""), 10);

  if (leftNumber === rightNumber) {
    return left.name.localeCompare(right.name);
  }

  return leftNumber - rightNumber;
}

async function fetchText(url) {
  const response = await fetch(url, { headers: REQUEST_HEADERS });
  if (!response.ok) {
    throw new Error(`Failed to fetch ${url}: ${response.status} ${response.statusText}`);
  }
  return response.text();
}

function extractListingEntries(html) {
  return [...html.matchAll(/<a class="product-item-link"\s+href="([^"]+)">\s*([\s\S]*?)<\/a>\s*<div class="product-item-code">([\s\S]*?)<\/div>/g)]
    .map((match) => {
      const href = match[1];
      const name = decodeHtmlEntities(stripTags(match[2]));
      const number = normalizeNumber(match[3]);
      const slug = new URL(href).pathname.replace(/^\/paint\//, "").replace(/\/$/, "");

      return {
        slug,
        url: href,
        name,
        number,
      };
    });
}

async function mapWithConcurrency(items, concurrency, worker) {
  const results = new Array(items.length);
  let nextIndex = 0;

  async function runWorker() {
    while (true) {
      const currentIndex = nextIndex;
      nextIndex += 1;
      if (currentIndex >= items.length) {
        return;
      }
      results[currentIndex] = await worker(items[currentIndex], currentIndex);
    }
  }

  await Promise.all(
    Array.from({ length: Math.max(1, Math.min(concurrency, items.length)) }, () => runWorker())
  );

  return results;
}

async function fetchColorDetails(entry) {
  const html = await fetchText(entry.url);
  const hex = html.match(/"productBgColor":"#([0-9A-Fa-f]{6})"/)?.[1]?.toUpperCase();
  const productCode = html.match(/"product_code":"([^"]+)"/)?.[1];
  const productName = html.match(/"product_name":"([^"]+)"/)?.[1];

  if (!hex) {
    throw new Error(`Missing productBgColor for ${entry.url}`);
  }

  if (productCode && normalizeNumber(productCode) !== entry.number) {
    throw new Error(`Number mismatch for ${entry.url}: ${entry.number} vs ${productCode}`);
  }

  if (productName && decodeHtmlEntities(productName) !== entry.name) {
    throw new Error(`Name mismatch for ${entry.url}: ${entry.name} vs ${productName}`);
  }

  return {
    number: entry.number,
    name: entry.name,
    family: deriveFamily(hex),
    hex,
    brand: "farrow_ball",
  };
}

function buildPopularColors(colors) {
  const colorsByName = new Map(colors.map((color) => [color.name.toLowerCase(), color]));
  const popular = POPULAR_NAMES.map((name) => colorsByName.get(name.toLowerCase())).filter(Boolean);

  if (popular.length !== POPULAR_NAMES.length) {
    const missing = POPULAR_NAMES.filter((name) => !colorsByName.has(name.toLowerCase()));
    throw new Error(`Missing curated popular Farrow & Ball colors: ${missing.join(", ")}`);
  }

  return popular;
}

function validateCatalog(colors, rawListingCount) {
  if (rawListingCount !== EXPECTED_RAW_LISTING_COUNT) {
    throw new Error(
      `Expected ${EXPECTED_RAW_LISTING_COUNT} raw Farrow & Ball listing entries, found ${rawListingCount}`
    );
  }

  if (colors.length !== EXPECTED_UNIQUE_COLOR_COUNT) {
    throw new Error(
      `Expected ${EXPECTED_UNIQUE_COLOR_COUNT} unique Farrow & Ball colors, found ${colors.length}`
    );
  }

  const seenEntries = new Set();
  for (const color of colors) {
    if (!/^[0-9A-F]{6}$/.test(color.hex)) {
      throw new Error(`Invalid hex for ${color.number}: ${color.hex}`);
    }
    const key = `${color.number}|${color.name}`;
    if (seenEntries.has(key)) {
      throw new Error(`Duplicate Farrow & Ball entry found: ${key}`);
    }
    seenEntries.add(key);
  }

  for (const expected of SPOT_CHECKS) {
    const actual = colors.find((color) => color.number == expected.number);
    if (!actual) {
      throw new Error(`Missing spot-check color ${expected.number}`);
    }
    if (actual.name !== expected.name || actual.hex !== expected.hex) {
      throw new Error(
        `Spot-check failed for ${expected.number}: expected ${expected.name}/${expected.hex}, received ${actual.name}/${actual.hex}`
      );
    }
  }
}

async function writeJSON(filePath, value) {
  await writeFile(filePath, `${JSON.stringify(value, null, 2)}\n`, "utf8");
}

async function main() {
  const listingEntries = [];

  for (let page = 1; page <= TOTAL_PAGES; page += 1) {
    const html = await fetchText(`https://www.farrow-ball.com/paint/all-paint-colours?p=${page}`);
    const pageEntries = extractListingEntries(html);
    if (pageEntries.length === 0) {
      throw new Error(`No listing entries found on catalog page ${page}`);
    }
    listingEntries.push(...pageEntries);
  }

  const uniqueListingEntries = [...new Map(listingEntries.map((entry) => [entry.url, entry])).values()];
  const colors = (await mapWithConcurrency(uniqueListingEntries, DEFAULT_CONCURRENCY, fetchColorDetails))
    .sort(naturalColorNumberSort);

  validateCatalog(colors, listingEntries.length);

  const popularColors = buildPopularColors(colors);

  await mkdir(OUTPUT_DIRECTORY, { recursive: true });
  await writeJSON(CATALOG_OUTPUT_PATH, colors);
  await writeJSON(POPULAR_OUTPUT_PATH, popularColors);

  console.log(
    JSON.stringify(
      {
        status: "ok",
        rawListingEntries: listingEntries.length,
        totalColors: colors.length,
        popularColors: popularColors.length,
        output: {
          catalog: CATALOG_OUTPUT_PATH,
          popular: POPULAR_OUTPUT_PATH,
        },
        spotChecks: SPOT_CHECKS,
      },
      null,
      2
    )
  );
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
});
