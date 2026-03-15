import sharp from "sharp";
import { NextRequest, NextResponse } from "next/server";
import {
  MATCH_BRANDS,
  applyGrayWorldBalance,
  buildSampleAnalysisFromHex,
  defaultSampleDiagnostics,
  buildShortlists,
  createSampleAnalysisFromPixels,
  findOcrNumberMatches,
  mergeWarnings,
  toResponseItem,
  type CaptureContext,
  type ColorMatchResponseItem,
  type FocusRect,
  type MatchBrand,
  type MatchMethod,
  type RankedCatalogColor,
  type SampleAnalysis,
} from "@/lib/color-match";
import { recognizeCatalogOcrHints } from "@/lib/color-match-ocr";
import { analyzeWithColorMatchWorker } from "@/lib/color-match-worker";
import { rerankColorMatchesWithGemini } from "@/lib/gemini-color-match";
import {
  isSupportedImageMimeType,
  normalizeImageMimeType,
} from "@/lib/image-mime";
import {
  MAX_IMAGE_UPLOAD_BYTES,
  MAX_IMAGE_UPLOAD_ERROR_MESSAGE,
} from "@/lib/image-upload-limits";
import { colorMatchRateLimit } from "@/lib/rate-limit";

export const runtime = "nodejs";
export const maxDuration = 30;

const SAMPLE_SIZE = 256;
const LOCAL_ANALYSIS_MIME_TYPE = "image/jpeg";

interface ImageSamplePayload {
  imageBuffer: Buffer;
  imageMimeType: string;
  focusRect: FocusRect;
  captureContext?: CaptureContext;
}

function getClientIp(request: NextRequest): string {
  const forwarded = request.headers.get("x-forwarded-for");
  const realIp = request.headers.get("x-real-ip");
  return forwarded?.split(",")[0]?.trim() || realIp || "unknown";
}

function parseFocusRect(rawValue: FormDataEntryValue | null, required: boolean): FocusRect | undefined {
  if (typeof rawValue !== "string" || !rawValue.trim()) {
    if (required) {
      throw new Error("focusRect is required and must be valid JSON.");
    }
    return undefined;
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(rawValue);
  } catch {
    throw new Error("focusRect must be valid JSON.");
  }

  if (!parsed || typeof parsed !== "object") {
    throw new Error("focusRect must be an object with x, y, width, and height.");
  }

  const rect = parsed as Partial<FocusRect>;
  const values = [rect.x, rect.y, rect.width, rect.height];
  if (values.some((value) => typeof value !== "number" || !Number.isFinite(value))) {
    throw new Error("focusRect must contain numeric x, y, width, and height values.");
  }

  if (rect.width! <= 0 || rect.height! <= 0) {
    throw new Error("focusRect width and height must be greater than zero.");
  }

  if (rect.x! < 0 || rect.y! < 0 || rect.x! > 1 || rect.y! > 1 || rect.width! > 1 || rect.height! > 1) {
    throw new Error("focusRect values must be normalized between 0 and 1.");
  }

  if ((rect.x! + rect.width!) > 1 || (rect.y! + rect.height!) > 1) {
    throw new Error("focusRect must stay within the image bounds.");
  }

  return {
    x: rect.x!,
    y: rect.y!,
    width: rect.width!,
    height: rect.height!,
  };
}

