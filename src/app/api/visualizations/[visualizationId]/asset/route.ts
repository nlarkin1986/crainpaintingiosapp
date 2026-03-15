import { NextRequest, NextResponse } from "next/server";
import {
  fetchVisualizationAssetBuffer,
  verifySignedVisualizationAssetUrl,
} from "@/lib/visualization-assets";
import { getVisualizationById, listVisualizationAssets } from "@/lib/visualization-store";
import {
  MEDIA_ROLES,
  MEDIA_VARIANTS,
  type MediaAssetRow,
  type MediaRole,
  type MediaVariant,
} from "@/types/visualization";

export const runtime = "nodejs";
export const maxDuration = 60;

function isMediaRole(value: string | null): value is MediaRole {
  return !!value && MEDIA_ROLES.includes(value as MediaRole);
}

function isMediaVariant(value: string | null): value is MediaVariant {
  return !!value && MEDIA_VARIANTS.includes(value as MediaVariant);
}

function findAsset(
  assets: MediaAssetRow[],
  role: MediaRole,
  variant: MediaVariant
): MediaAssetRow | null {
  return (
    assets.find((asset) => asset.role === role && asset.variant === variant) ?? null
  );
}

export async function GET(
  request: NextRequest,
  context: { params: Promise<{ visualizationId: string }> }
) {
  const { visualizationId } = await context.params;
  const role = request.nextUrl.searchParams.get("role");
  const variant = request.nextUrl.searchParams.get("variant");
  const exp = request.nextUrl.searchParams.get("exp");
  const sig = request.nextUrl.searchParams.get("sig");

  if (!isMediaRole(role) || !isMediaVariant(variant)) {
    return NextResponse.json(
      { error: "Invalid asset selector.", code: "INVALID_INPUT" },
      { status: 400 }
    );
  }

  if (
    !verifySignedVisualizationAssetUrl({
      visualizationId,
      role,
      variant,
      exp,
      sig,
    })
  ) {
    return NextResponse.json(
      { error: "Asset URL is invalid or expired.", code: "UNAUTHORIZED" },
      { status: 401 }
    );
  }

  const visualization = await getVisualizationById(visualizationId);
  if (!visualization || visualization.status !== "completed") {
    return NextResponse.json(
      { error: "Preview asset not found.", code: "NOT_FOUND" },
      { status: 404 }
    );
  }

  const assets = await listVisualizationAssets(visualizationId);
  const asset = findAsset(assets, role, variant);
  if (!asset) {
    return NextResponse.json(
      { error: "Preview asset not found.", code: "NOT_FOUND" },
      { status: 404 }
    );
  }

  try {
    const upstream = await fetchVisualizationAssetBuffer(asset.storage_key);
    const arrayBuffer = await upstream.arrayBuffer();
    return new NextResponse(arrayBuffer, {
      status: 200,
      headers: {
        "Cache-Control": "private, max-age=300",
        "Content-Disposition": `inline; filename="${visualizationId}-${role}-${variant}.jpg"`,
        "Content-Length": String(asset.file_size_bytes),
        "Content-Type": asset.mime_type,
      },
    });
  } catch (error) {
    console.error("Failed to proxy visualization asset:", error);
    return NextResponse.json(
      { error: "Unable to load preview asset.", code: "INTERNAL_ERROR" },
      { status: 500 }
    );
  }
}
