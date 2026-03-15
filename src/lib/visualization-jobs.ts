import { buildPaintPrompt } from "@/lib/prompt";
import {
  fetchVisualizationAssetBuffer,
  uploadVisualizationAsset,
} from "@/lib/visualization-assets";
import { GeminiGenerationError, generatePaintVisualizationDetailed } from "@/lib/gemini";
import {
  createVisualizationDerivatives,
  type EncodedVisualizationImage,
  normalizeGeneratedVisualizationImage,
  VisualizationImageError,
} from "@/lib/visualization-images";
import { MAX_IMAGE_UPLOAD_ERROR_MESSAGE } from "@/lib/image-upload-limits";
import {
  claimVisualizationForProcessing,
  completeVisualization,
  failVisualization,
  finishVisualizationAttempt,
  getCanonicalOriginalAsset,
  startVisualizationAttempt,
} from "@/lib/visualization-store";
import { hasDatabaseConnectionString } from "@/lib/postgres";
import type { MediaVariant } from "@/types/visualization";

const VISUALIZATION_PROVIDER = "gemini";
const DEFAULT_MODEL = "gemini-3.1-flash-image-preview";
export const VISUALIZATION_PROMPT_VERSION =
  process.env.VISUALIZATION_PROMPT_VERSION?.trim() || "ios-visualizer-v1";

interface ProcessingError {
  code: string;
  clientMessage: string;
  attemptMessage: string;
}

function configuredGeminiModel(): string {
  return process.env.GEMINI_IMAGE_MODEL?.trim() || DEFAULT_MODEL;
}

function ensureVisualizationBackendConfigured() {
  if (!hasDatabaseConnectionString()) {
    throw new Error("Database connection string is not configured");
  }
  if (!process.env.BLOB_READ_WRITE_TOKEN) {
    throw new Error("BLOB_READ_WRITE_TOKEN is not configured");
  }
  if (!process.env.GEMINI_API_KEY) {
    throw new Error("GEMINI_API_KEY is not configured");
  }
}

function mapProcessingError(error: unknown): ProcessingError {
  if (error instanceof VisualizationImageError) {
    switch (error.code) {
      case "UNSUPPORTED_IMAGE":
        return {
          code: "UNSUPPORTED_IMAGE",
          clientMessage:
            "Unsupported or unreadable image. Please upload JPEG, PNG, WEBP, HEIC, or HEIF.",
          attemptMessage: error.message,
        };
      case "IMAGE_TOO_LARGE":
        return {
          code: "IMAGE_TOO_LARGE",
          clientMessage: MAX_IMAGE_UPLOAD_ERROR_MESSAGE,
          attemptMessage: error.message,
        };
      case "INVALID_OUTPUT":
        return {
          code: "INVALID_OUTPUT",
          clientMessage:
            "We couldn't generate a stable preview for this room. Please try again.",
          attemptMessage: error.message,
        };
      default:
        return {
          code: "INVALID_INPUT",
          clientMessage:
            "We couldn't process that image. Please try another photo.",
          attemptMessage: error.message,
        };
    }
  }

  if (error instanceof GeminiGenerationError) {
    switch (error.code) {
      case "TIMEOUT":
        return {
          code: "UPSTREAM_TIMEOUT",
          clientMessage:
            "Preview generation timed out. Please try again in a moment.",
          attemptMessage: error.message,
        };
      case "INVALID_INPUT":
      case "NO_IMAGE":
        return {
          code: "INVALID_INPUT",
          clientMessage:
            "We couldn't process that photo for preview generation. Please try another image.",
          attemptMessage: error.message,
        };
      default:
        return {
          code: "UPSTREAM_UNAVAILABLE",
          clientMessage:
            "The preview service is temporarily unavailable. Please try again shortly.",
          attemptMessage: error.message,
        };
    }
  }

  if (error instanceof Error) {
    return {
      code: "INTERNAL_ERROR",
      clientMessage:
        "We couldn't generate this preview right now. Please try again.",
      attemptMessage: error.message,
    };
  }

  return {
    code: "INTERNAL_ERROR",
    clientMessage: "We couldn't generate this preview right now. Please try again.",
    attemptMessage: "Unknown visualization processing error",
  };
}

