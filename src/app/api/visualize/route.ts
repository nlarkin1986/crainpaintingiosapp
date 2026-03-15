import { after, NextRequest, NextResponse } from "next/server";
import { normalizeCustomInstruction } from "@/lib/prompt";
import {
  uploadVisualizationAsset,
} from "@/lib/visualization-assets";
import {
  createVisualizationDerivatives,
  type EncodedVisualizationImage,
  normalizeUploadedVisualizationImage,
  VisualizationImageError,
} from "@/lib/visualization-images";
import {
  processVisualizationJob,
  VISUALIZATION_PROMPT_VERSION,
} from "@/lib/visualization-jobs";
import {
  createVisualizationJob,
  getVisualizationByClientRequest,
  saveOriginalVisualizationAssets,
  upsertInstallation,
  VisualizationRateLimitError,
} from "@/lib/visualization-store";
import { hasDatabaseConnectionString } from "@/lib/postgres";
import type { MediaVariant, VisualizationRow } from "@/types/visualization";
import {
  isSupportedImageMimeType,
  normalizeImageMimeType,
} from "@/lib/image-mime";

export const runtime = "nodejs";
export const maxDuration = 60;

const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const HEX_PATTERN = /^[0-9a-f]{6}$/i;

function readClientIp(request: NextRequest): string | null {
  const forwarded = request.headers.get("x-forwarded-for");
  const realIp = request.headers.get("x-real-ip");
  return forwarded?.split(",")[0]?.trim() || realIp || null;
}

function toIsoString(value: string | Date | null | undefined): string | null {
  if (!value) {
    return null;
  }
  return new Date(value).toISOString();
}

function startResponse(
  visualization: VisualizationRow,
  message: string
) {
  return {
    visualizationId: visualization.id,
    shareId: visualization.share_token,
    status: visualization.status,
    message,
    retryAfterSeconds: 2,
    createdAt: toIsoString(visualization.created_at),
  };
}

async function uploadOriginalAssetSet(input: {
  visualizationId: string;
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
      role: "original",
      variant,
      buffer: asset.buffer,
      mimeType: asset.mimeType,
      width: asset.width,
      height: asset.height,
    });
  }

  return uploaded;
}

export async function POST(request: NextRequest) {
  try {
    if (
      !hasDatabaseConnectionString() ||
      !process.env.BLOB_READ_WRITE_TOKEN ||
      !process.env.GEMINI_API_KEY
    ) {
      return NextResponse.json(
        { error: "The preview backend is not fully configured.", code: "INTERNAL_ERROR" },
        { status: 500 }
      );
    }

    const installationId = request.headers.get("x-installation-id");
    const appVersion = request.headers.get("x-app-version");
    if (!installationId || !UUID_PATTERN.test(installationId)) {
      return NextResponse.json(
        {
          error: "Missing or invalid X-Installation-ID header.",
          code: "INVALID_INPUT",
        },
        { status: 400 }
      );
    }

    const formData = await request.formData();
    const image = formData.get("image");
    const colorName = formData.get("colorName");
    const colorHex = formData.get("colorHex");
    const colorNumber = formData.get("colorNumber");
    const surface = formData.get("surface");
    const clientRequestId = formData.get("clientRequestId");
    const brand = (formData.get("brand") as string | null) ?? "benjamin_moore";
    const customInstruction = normalizeCustomInstruction(
      formData.get("customInstruction") as string | null
    );

    if (!(image instanceof File)) {
      return NextResponse.json(
        { error: "Missing required image upload.", code: "INVALID_INPUT" },
        { status: 400 }
      );
    }

    if (
      typeof colorName !== "string" ||
      typeof colorHex !== "string" ||
      typeof colorNumber !== "string" ||
      typeof surface !== "string" ||
      typeof clientRequestId !== "string"
    ) {
      return NextResponse.json(
        {
          error:
            "Missing required fields: colorName, colorHex, colorNumber, surface, clientRequestId.",
          code: "INVALID_INPUT",
        },
        { status: 400 }
      );
    }

    if (!UUID_PATTERN.test(clientRequestId)) {
      return NextResponse.json(
        { error: "clientRequestId must be a valid UUID.", code: "INVALID_INPUT" },
        { status: 400 }
      );
    }

    if (!HEX_PATTERN.test(colorHex)) {
      return NextResponse.json(
        { error: "colorHex must be a 6-character hex value.", code: "INVALID_INPUT" },
        { status: 400 }
      );
    }

    if (surface === "custom" && !customInstruction) {
      return NextResponse.json(
        {
          error: "Please describe the custom surface you want to repaint.",
          code: "INVALID_INPUT",
        },
        { status: 400 }
      );
    }

    const inputMimeType = normalizeImageMimeType(image.type);
    if (!inputMimeType || !isSupportedImageMimeType(inputMimeType)) {
      return NextResponse.json(
        {
          error: "Unsupported image type. Please upload JPEG, PNG, WEBP, HEIC, or HEIF.",
          code: "UNSUPPORTED_IMAGE",
        },
        { status: 415 }
      );
    }

    await upsertInstallation({ installationId, appVersion });

    const existing = await getVisualizationByClientRequest({
      installationId,
      clientRequestId,
    });
    if (existing) {
      if (existing.status === "queued" || existing.status === "processing") {
        after(() => processVisualizationJob(existing.id));
      }

      return NextResponse.json(
        startResponse(existing, existing.status === "completed" ? "Preview already ready." : "Preview queued."),
        { status: 202 }
      );
    }

    const imageBuffer = Buffer.from(await image.arrayBuffer());
    const canonicalOriginal = await normalizeUploadedVisualizationImage(imageBuffer);
    const originalDerivatives = await createVisualizationDerivatives(canonicalOriginal);
    const requestIp = readClientIp(request);

    const { visualization, isNew } = await createVisualizationJob({
      installationId,
      clientRequestId,
      brand,
      colorName,
      colorNumber,
      colorHex: colorHex.toUpperCase(),
      surface,
      customInstruction,
      promptVersion: VISUALIZATION_PROMPT_VERSION,
      requestIp,
    });

    if (!isNew) {
      if (visualization.status === "queued" || visualization.status === "processing") {
        after(() => processVisualizationJob(visualization.id));
      }
      return NextResponse.json(startResponse(visualization, "Preview queued."), {
        status: 202,
      });
    }

    const uploadedOriginalAssets = await uploadOriginalAssetSet({
      visualizationId: visualization.id,
      derivatives: originalDerivatives,
    });

    await saveOriginalVisualizationAssets({
      visualizationId: visualization.id,
      assets: uploadedOriginalAssets,
      canonicalWidth: canonicalOriginal.width,
      canonicalHeight: canonicalOriginal.height,
    });

    after(() => processVisualizationJob(visualization.id));

    return NextResponse.json(startResponse(visualization, "Preview queued."), {
      status: 202,
    });
  } catch (error) {
    if (error instanceof VisualizationRateLimitError) {
      return NextResponse.json(
        {
          error: error.message,
          code: error.code,
          retryAfterSeconds: error.retryAfterSeconds,
        },
        {
          status: error.status,
          headers: {
            "Retry-After": String(error.retryAfterSeconds),
          },
        }
      );
    }

    if (error instanceof VisualizationImageError) {
      return NextResponse.json(
        {
          error: error.message,
          code: error.code,
        },
        { status: error.status }
      );
    }

    console.error("Visualize API error:", error);
    return NextResponse.json(
      {
        error: "An unexpected error occurred while queuing this preview.",
        code: "INTERNAL_ERROR",
      },
      { status: 500 }
    );
  }
}