function parseCaptureContext(rawValue: FormDataEntryValue | null): CaptureContext | undefined {
  if (typeof rawValue !== "string" || !rawValue.trim()) return undefined;

  let parsed: unknown;
  try {
    parsed = JSON.parse(rawValue);
  } catch {
    throw new Error("captureContext must be valid JSON.");
  }

  if (!parsed || typeof parsed !== "object") {
    throw new Error("captureContext must be an object.");
  }

  const context = parsed as Partial<CaptureContext>;
  if (context.flashUsed != null && typeof context.flashUsed !== "boolean") {
    throw new Error("captureContext.flashUsed must be a boolean.");
  }
  if (context.exposureBias != null && (typeof context.exposureBias !== "number" || !Number.isFinite(context.exposureBias))) {
    throw new Error("captureContext.exposureBias must be a finite number.");
  }
  if (context.whiteBalanceMode != null && typeof context.whiteBalanceMode !== "string") {
    throw new Error("captureContext.whiteBalanceMode must be a string.");
  }
  if (context.whiteBalanceTemperature != null && (typeof context.whiteBalanceTemperature !== "number" || !Number.isFinite(context.whiteBalanceTemperature))) {
    throw new Error("captureContext.whiteBalanceTemperature must be a finite number.");
  }
  if (context.whiteBalanceTint != null && (typeof context.whiteBalanceTint !== "number" || !Number.isFinite(context.whiteBalanceTint))) {
    throw new Error("captureContext.whiteBalanceTint must be a finite number.");
  }
  if (context.whiteBalanceRedGain != null && (typeof context.whiteBalanceRedGain !== "number" || !Number.isFinite(context.whiteBalanceRedGain))) {
    throw new Error("captureContext.whiteBalanceRedGain must be a finite number.");
  }
  if (context.whiteBalanceGreenGain != null && (typeof context.whiteBalanceGreenGain !== "number" || !Number.isFinite(context.whiteBalanceGreenGain))) {
    throw new Error("captureContext.whiteBalanceGreenGain must be a finite number.");
  }
  if (context.whiteBalanceBlueGain != null && (typeof context.whiteBalanceBlueGain !== "number" || !Number.isFinite(context.whiteBalanceBlueGain))) {
    throw new Error("captureContext.whiteBalanceBlueGain must be a finite number.");
  }
  if (context.iso != null && (typeof context.iso !== "number" || !Number.isFinite(context.iso))) {
    throw new Error("captureContext.iso must be a finite number.");
  }
  if (context.exposureDurationSeconds != null && (typeof context.exposureDurationSeconds !== "number" || !Number.isFinite(context.exposureDurationSeconds))) {
    throw new Error("captureContext.exposureDurationSeconds must be a finite number.");
  }
  if (context.deviceModel != null && typeof context.deviceModel !== "string") {
    throw new Error("captureContext.deviceModel must be a string.");
  }
  if (context.capturedAt != null && typeof context.capturedAt !== "string") {
    throw new Error("captureContext.capturedAt must be a string.");
  }
  if (context.latitude != null && (typeof context.latitude !== "number" || !Number.isFinite(context.latitude))) {
    throw new Error("captureContext.latitude must be a finite number.");
  }
  if (context.longitude != null && (typeof context.longitude !== "number" || !Number.isFinite(context.longitude))) {
    throw new Error("captureContext.longitude must be a finite number.");
  }
  if (context.source != null && typeof context.source !== "string") {
    throw new Error("captureContext.source must be a string.");
  }

  return {
    flashUsed: context.flashUsed,
    exposureBias: context.exposureBias,
    whiteBalanceMode: context.whiteBalanceMode?.trim(),
    whiteBalanceTemperature: context.whiteBalanceTemperature,
    whiteBalanceTint: context.whiteBalanceTint,
    whiteBalanceRedGain: context.whiteBalanceRedGain,
    whiteBalanceGreenGain: context.whiteBalanceGreenGain,
    whiteBalanceBlueGain: context.whiteBalanceBlueGain,
    iso: context.iso,
    exposureDurationSeconds: context.exposureDurationSeconds,
    deviceModel: context.deviceModel?.trim(),
    capturedAt: context.capturedAt?.trim(),
    latitude: context.latitude,
    longitude: context.longitude,
    source: context.source?.trim(),
  };
}

