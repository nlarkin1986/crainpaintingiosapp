import {
  buildSampleAnalysisFromHex,
  defaultSampleDiagnostics,
  type CaptureContext,
  type FocusRect,
  type SampleAnalysis,
} from "@/lib/color-match";

const DEFAULT_TIMEOUT_MS = 8_000;

interface WorkerDiagnostics {
  coveragePct: number;
  glarePct: number;
  variance: number;
  preCorrectionHex?: string;
  postCorrectionHex?: string;
}

interface WorkerAnalysisResponse {
  sampleHex: string;
  quality: SampleAnalysis["quality"];
  warnings: string[];
  diagnostics: WorkerDiagnostics;
  awbModel?: string;
  cropBase64: string;
  cropMimeType: string;
  correctedCropBase64?: string;
  correctedCropMimeType?: string;
}

function getWorkerBaseUrl(): string | null {
  return process.env.COLOR_MATCH_WORKER_URL?.trim() || null;
}

function getWorkerTimeoutMs(): number {
  const parsed = Number(process.env.COLOR_MATCH_WORKER_TIMEOUT_MS);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : DEFAULT_TIMEOUT_MS;
}

function getWorkerHeaders() {
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
  };

  const token = process.env.COLOR_MATCH_WORKER_TOKEN?.trim();
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }

  return headers;
}

function parseWorkerResponse(payload: unknown): WorkerAnalysisResponse | null {
  if (!payload || typeof payload !== "object") return null;
  const response = payload as Partial<WorkerAnalysisResponse>;

  if (
    typeof response.sampleHex !== "string" ||
    (response.quality !== "good" && response.quality !== "mixed" && response.quality !== "poor") ||
    !Array.isArray(response.warnings) ||
    !response.diagnostics ||
    typeof response.cropBase64 !== "string" ||
    typeof response.cropMimeType !== "string"
  ) {
    return null;
  }

  const diagnostics = response.diagnostics as Partial<WorkerDiagnostics>;
  if (
    typeof diagnostics.coveragePct !== "number" ||
    typeof diagnostics.glarePct !== "number" ||
    typeof diagnostics.variance !== "number"
  ) {
    return null;
  }

  return {
    sampleHex: response.sampleHex,
    quality: response.quality,
    warnings: response.warnings.filter((warning): warning is string => typeof warning === "string"),
    diagnostics: {
      coveragePct: diagnostics.coveragePct,
      glarePct: diagnostics.glarePct,
      variance: diagnostics.variance,
      preCorrectionHex: typeof diagnostics.preCorrectionHex === "string" ? diagnostics.preCorrectionHex : undefined,
      postCorrectionHex: typeof diagnostics.postCorrectionHex === "string" ? diagnostics.postCorrectionHex : undefined,
    },
    awbModel: typeof response.awbModel === "string" ? response.awbModel : undefined,
    cropBase64: response.cropBase64,
    cropMimeType: response.cropMimeType,
    correctedCropBase64: typeof response.correctedCropBase64 === "string" ? response.correctedCropBase64 : undefined,
    correctedCropMimeType: typeof response.correctedCropMimeType === "string" ? response.correctedCropMimeType : undefined,
  };
}

export interface ColorMatchWorkerAnalysis {
  sample: SampleAnalysis;
  ocrCropBase64: string;
  ocrCropMimeType: string;
  rerankCropBase64: string;
  rerankCropMimeType: string;
}

export async function analyzeWithColorMatchWorker(input: {
  imageBuffer: Buffer;
  imageMimeType: string;
  focusRect: FocusRect;
  captureContext?: CaptureContext;
}): Promise<ColorMatchWorkerAnalysis | null> {
  const baseUrl = getWorkerBaseUrl();
  if (!baseUrl) return null;

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), getWorkerTimeoutMs());

  try {
    const response = await fetch(new URL("/match/analyze", baseUrl), {
      method: "POST",
      headers: getWorkerHeaders(),
      body: JSON.stringify({
        imageBase64: input.imageBuffer.toString("base64"),
        imageMimeType: input.imageMimeType,
        focusRect: input.focusRect,
        captureContext: input.captureContext,
      }),
      signal: controller.signal,
    });

    if (!response.ok) {
      console.error("Color match worker failed:", response.status, await response.text());
      return null;
    }

    const payload = parseWorkerResponse(await response.json());
    if (!payload) return null;

    const sample = buildSampleAnalysisFromHex(payload.sampleHex, {
      quality: payload.quality,
      warnings: payload.warnings,
      spread: payload.diagnostics.variance,
      diagnostics: defaultSampleDiagnostics({
        coveragePct: payload.diagnostics.coveragePct,
        glarePct: payload.diagnostics.glarePct,
        variance: payload.diagnostics.variance,
        preCorrectionHex: payload.diagnostics.preCorrectionHex,
        postCorrectionHex: payload.diagnostics.postCorrectionHex ?? payload.sampleHex,
        awbModel: payload.awbModel,
      }),
    });

    if (!sample) return null;

    return {
      sample,
      ocrCropBase64: payload.cropBase64,
      ocrCropMimeType: payload.cropMimeType,
      rerankCropBase64: payload.correctedCropBase64 ?? payload.cropBase64,
      rerankCropMimeType: payload.correctedCropMimeType ?? payload.cropMimeType,
    };
  } catch (error) {
    console.error("Color match worker request error:", error);
    return null;
  } finally {
    clearTimeout(timeoutId);
  }
}
