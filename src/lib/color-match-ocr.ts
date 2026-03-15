import { normalizeCatalogNumber } from "@/lib/color-match";

const DEFAULT_TIMEOUT_MS = 6_000;
const DEFAULT_FEATURE_TYPE = "TEXT_DETECTION";

interface VisionAnnotateResponse {
  responses?: Array<{
    fullTextAnnotation?: {
      text?: string;
    };
    textAnnotations?: Array<{
      description?: string;
    }>;
  }>;
}

export interface CatalogOcrHints {
  rawText: string;
  normalizedCandidates: string[];
}

function getVisionApiKey(): string | null {
  return process.env.GOOGLE_CLOUD_VISION_API_KEY?.trim() || null;
}

function getVisionTimeoutMs(): number {
  const parsed = Number(process.env.GOOGLE_CLOUD_VISION_TIMEOUT_MS);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : DEFAULT_TIMEOUT_MS;
}

function getVisionFeatureType(): "TEXT_DETECTION" | "DOCUMENT_TEXT_DETECTION" {
  return process.env.GOOGLE_CLOUD_VISION_FEATURE_TYPE === "DOCUMENT_TEXT_DETECTION"
    ? "DOCUMENT_TEXT_DETECTION"
    : DEFAULT_FEATURE_TYPE;
}

function extractRawText(payload: VisionAnnotateResponse): string {
  const response = payload.responses?.[0];
  const fullText = response?.fullTextAnnotation?.text?.trim();
  if (fullText) return fullText;

  const annotationText = response?.textAnnotations?.[0]?.description?.trim();
  return annotationText ?? "";
}

function buildNormalizedCandidates(text: string): string[] {
  const tokens = text
    .toUpperCase()
    .split(/[^A-Z0-9]+/)
    .map((token) => token.trim())
    .filter(Boolean);

  const candidates = new Set<string>();

  for (let index = 0; index < tokens.length; index += 1) {
    const current = tokens[index];
    if (!current) continue;
    candidates.add(normalizeCatalogNumber(current));

    const next = tokens[index + 1];
    if (next) {
      candidates.add(normalizeCatalogNumber(`${current}${next}`));
    }

    const third = tokens[index + 2];
    if (next && third) {
      candidates.add(normalizeCatalogNumber(`${current}${next}${third}`));
    }
  }

  return [...candidates].filter(Boolean);
}

export async function recognizeCatalogOcrHints(input: {
  imageBase64: string;
  imageMimeType: string;
}): Promise<CatalogOcrHints | null> {
  const apiKey = getVisionApiKey();
  if (!apiKey) return null;

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), getVisionTimeoutMs());

  try {
    const response = await fetch(`https://vision.googleapis.com/v1/images:annotate?key=${encodeURIComponent(apiKey)}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        requests: [
          {
            image: {
              content: input.imageBase64,
            },
            features: [
              {
                type: getVisionFeatureType(),
                maxResults: 10,
              },
            ],
            imageContext: {
              languageHints: ["en"],
            },
          },
        ],
      }),
      signal: controller.signal,
    });

    if (!response.ok) {
      console.error("Color match OCR request failed:", response.status, await response.text());
      return null;
    }

    const payload = await response.json() as VisionAnnotateResponse;
    const rawText = extractRawText(payload);
    if (!rawText) return null;

    return {
      rawText,
      normalizedCandidates: buildNormalizedCandidates(rawText),
    };
  } catch (error) {
    console.error("Color match OCR request error:", error);
    return null;
  } finally {
    clearTimeout(timeoutId);
  }
}
