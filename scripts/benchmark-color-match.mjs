import fs from "node:fs/promises";
import path from "node:path";

function usage() {
  console.error("Usage: node scripts/benchmark-color-match.mjs <manifest.json>");
  process.exit(1);
}

function normalizeCatalogNumber(value) {
  return String(value ?? "").toUpperCase().replace(/[^A-Z0-9]/g, "");
}

async function loadManifest(manifestPath) {
  const file = await fs.readFile(manifestPath, "utf8");
  const parsed = JSON.parse(file);
  if (!Array.isArray(parsed.samples) || parsed.samples.length === 0) {
    throw new Error("Manifest must contain a non-empty samples array.");
  }
  return parsed;
}

async function runSample(baseURL, sample, manifestDir) {
  const imagePath = path.resolve(manifestDir, sample.imagePath);
  const buffer = await fs.readFile(imagePath);

  const formData = new FormData();
  formData.set("image", new Blob([buffer], { type: sample.imageMimeType ?? "image/jpeg" }), path.basename(imagePath));
  formData.set("focusRect", JSON.stringify(sample.focusRect));

  if (sample.captureContext) {
    formData.set("captureContext", JSON.stringify(sample.captureContext));
  }

  const response = await fetch(new URL("/api/color-match", baseURL), {
    method: "POST",
    body: formData,
  });

  const payload = await response.json();
  if (!response.ok) {
    return {
      id: sample.id,
      ok: false,
      error: payload.error ?? `HTTP ${response.status}`,
    };
  }

  const expectedBrand = sample.expected?.brand ?? null;
  const expectedNumber = normalizeCatalogNumber(sample.expected?.number ?? "");
  const ranked = Array.isArray(payload.matches) ? payload.matches : [];
  const normalizedRanked = ranked.map((match) => ({
    brand: match.brand,
    number: normalizeCatalogNumber(match.number),
    confidence: match.confidence,
  }));

  const top1 = normalizedRanked[0] ?? null;
  const top3 = normalizedRanked.slice(0, 3);
  const top1Correct = Boolean(top1 && top1.brand === expectedBrand && top1.number === expectedNumber);
  const top3Correct = top3.some((match) => match.brand === expectedBrand && match.number === expectedNumber);

  return {
    id: sample.id,
    ok: true,
    expectedBrand,
    expectedNumber,
    top1Correct,
    top3Correct,
    matchMethod: payload.matchMethod,
    diagnostics: payload.diagnostics ?? null,
    top1,
    ranked: top3,
  };
}

function summarize(results) {
  const successful = results.filter((result) => result.ok);
  const failures = results.filter((result) => !result.ok);
  const top1Hits = successful.filter((result) => result.top1Correct).length;
  const top3Hits = successful.filter((result) => result.top3Correct).length;
  const deltaEs = successful
    .map((result) => result.diagnostics?.deltaETop1)
    .filter((value) => typeof value === "number");

  return {
    sampleCount: results.length,
    successfulSamples: successful.length,
    failedSamples: failures.length,
    top1Accuracy: successful.length ? Number((top1Hits / successful.length).toFixed(4)) : 0,
    top3Accuracy: successful.length ? Number((top3Hits / successful.length).toFixed(4)) : 0,
    medianDeltaETop1: deltaEs.length
      ? deltaEs.sort((left, right) => left - right)[Math.floor(deltaEs.length / 2)]
      : null,
  };
}

async function main() {
  const manifestArg = process.argv[2];
  if (!manifestArg) usage();

  const baseURL = process.env.COLOR_MATCH_BENCHMARK_BASE_URL ?? process.env.CRAIN_API_BASE_URL;
  if (!baseURL) {
    throw new Error("Set COLOR_MATCH_BENCHMARK_BASE_URL or CRAIN_API_BASE_URL before running the benchmark.");
  }

  const manifestPath = path.resolve(process.cwd(), manifestArg);
  const manifest = await loadManifest(manifestPath);
  const manifestDir = path.dirname(manifestPath);

  const results = [];
  for (const sample of manifest.samples) {
    results.push(await runSample(baseURL, sample, manifestDir));
  }

  const report = {
    manifest: path.basename(manifestPath),
    generatedAt: new Date().toISOString(),
    summary: summarize(results),
    results,
  };

  console.log(JSON.stringify(report, null, 2));
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
