import { GoogleGenAI } from "@google/genai";

const DEFAULT_PRIMARY_MODEL = "gemini-2.5-flash-image";
const DEFAULT_FALLBACK_MODEL = "gemini-3.1-flash-image-preview";
const DEFAULT_SECONDARY_FALLBACK_MODEL = "gemini-2.0-flash-preview-image-generation";
const REQUEST_TIMEOUT_MS = 45_000;
const MAX_RETRIES = 2;

export class GeminiGenerationError extends Error {
  status: number;
  code: string;
  cause?: unknown;

  constructor(
    message: string,
    options: { status: number; code: string; cause?: unknown }
  ) {
    super(message);
    this.name = "GeminiGenerationError";
    this.status = options.status;
    this.code = options.code;
    this.cause = options.cause;
  }
}

let _ai: GoogleGenAI | null = null;

function getClient(): GoogleGenAI {
  if (!_ai) {
    if (!process.env.GEMINI_API_KEY) {
      throw new Error("GEMINI_API_KEY environment variable is not set");
    }
    _ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
  }
  return _ai;
}

function configuredModelIds(): string[] {
  const modelCandidates = [
    process.env.GEMINI_IMAGE_MODEL?.trim() || DEFAULT_PRIMARY_MODEL,
    process.env.GEMINI_IMAGE_FALLBACK_MODEL?.trim() || DEFAULT_FALLBACK_MODEL,
    process.env.GEMINI_IMAGE_SECONDARY_FALLBACK_MODEL?.trim() ||
      DEFAULT_SECONDARY_FALLBACK_MODEL,
  ];

  return [...new Set(modelCandidates.filter(Boolean))];
}

function getErrorStatus(error: unknown): number | undefined {
  if (!error || typeof error !== "object") return undefined;
  const maybeError = error as { status?: number; response?: { status?: number } };
  return maybeError.status ?? maybeError.response?.status;
}

function getErrorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  return String(error);
}

function toGeminiGenerationError(
  error: unknown,
  modelId: string
): GeminiGenerationError {
  if (error instanceof GeminiGenerationError) return error;

  const message = getErrorMessage(error);
  const status = getErrorStatus(error);
  const lower = message.toLowerCase();

  if (status === 429) {
    return new GeminiGenerationError(
      "Gemini rate limit exceeded. Please retry shortly.",
      { status: 429, code: "RATE_LIMIT", cause: error }
    );
  }

  if (lower.includes("timed out")) {
    return new GeminiGenerationError(
      "Gemini request timed out. Please retry.",
      { status: 504, code: "TIMEOUT", cause: error }
    );
  }

  if (status === 401 || status === 403) {
    return new GeminiGenerationError(
      "Gemini credentials are invalid or missing permissions.",
      { status: 500, code: "AUTH_ERROR", cause: error }
    );
  }

  if (status === 404 || lower.includes("not found") || lower.includes("not available")) {
    return new GeminiGenerationError(
      `Gemini model "${modelId}" is unavailable.`,
      { status: 503, code: "MODEL_UNAVAILABLE", cause: error }
    );
  }

  if (status === 400 || lower.includes("invalid") || lower.includes("unsupported")) {
    return new GeminiGenerationError(
      "Gemini rejected this image or prompt.",
      { status: 422, code: "INVALID_INPUT", cause: error }
    );
  }

  return new GeminiGenerationError("Gemini image generation failed.", {
    status: 503,
    code: "UPSTREAM_ERROR",
    cause: error,
  });
}

function isRetryableError(error: unknown): boolean {
  const status = getErrorStatus(error);
  if (!status) {
    return getErrorMessage(error).toLowerCase().includes("timed out");
  }
  return [408, 429, 500, 502, 503, 504].includes(status);
}

function shouldTryFallbackModel(error: unknown): boolean {
  const status = getErrorStatus(error);
  if (status && [408, 429, 500, 502, 503, 504].includes(status)) return true;
  if (status === 404) return true;

  const message = getErrorMessage(error).toLowerCase();
  return (
    message.includes("timed out") ||
    message.includes("not found") ||
    message.includes("unsupported model") ||
    message.includes("not available") ||
    message.includes("model not")
  );
}

