import { after, NextRequest, NextResponse } from "next/server";
import { buildSignedVisualizationAssetUrl } from "@/lib/visualization-assets";
import { processVisualizationJob } from "@/lib/visualization-jobs";
import {
  getVisualizationForInstallation,
  listVisualizationAssets,
  upsertInstallation,
} from "@/lib/visualization-store";
import type { MediaAssetRow, MediaRole, MediaVariant } from "@/types/visualization";

export const runtime = "nodejs";
export const maxDuration = 60;

const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function toIsoString(value: string | Date | null | undefined): string | null {
  if (!value) {
    return null;
  }
  return new Date(value).toISOString();
}

function assetMapKey(role: MediaRole, variant: MediaVariant) {
  return `${role}:${variant}`;
}

function getAsset(
  assets: Map<string, MediaAssetRow>,
  role: MediaRole,
  variant: MediaVariant
): MediaAssetRow | null {
  return assets.get(assetMapKey(role, variant)) ?? null;
}

export async function GET(
  request: NextRequest,
  context: { params: Promise<{ visualizationId: string }> }
) {
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

  const { visualizationId } = await context.params;
  const visualization = await getVisualizationForInstallation({
    visualizationId,
    installationId,
  });

  if (!visualization) {
    return NextResponse.json(
      { error: "Preview not found.", code: "NOT_FOUND" },
      { status: 404 }
    );
  }

  await upsertInstallation({ installationId, appVersion });

  if (visualization.status === "queued" || visualization.status === "processing") {
    after(() => processVisualizationJob(visualization.id));
  }

  if (visualization.status === "queued") {
    return NextResponse.json({
      visualizationId: visualization.id,
      shareId: visualization.share_token,
      status: visualization.status,
      message: "Preview queued.",
      retryAfterSeconds: 2,
    });
  }

  if (visualization.status === "processing") {
    return NextResponse.json({
      visualizationId: visualization.id,
      shareId: visualization.share_token,
      status: visualization.status,
      message: "Generating preview.",
      retryAfterSeconds: 2,
    });
  }

  if (visualization.status === "failed") {
    return NextResponse.json({
      visualizationId: visualization.id,
      shareId: visualization.share_token,
      status: visualization.status,
      error:
        visualization.error_message ??
        "We couldn't generate this preview. Please try again.",
      code: visualization.error_code ?? "INTERNAL_ERROR",
      retryAfterSeconds:
        visualization.error_code === "UPSTREAM_TIMEOUT" ||
        visualization.error_code === "UPSTREAM_UNAVAILABLE"
          ? 10
          : undefined,
    });
  }

  if (visualization.status === "expired") {
    return NextResponse.json(
      {
        error: "This preview has expired and is no longer available.",
        code: "EXPIRED",
      },
      { status: 410 }
    );
  }

  const assetRows = await listVisualizationAssets(visualization.id);
  const assets = new Map<string, MediaAssetRow>();
  for (const asset of assetRows) {
    assets.set(assetMapKey(asset.role, asset.variant), asset);
  }

  const requiredAssets: Array<[MediaRole, MediaVariant]> = [
    ["original", "job"],
    ["original", "card"],
    ["original", "full"],
    ["result", "job"],
    ["result", "card"],
    ["result", "full"],
  ];

  for (const [role, variant] of requiredAssets) {
    if (!getAsset(assets, role, variant)) {
      return NextResponse.json({
        visualizationId: visualization.id,
        shareId: visualization.share_token,
        status: "processing",
        message: "Preparing preview assets.",
        retryAfterSeconds: 2,
      });
    }
  }

  const origin = request.nextUrl.origin;
  const resultFullAsset = getAsset(assets, "result", "full");

  return NextResponse.json({
    visualizationId: visualization.id,
    shareId: visualization.share_token,
    status: visualization.status,
    width: visualization.width,
    height: visualization.height,
    mimeType: resultFullAsset?.mime_type ?? "image/jpeg",
    originalJobUrl: buildSignedVisualizationAssetUrl({
      origin,
      visualizationId: visualization.id,
      role: "original",
      variant: "job",
    }),
    resultJobUrl: buildSignedVisualizationAssetUrl({
      origin,
      visualizationId: visualization.id,
      role: "result",
      variant: "job",
    }),
    originalCardUrl: buildSignedVisualizationAssetUrl({
      origin,
      visualizationId: visualization.id,
      role: "original",
      variant: "card",
    }),
    resultCardUrl: buildSignedVisualizationAssetUrl({
      origin,
      visualizationId: visualization.id,
      role: "result",
      variant: "card",
    }),
    originalFullUrl: buildSignedVisualizationAssetUrl({
      origin,
      visualizationId: visualization.id,
      role: "original",
      variant: "full",
    }),
    resultFullUrl: buildSignedVisualizationAssetUrl({
      origin,
      visualizationId: visualization.id,
      role: "result",
      variant: "full",
    }),
    createdAt: toIsoString(visualization.created_at),
    completedAt: toIsoString(visualization.completed_at),
  });
}
