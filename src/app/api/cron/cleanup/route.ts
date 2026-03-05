import { list, del } from "@vercel/blob";

const blobToken = process.env.Crain_READ_WRITE_TOKEN;
import { NextRequest, NextResponse } from "next/server";

export async function GET(request: NextRequest) {
  // Verify cron secret
  const authHeader = request.headers.get("authorization");
  if (authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const cutoff = Date.now() - 24 * 60 * 60 * 1000;
  let deleted = 0;
  let cursor: string | undefined;

  do {
    const result = await list({ cursor, token: blobToken });
    const expired = result.blobs.filter(
      (blob) => new Date(blob.uploadedAt).getTime() < cutoff
    );

    if (expired.length > 0) {
      await del(expired.map((b) => b.url), { token: blobToken });
      deleted += expired.length;
    }

    cursor = result.hasMore ? result.cursor : undefined;
  } while (cursor);

  return NextResponse.json({ deleted, timestamp: new Date().toISOString() });
}