async function parseRequestPayload(request: NextRequest): Promise<ImageSamplePayload | { sampleHex: string }> {
  const contentType = request.headers.get("content-type") ?? "";

  if (contentType.includes("application/json")) {
    const body = await request.json();
    const sampleHex = typeof body?.sampleHex === "string" ? body.sampleHex.trim().replace("#", "").toUpperCase() : null;

    if (!sampleHex || !/^[0-9A-F]{6}$/.test(sampleHex)) {
      throw new Error("Please provide a valid 6-digit sample hex value.");
    }

    return { sampleHex };
  }

  const formData = await request.formData();
  const image = formData.get("image");

  if (!(image instanceof File)) {
    throw new Error("Missing required image upload.");
  }

  if (image.size > MAX_IMAGE_UPLOAD_BYTES) {
    throw new Error(MAX_IMAGE_UPLOAD_ERROR_MESSAGE);
  }

  const imageMimeType = normalizeImageMimeType(image.type);
  if (!imageMimeType || !isSupportedImageMimeType(imageMimeType)) {
    throw new Error("Unsupported image type. Please upload JPEG, PNG, WEBP, HEIC, or HEIF.");
  }

  const focusRect = parseFocusRect(formData.get("focusRect"), true);
  if (!focusRect) {
    throw new Error("focusRect is required and must be valid JSON.");
  }

  return {
    imageBuffer: Buffer.from(await image.arrayBuffer()),
    imageMimeType,
    focusRect,
    captureContext: parseCaptureContext(formData.get("captureContext")),
  };
}

async function normalizeUploadedImage(imageBuffer: Buffer): Promise<Buffer> {
  return sharp(imageBuffer, { failOn: "none" })
    .rotate()
    .removeAlpha()
    .toColorspace("srgb")
    .jpeg({ quality: 96, mozjpeg: true })
    .toBuffer();
}

function computeCropRect(width: number, height: number, focusRect: FocusRect) {
  const left = Math.round(focusRect.x * width);
  const top = Math.round(focusRect.y * height);
  const cropWidth = Math.max(1, Math.round(focusRect.width * width));
  const cropHeight = Math.max(1, Math.round(focusRect.height * height));

  return {
    left: Math.min(left, Math.max(0, width - cropWidth)),
    top: Math.min(top, Math.max(0, height - cropHeight)),
    width: Math.min(cropWidth, width),
    height: Math.min(cropHeight, height),
  };
}

async function analyzeUploadedSampleLocally(payload: ImageSamplePayload): Promise<{
  sample: SampleAnalysis;
  ocrCropBase64: string;
  ocrCropMimeType: string;
  rerankCropBase64: string;
  rerankCropMimeType: string;
}> {
  const image = sharp(payload.imageBuffer, { failOn: "none" });
  const metadata = await image.metadata();
  const width = metadata.width ?? 0;
  const height = metadata.height ?? 0;

  if (!width || !height) {
    throw new Error("We could not read that image. Please try another photo.");
  }

  const cropRect = computeCropRect(width, height, payload.focusRect);
  const extracted = await image
    .extract(cropRect)
    .resize(SAMPLE_SIZE, SAMPLE_SIZE, { fit: "fill" })
    .removeAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });

  if (extracted.info.channels < 3) {
    throw new Error("We could not isolate a color sample from that image.");
  }

  const pixels = new Uint8Array(extracted.info.width * extracted.info.height * 3);
  for (let sourceIndex = 0, targetIndex = 0; sourceIndex < extracted.data.length; sourceIndex += extracted.info.channels, targetIndex += 3) {
    pixels[targetIndex] = extracted.data[sourceIndex] ?? 0;
    pixels[targetIndex + 1] = extracted.data[sourceIndex + 1] ?? 0;
    pixels[targetIndex + 2] = extracted.data[sourceIndex + 2] ?? 0;
  }

  const balancedPixels = applyGrayWorldBalance(pixels);
  const preCorrectionSample = createSampleAnalysisFromPixels(pixels);
  const sample = createSampleAnalysisFromPixels(balancedPixels);
  if (!sample) {
    throw new Error("We could not isolate a color sample from that image.");
  }

  const originalCropBuffer = await sharp(Buffer.from(pixels), {
    raw: {
      width: extracted.info.width,
      height: extracted.info.height,
      channels: 3,
    },
  })
    .png()
    .toBuffer();

  const correctedCropBuffer = await sharp(Buffer.from(balancedPixels), {
    raw: {
      width: extracted.info.width,
      height: extracted.info.height,
      channels: 3,
    },
  })
    .png()
    .toBuffer();

  return {
    sample: {
      ...sample,
      diagnostics: defaultSampleDiagnostics({
        ...sample.diagnostics,
        preCorrectionHex: preCorrectionSample?.sampleHex,
        postCorrectionHex: sample.sampleHex,
        awbModel: "gray_world",
      }),
    },
    ocrCropBase64: originalCropBuffer.toString("base64"),
    ocrCropMimeType: "image/png",
    rerankCropBase64: correctedCropBuffer.toString("base64"),
    rerankCropMimeType: "image/png",
  };
}