async function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T> {
  let timeoutId: NodeJS.Timeout | null = null;
  const timeoutPromise = new Promise<never>((_, reject) => {
    timeoutId = setTimeout(() => reject(new Error("Gemini request timed out")), ms);
  });

  try {
    return await Promise.race([promise, timeoutPromise]);
  } finally {
    if (timeoutId) clearTimeout(timeoutId);
  }
}

function extractImageFromResponse(
  response: unknown
): { data: string; mimeType: string } | null {
  if (!response || typeof response !== "object") return null;

  const maybeResponse = response as {
    candidates?: Array<{
      content?: {
        parts?: Array<{
          inlineData?: { data?: string; mimeType?: string };
          inline_data?: { data?: string; mime_type?: string };
        }>;
      };
    }>;
  };

  const candidates = maybeResponse.candidates ?? [];
  for (const candidate of candidates) {
    const parts = candidate.content?.parts ?? [];
    for (const part of parts) {
      const inlineData =
        part.inlineData ??
        (part.inline_data
          ? {
              data: part.inline_data.data,
              mimeType: part.inline_data.mime_type,
            }
          : undefined);
      if (
        inlineData?.data &&
        inlineData?.mimeType &&
        inlineData.mimeType.startsWith("image/")
      ) {
        return { data: inlineData.data, mimeType: inlineData.mimeType };
      }
    }
  }

  return null;
}

async function generateWithModel(
  ai: GoogleGenAI,
  modelId: string,
  prompt: string,
  imageBase64: string,
  imageMimeType: string
): Promise<{ data: string; mimeType: string }> {
  let lastError: unknown = null;

  for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
    try {
      const response = await withTimeout(
        ai.models.generateContent({
          model: modelId,
          contents: [
            {
              role: "user",
              parts: [
                { text: prompt },
                {
                  inlineData: {
                    mimeType: imageMimeType,
                    data: imageBase64,
                  },
                },
              ],
            },
          ],
          config: {
            // We only need the edited image payload.
            responseModalities: ["IMAGE"],
          },
        }),
        REQUEST_TIMEOUT_MS
      );

      const image = extractImageFromResponse(response);
      if (!image) {
        throw new GeminiGenerationError(
          "Gemini returned no image for this request.",
          { status: 422, code: "NO_IMAGE" }
        );
      }

      return image;
    } catch (error) {
      lastError = error;
      const canRetry = attempt < MAX_RETRIES && isRetryableError(error);
      if (!canRetry) break;
      await sleep(250 * 2 ** attempt);
    }
  }

  throw toGeminiGenerationError(lastError, modelId);
}

/**
 * Send an image + text prompt to Gemini and return the generated image.
 * Returns { data: string (base64), mimeType: string } or throws.
 */
export async function generatePaintVisualization(
  prompt: string,
  imageBase64: string,
  imageMimeType: string
): Promise<{ data: string; mimeType: string }> {
  let ai: GoogleGenAI;
  try {
    ai = getClient();
  } catch (error) {
    throw new GeminiGenerationError(
      "Gemini is not configured. Missing API credentials.",
      { status: 500, code: "AUTH_ERROR", cause: error }
    );
  }

  const modelIds = configuredModelIds();
  let lastError: unknown = null;

  for (let i = 0; i < modelIds.length; i++) {
    const modelId = modelIds[i];
    try {
      const image = await generateWithModel(
        ai,
        modelId,
        prompt,
        imageBase64,
        imageMimeType
      );
      return image;
    } catch (error) {
      lastError = error;
      const hasFallback = i < modelIds.length - 1;
      const shouldFallback = hasFallback && shouldTryFallbackModel(error);
      if (!shouldFallback) break;
      console.warn(
        `Gemini model "${modelId}" failed; trying fallback model "${modelIds[i + 1]}".`
      );
    }
  }

  const modelList = modelIds.join(", ");
  const wrapped = toGeminiGenerationError(
    lastError,
    modelIds[modelIds.length - 1] ?? DEFAULT_FALLBACK_MODEL
  );
  wrapped.message = `${wrapped.message} Tried models: ${modelList}.`;
  throw wrapped;
}
