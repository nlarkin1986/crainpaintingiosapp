import { GoogleGenAI } from "@google/genai";
import type { MatchBrand, RankedCatalogColor, SampleAnalysis } from "@/lib/color-match";

const DEFAULT_MODEL = "gemini-2.5-flash";
const REQUEST_TIMEOUT_MS = 20_000;

interface GeminiColorMatchSelection {
  brand: MatchBrand;
  number: string;
  confidence: number;
  rationale: string;
}

export interface GeminiColorMatchAssessment {
  warnings: string[];
  matches: GeminiColorMatchSelection[];
}

interface GeminiMatchRequest {
  imageBase64: string;
  imageMimeType: string;
  sample: SampleAnalysis;
  shortlists: Record<MatchBrand, RankedCatalogColor[]>;
  ocrText?: string | null;
}

let googleClient: GoogleGenAI | null = null;

function getGoogleClient(): GoogleGenAI | null {
  if (!process.env.GEMINI_API_KEY) return null;
  if (!googleClient) {
    googleClient = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
  }
  return googleClient;
}

function configuredModelIds(): string[] {
  const explicit = process.env.COLOR_MATCH_RERANK_MODELS
    ?.split(",")
    .map((model) => model.trim())
    .filter(Boolean);

  if (explicit?.length) {
    return [...new Set(explicit)];
  }

  return [
    process.env.GEMINI_COLOR_MATCH_MODEL?.trim() || DEFAULT_MODEL,
  ].filter(Boolean);
}

async function withTimeout<T>(promise: Promise<T>, timeoutMs: number): Promise<T> {
  let timeoutId: NodeJS.Timeout | null = null;
  const timeoutPromise = new Promise<never>((_, reject) => {
    timeoutId = setTimeout(() => reject(new Error("Color match rerank request timed out")), timeoutMs);
  });

  try {
    return await Promise.race([promise, timeoutPromise]);
  } finally {
    if (timeoutId) clearTimeout(timeoutId);
  }
}

function extractTextFromGoogleResponse(response: unknown): string | null {
  if (!response || typeof response !== "object") return null;

  const maybeResponse = response as {
    text?: string;
    candidates?: Array<{
      content?: {
        parts?: Array<{ text?: string }>;
      };
    }>;
  };

  if (typeof maybeResponse.text === "string" && maybeResponse.text.trim()) {
    return maybeResponse.text.trim();
  }

  const parts = maybeResponse.candidates?.flatMap((candidate) => candidate.content?.parts ?? []) ?? [];
  const text = parts
    .map((part) => part.text?.trim())
    .filter((value): value is string => Boolean(value))
    .join("\n");

  return text || null;
}

function extractTextFromOpenAIResponse(response: unknown): string | null {
  if (!response || typeof response !== "object") return null;

  const maybeResponse = response as {
    output_text?: string;
    output?: Array<{
      content?: Array<{
        text?: string;
      }>;
    }>;
  };

  if (typeof maybeResponse.output_text === "string" && maybeResponse.output_text.trim()) {
    return maybeResponse.output_text.trim();
  }

  const text = maybeResponse.output
    ?.flatMap((item) => item.content ?? [])
    .map((part) => part.text?.trim())
    .filter((value): value is string => Boolean(value))
    .join("\n");

  return text || null;
}

