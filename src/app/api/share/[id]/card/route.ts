import { ImageResponse } from "next/og";
import { NextResponse } from "next/server";
import {
  getDesignCardFilename,
  getImmutableAssetHeaders,
  getShareVisualizationData,
} from "@/lib/share";
import {
  DESIGN_CARD_HEIGHT,
  DESIGN_CARD_WIDTH,
  renderShareDesignCard,
} from "@/lib/share-design-card";

export const runtime = "nodejs";

export async function GET(
  _request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const data = await getShareVisualizationData(id);

  if (!data) {
    return new NextResponse("Not found", { status: 404 });
  }

  try {
    const image = new ImageResponse(renderShareDesignCard(data), {
      width: DESIGN_CARD_WIDTH,
      height: DESIGN_CARD_HEIGHT,
    });

    const pngBuffer = Buffer.from(await image.arrayBuffer());
    const sharpModule = await import("sharp");
    const sharp = "default" in sharpModule ? sharpModule.default : sharpModule;
    const jpegBuffer = await sharp(pngBuffer)
      .jpeg({ quality: 88, mozjpeg: true })
      .toBuffer();

    const filename = getDesignCardFilename({
      brand: data.brand,
      colorNumber: data.colorNumber,
      surface: data.surface,
    });

    return new Response(new Uint8Array(jpegBuffer), {
      headers: getImmutableAssetHeaders(filename, "image/jpeg"),
    });
  } catch (error) {
    console.error("Failed to render share design card:", error);
    return new NextResponse("Failed to render design card", { status: 500 });
  }
}