function augmentWarningsForCaptureContext(sample: SampleAnalysis, captureContext?: CaptureContext): SampleAnalysis {
  const extraWarnings: string[] = [];

  if (captureContext?.flashUsed) {
    extraWarnings.push("Flash can create glare and shift the read. Natural, even light usually produces a stronger match.");
  }

  if ((captureContext?.exposureBias ?? 0) > 0.85) {
    extraWarnings.push("The sample was captured with a bright exposure bias, so the match may read lighter than the surface.");
  }

  if ((captureContext?.exposureBias ?? 0) < -0.85) {
    extraWarnings.push("The sample was captured with a dark exposure bias, so the match may read deeper than the surface.");
  }

  if (!extraWarnings.length) return sample;

  return {
    ...sample,
    warnings: mergeWarnings(sample.warnings, extraWarnings),
  };
}

function buildPrimaryMatches(
  shortlists: Record<MatchBrand, RankedCatalogColor[]>,
  overrides?: Partial<Record<MatchBrand, RankedCatalogColor>>
) {
  return MATCH_BRANDS.map((brand) => {
    const selected = overrides?.[brand] ?? shortlists[brand][0];
    if (!selected) {
      throw new Error(`No colors available for ${brand}.`);
    }
    return toResponseItem(selected);
  });
}

function buildGeminiMatches(
  shortlists: Record<MatchBrand, RankedCatalogColor[]>,
  matches: Array<{ brand: MatchBrand; number: string; confidence: number; rationale: string }>
): ColorMatchResponseItem[] | null {
  const selected = new Map<MatchBrand, ColorMatchResponseItem>();

  for (const match of matches) {
    const shortlistMatch = shortlists[match.brand].find((entry) => entry.color.number === match.number);
    if (!shortlistMatch) {
      return null;
    }

    selected.set(match.brand, {
      ...toResponseItem(shortlistMatch),
      confidence: match.confidence,
      rationale: match.rationale,
    });
  }

  if (selected.size !== MATCH_BRANDS.length) return null;

  return MATCH_BRANDS.map((brand) => selected.get(brand)!).filter(Boolean);
}

function shouldRerankWithGemini(sample: SampleAnalysis, shortlists: Record<MatchBrand, RankedCatalogColor[]>) {
  if (sample.quality === "poor") return false;

  return MATCH_BRANDS.some((brand) => {
    const [first, second] = shortlists[brand];
    if (!first || !second) return false;
    return first.deltaE >= 4.5 || (second.deltaE - first.deltaE) <= 1.4;
  });
}

function enrichDiagnostics(
  sample: SampleAnalysis,
  shortlists: Record<MatchBrand, RankedCatalogColor[]>,
  ocrTextFound: boolean
): SampleAnalysis {
  const deltaEs = MATCH_BRANDS
    .map((brand) => shortlists[brand][0]?.deltaE)
    .filter((value): value is number => typeof value === "number");
  const deltaGaps = MATCH_BRANDS
    .map((brand) => {
      const [first, second] = shortlists[brand];
      if (!first || !second) return null;
      return second.deltaE - first.deltaE;
    })
    .filter((value): value is number => typeof value === "number");

  return {
    ...sample,
    diagnostics: defaultSampleDiagnostics({
      ...sample.diagnostics,
      ocrTextFound,
      deltaETop1: deltaEs.length ? Math.min(...deltaEs) : undefined,
      deltaEGapTop2: deltaGaps.length ? Math.min(...deltaGaps) : undefined,
      postCorrectionHex: sample.diagnostics.postCorrectionHex ?? sample.sampleHex,
    }),
  };
}

function usesAdvancedAwb(sample: SampleAnalysis): boolean {
  const awbModel = sample.diagnostics.awbModel?.trim().toLowerCase();
  return Boolean(awbModel && awbModel !== "gray_world");
}