function buildPrompt({ sample, shortlists, ocrText }: GeminiMatchRequest): string {
  const shortlistLines = Object.entries(shortlists)
    .map(([brand, matches]) => {
      const serialized = matches.map((match, index) => ({
        rank: index + 1,
        number: match.color.number,
        name: match.color.name,
        family: match.color.family,
        hex: `#${match.color.hex}`,
        deterministicConfidence: match.confidence,
        deltaE: Number(match.deltaE.toFixed(2)),
      }));

      return `${brand}: ${JSON.stringify(serialized)}`;
    })
    .join("\n");

  return [
    "You are matching a photographed paint sample to two paint catalogs.",
    "Use the corrected cropped sample image plus the deterministic shortlist below.",
    "Prioritize visible paint-card text, labels, or OCR clues when present.",
    "Otherwise choose the closest-looking paint chip under real-world lighting.",
    "Return strict JSON with this shape only:",
    '{"warnings":["..."],"matches":[{"brand":"benjamin_moore","number":"HC-114","confidence":96,"rationale":"..."},{"brand":"sherwin_williams","number":"SW 6204","confidence":93,"rationale":"..."}]}',
    "Return exactly one match for benjamin_moore and one for sherwin_williams.",
    ocrText?.trim() ? `OCR text from the crop: ${JSON.stringify(ocrText.trim().slice(0, 500))}` : null,
    `Sample stats: ${JSON.stringify({
      sampleHex: `#${sample.sampleHex}`,
      quality: sample.quality,
      spread: Number(sample.spread.toFixed(2)),
      warnings: sample.warnings,
      diagnostics: sample.diagnostics,
    })}`,
    `Shortlists:\n${shortlistLines}`,
  ].filter(Boolean).join("\n");
}

function parseAssessment(text: string): GeminiColorMatchAssessment | null {
  try {
    const parsed = JSON.parse(text) as GeminiColorMatchAssessment;
    if (!parsed || typeof parsed !== "object" || !Array.isArray(parsed.matches)) {
      return null;
    }

    const matches = parsed.matches
      .filter((match): match is GeminiColorMatchSelection => {
        return Boolean(
          match &&
          (match.brand === "benjamin_moore" || match.brand === "sherwin_williams") &&
          typeof match.number === "string" &&
          typeof match.confidence === "number" &&
          typeof match.rationale === "string"
        );
      })
      .map((match) => ({
        ...match,
        confidence: Math.max(70, Math.min(99, Math.round(match.confidence))),
        rationale: match.rationale.trim().slice(0, 220),
      }));

    const warnings = Array.isArray(parsed.warnings)
      ? parsed.warnings
          .filter((warning): warning is string => typeof warning === "string")
          .map((warning) => warning.trim())
          .filter(Boolean)
          .slice(0, 4)
      : [];

    return { warnings, matches };
  } catch {
    return null;
  }
}

async function rerankWithGemini(model: string, request: GeminiMatchRequest): Promise<GeminiColorMatchAssessment | null> {
  const ai = getGoogleClient();
  if (!ai) return null;

  const response = await withTimeout(
    ai.models.generateContent({
      model,
      contents: [
        {
          role: "user",
          parts: [
            { text: buildPrompt(request) },
            {
              inlineData: {
                mimeType: request.imageMimeType,
                data: request.imageBase64,
              },
            },
          ],
        },
      ],
      config: {
        responseMimeType: "application/json",
      },
    }),
    REQUEST_TIMEOUT_MS
  );

  const text = extractTextFromGoogleResponse(response);
  return text ? parseAssessment(text) : null;
}

async function rerankWithOpenAI(model: string, request: GeminiMatchRequest): Promise<GeminiColorMatchAssessment | null> {
  const apiKey = process.env.OPENAI_API_KEY?.trim();
  if (!apiKey) return null;

  const response = await withTimeout(
    fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        input: [
          {
            role: "user",
            content: [
              { type: "input_text", text: buildPrompt(request) },
              {
                type: "input_image",
                image_url: `data:${request.imageMimeType};base64,${request.imageBase64}`,
                detail: "high",
              },
            ],
          },
        ],
      }),
    }).then(async (result) => {
      if (!result.ok) {
        throw new Error(`OpenAI rerank failed with ${result.status}: ${await result.text()}`);
      }
      return result.json();
    }),
    REQUEST_TIMEOUT_MS
  );

  const text = extractTextFromOpenAIResponse(response);
  return text ? parseAssessment(text) : null;
}

function isOpenAIModel(model: string): boolean {
  const normalized = model.toLowerCase();
  return normalized.startsWith("gpt-") || normalized.startsWith("o");
}

export async function rerankColorMatchesWithGemini(
  request: GeminiMatchRequest
): Promise<GeminiColorMatchAssessment | null> {
  const models = configuredModelIds();

  for (const model of models) {
    try {
      const assessment = isOpenAIModel(model)
        ? await rerankWithOpenAI(model, request)
        : await rerankWithGemini(model, request);
      if (assessment) return assessment;
    } catch (error) {
      console.error("Color match rerank failed:", model, error);
    }
  }

  return null;
}
