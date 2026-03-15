import { NextRequest, NextResponse } from "next/server";
import { processVisualizationJob } from "@/lib/visualization-jobs";
import { listQueuedVisualizationIds } from "@/lib/visualization-store";

export const runtime = "nodejs";
export const maxDuration = 60;

export async function POST(request: NextRequest) {
  const authHeader = request.headers.get("authorization");
  if (authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json().catch(() => ({}));
  const visualizationId =
    typeof body?.visualizationId === "string" ? body.visualizationId : null;

  if (visualizationId) {
    const result = await processVisualizationJob(visualizationId);
    return NextResponse.json({ processed: [visualizationId], result });
  }

  const queuedIds = await listQueuedVisualizationIds(3);
  const processed = [];

  for (const id of queuedIds) {
    processed.push({
      visualizationId: id,
      result: await processVisualizationJob(id),
    });
  }

  return NextResponse.json({
    processed,
    queued: queuedIds.length,
  });
}