async function uploadAssetSet(input: {
  visualizationId: string;
  role: "result";
  derivatives: Record<MediaVariant, EncodedVisualizationImage>;
}) {
  const uploaded = {} as Record<
    MediaVariant,
    Awaited<ReturnType<typeof uploadVisualizationAsset>>
  >;

  for (const [variant, asset] of Object.entries(input.derivatives) as Array<
    [MediaVariant, EncodedVisualizationImage]
  >) {
    uploaded[variant] = await uploadVisualizationAsset({
      visualizationId: input.visualizationId,
      role: input.role,
      variant,
      buffer: asset.buffer,
      mimeType: asset.mimeType,
      width: asset.width,
      height: asset.height,
    });
  }

  return uploaded;
}

export async function processVisualizationJob(visualizationId: string): Promise<{
  status: "completed" | "failed" | "skipped";
  code?: string;
}> {
  ensureVisualizationBackendConfigured();

  const visualization = await claimVisualizationForProcessing(visualizationId);
  if (!visualization) {
    return { status: "skipped" };
  }

  try {
    const originalAsset = await getCanonicalOriginalAsset(visualizationId);
    if (!originalAsset) {
      throw new Error("Original canonical asset is missing");
    }

    const originalResponse = await fetchVisualizationAssetBuffer(originalAsset.storage_key);
    const originalBuffer = Buffer.from(await originalResponse.arrayBuffer());
    const prompt = buildPaintPrompt({
      surface: visualization.surface,
      colorName: visualization.color_name,
      colorNumber: visualization.color_number,
      colorHex: visualization.color_hex,
      brand: visualization.brand,
      customInstruction: visualization.custom_instruction ?? undefined,
    });

    const expectedWidth = visualization.width ?? originalAsset.width;
    const expectedHeight = visualization.height ?? originalAsset.height;

    let lastError: unknown = null;

    for (let generationAttempt = 0; generationAttempt < 2; generationAttempt++) {
      const attempt = await startVisualizationAttempt({
        visualizationId,
        provider: VISUALIZATION_PROVIDER,
        model: configuredGeminiModel(),
      });
      const startedAt = Date.now();

      try {
        const generated = await generatePaintVisualizationDetailed(
          prompt,
          originalBuffer.toString("base64"),
          originalAsset.mime_type
        );

        const canonicalResult = await normalizeGeneratedVisualizationImage(
          Buffer.from(generated.data, "base64"),
          { width: expectedWidth, height: expectedHeight }
        );
        const resultDerivatives = await createVisualizationDerivatives(canonicalResult);
        const uploadedResultAssets = await uploadAssetSet({
          visualizationId,
          role: "result",
          derivatives: resultDerivatives,
        });

        await finishVisualizationAttempt({
          attemptId: attempt.id,
          status: "succeeded",
          latencyMs: Date.now() - startedAt,
          model: generated.modelId,
        });

        await completeVisualization({
          visualizationId,
          provider: VISUALIZATION_PROVIDER,
          model: generated.modelId,
          resultAssets: uploadedResultAssets,
        });

        return { status: "completed" };
      } catch (error) {
        lastError = error;
        const mapped = mapProcessingError(error);
        await finishVisualizationAttempt({
          attemptId: attempt.id,
          status: "failed",
          latencyMs: Date.now() - startedAt,
          errorCode: mapped.code,
          errorMessage: mapped.attemptMessage,
        });

        if (mapped.code === "INVALID_OUTPUT" && generationAttempt === 0) {
          continue;
        }

        throw error;
      }
    }

    throw lastError ?? new Error("Visualization generation failed");
  } catch (error) {
    const mapped = mapProcessingError(error);
    await failVisualization({
      visualizationId,
      errorCode: mapped.code,
      errorMessage: mapped.clientMessage,
    });
    return { status: "failed", code: mapped.code };
  }
}
