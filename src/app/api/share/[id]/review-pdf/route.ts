import { NextRequest, NextResponse } from "next/server";
import {
  getImmutableAssetHeaders,
  getReviewSheetFilename,
  getShareUrls,
  getShareVisualizationData,
} from "@/lib/share";
import { renderShareReviewPdfToBuffer } from "@/lib/share-review-pdf";

export const runtime = "nodejs";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const data = await getShareVisualizationData(id);

  if (!data) {
    return new NextResponse("Not found", { status: 404 });
  }

  try {
    const { shareUrl } = getShareUrls(id, request.nextUrl.origin);
    const pdfBuffer = await renderShareReviewPdfToBuffer(data, shareUrl);
    const filename = getReviewSheetFilename({
      brand: data.brand,
      colorNumber: data.colorNumber,
      surface: data.surface,
    });

    return new Response(new Uint8Array(pdfBuffer), {
      headers: getImmutableAssetHeaders(filename, "application/pdf"),
    });
  } catch (error) {
    console.error("Failed to render share review PDF:", error);
    return new NextResponse("Failed to render review PDF", { status: 500 });
  }
}