export async function POST(request: NextRequest) {
  try {
    const ip = getClientIp(request);
    const { success: allowed, remaining } = colorMatchRateLimit(ip);
    if (!allowed) {
      return NextResponse.json(
        { error: "Rate limit exceeded. Please try again later." },
        { status: 429, headers: { "X-RateLimit-Remaining": "0" } }
      );
    }

    const payload = await parseRequestPayload(request);

    let sample: SampleAnalysis;
    let ocrCropBase64: string | null = null;
    let ocrCropMimeType: string | null = null;
    let rerankCropBase64: string | null = null;
    let rerankCropMimeType: string | null = null;

    if ("sampleHex" in payload) {
      const analysis = buildSampleAnalysisFromHex(payload.sampleHex);
      if (!analysis) {
        return NextResponse.json(
          { error: "Please provide a valid 6-digit sample hex value." },
          { status: 400 }
        );
      }
      sample = analysis;
    } else {
      const normalizedImageBuffer = await normalizeUploadedImage(payload.imageBuffer);
      const normalizedPayload = {
        ...payload,
        imageBuffer: normalizedImageBuffer,
        imageMimeType: LOCAL_ANALYSIS_MIME_TYPE,
      };

      const workerAnalysis = await analyzeWithColorMatchWorker(normalizedPayload);
      const localAnalysis = workerAnalysis ?? await analyzeUploadedSampleLocally(normalizedPayload);

      sample = augmentWarningsForCaptureContext(localAnalysis.sample, payload.captureContext);
      ocrCropBase64 = localAnalysis.ocrCropBase64;
      ocrCropMimeType = localAnalysis.ocrCropMimeType;
      rerankCropBase64 = localAnalysis.rerankCropBase64;
      rerankCropMimeType = localAnalysis.rerankCropMimeType;
    }

    const shortlists = buildShortlists(sample.sampleLab);
    let warnings = sample.warnings;
    let matches = buildPrimaryMatches(shortlists);
    let matchMethod: MatchMethod = usesAdvancedAwb(sample)
      ? "learned_awb_deterministic"
      : "deterministic_cv";

    const ocrHints = ocrCropBase64 && ocrCropMimeType
      ? await recognizeCatalogOcrHints({
          imageBase64: ocrCropBase64,
          imageMimeType: ocrCropMimeType,
        })
      : null;

    const ocrMatches = ocrHints
      ? findOcrNumberMatches(sample.sampleLab, ocrHints.normalizedCandidates)
      : {};

    sample = enrichDiagnostics(sample, shortlists, Boolean(ocrHints?.rawText.trim()));

    if (Object.keys(ocrMatches).length > 0) {
      matches = buildPrimaryMatches(shortlists, ocrMatches);
      matchMethod = "ocr_exact";
    } else if (rerankCropBase64 && rerankCropMimeType && shouldRerankWithGemini(sample, shortlists)) {
      const assessment = await rerankColorMatchesWithGemini({
        imageBase64: rerankCropBase64,
        imageMimeType: rerankCropMimeType,
        sample,
        shortlists,
        ocrText: ocrHints?.rawText ?? null,
      });

      const geminiMatches = assessment
        ? buildGeminiMatches(shortlists, assessment.matches)
        : null;

      if (geminiMatches) {
        matches = geminiMatches;
        warnings = mergeWarnings(sample.warnings, assessment?.warnings);
        matchMethod = usesAdvancedAwb(sample)
          ? "learned_awb_vlm_rerank"
          : "gemini_shortlist";
      }
    }

    return NextResponse.json(
      {
        sampleHex: sample.sampleHex,
        quality: sample.quality,
        warnings,
        diagnostics: sample.diagnostics,
        matchMethod,
        matches,
      },
      {
        status: 200,
        headers: { "X-RateLimit-Remaining": String(remaining) },
      }
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : "We couldn't match this color right now. Please try again.";
    const status =
      message.includes("valid 6-digit") ||
      message.includes("Unsupported image type") ||
      message.includes("Missing required image") ||
      message.includes("focusRect") ||
      message.includes("captureContext") ||
      message.includes(MAX_IMAGE_UPLOAD_ERROR_MESSAGE)
        ? 400
        : 500;

    console.error("Color match API error:", error);
    return NextResponse.json({ error: message }, { status });
  }
}
