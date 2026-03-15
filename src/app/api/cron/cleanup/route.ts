import { del } from "@vercel/blob";
import { NextRequest, NextResponse } from "next/server";
import {
  listExpiredVisualizations,
  markVisualizationsExpired,
} from "@/lib/visualization-store";

export const runtime = "nodejs";
export const maxDuration = 30;

function blobToken(): string | null {
  return process.env.BLOB_READ_WRITE_TOKEN ?? null;
}

export async function GET(request: NextRequest) {
  const authHeader = request.headers.get("authorization");
  if (authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const token = blobToken();
  if (!token) {
    return NextResponse.json(
      { error: "BLOB_READ_WRITE_TOKEN is not configured" },
      { status: 500 }
    );
  }

  const expiredAssets = await listExpiredVisualizations(500);
  if (expiredAssets.length === 0) {
    return NextResponse.json({
      deleted: 0,
      expiredVisualizations: 0,
      timestamp: new Date().toISOString(),
    });
  }

  const storageKeys = [...new Set(expiredAssets.map((asset) => asset.storage_key))];
  const visualizationIds = [...new Set(expiredAssets.map((asset) => asset.id))];

  try {
    await del(storageKeys, { token });
  } catch (error) {
    console.error("Failed to delete expired visualization blobs:", error);
    return NextResponse.json(
      { error: "Failed to delete expired visualization assets" },
      { status: 500 }
    );
  }

  await markVisualizationsExpired(visualizationIds);

  return NextResponse.json({
    deleted: storageKeys.length,
    expiredVisualizations: visualizationIds.length,
    timestamp: new Date().toISOString(),
  });
}
