import { NextRequest, NextResponse } from "next/server";
import { put, type PutCommandOptions } from "@vercel/blob";

const blobToken = process.env.BLOB_READ_WRITE_TOKEN;
import { nanoid } from "nanoid";
import { buildPaintPrompt } from "@/lib/prompt";
import { rateLimit } from "@/lib/rate-limit";
import { generatePaintVisualization } from "@/lib/gemini";

export const maxDuration = 60;

// Vercel serverless body limit is 4.5 MB; keep under that with overhead
const MAX_FILE_SIZE = 4 * 1024 * 1024; // 4 MB

export async function POST(request: NextRequest) {
  try {
    // --- Parse FormData ---
    const formData = await request.formData();
    const image = formData.get("image") as File | null;
    const colorName = formData.get("colorName") as string | null;
    const colorHex = formData.get("colorHex") as string | null;
    const colorNumber = formData.get("colorNumber") as string | null;
    const surface = formData.get("surface") as string | null;
    const customInstruction = formData.get("customInstruction") as string | null;
    const brand = (formData.get("brand") as string | null) ?? "benjamin_moore";

    // --- Validate required fields ---
    if (!image || !colorName || !colorHex || !colorNumber || !surface) {
      return NextResponse.json(
        { error: "Missing required fields: image, colorName, colorHex, colorNumber, surface" },
        { status: 400 }
      );
    }

    // --- Validate file type ---
    if (!image.type.startsWith("image/")) {
      return NextResponse.json(
        { error: "File must be an image" },
        { status: 400 }
      );
    }

    // --- Validate file size ---
    if (image.size > MAX_FILE_SIZE) {
      return NextResponse.json(
        { error: "Image must be 4 MB or smaller" },
        { status: 400 }
      );
    }

    // --- Rate limit ---
    const forwarded = request.headers.get("x-forwarded-for");
    const realIp = request.headers.get("x-real-ip");
    const ip = forwarded?.split(",")[0]?.trim() || realIp || "unknown";

    const { success: allowed, remaining } = rateLimit(ip);
    if (!allowed) {
      return NextResponse.json(
        { error: "Rate limit exceeded. Please try again later." },
        { status: 429, headers: { "X-RateLimit-Remaining": "0" } }
      );
    }

    // --- Upload original image to Vercel Blob ---
    const imageBuffer = Buffer.from(await image.arrayBuffer());
    const ext = image.type.split("/")[1] || "jpg";
    const originalBlob = await put(`originals/${nanoid(10)}.${ext}`, imageBuffer, {
      access: "public",
      contentType: image.type,
      token: blobToken,
    });
    const originalUrl = originalBlob.url;

    // --- Convert image to base64 ---
    const imageBase64 = imageBuffer.toString("base64");

    // --- Build prompt ---
    const prompt = buildPaintPrompt({
      surface,
      colorName,
      colorNumber,
      colorHex,
      brand,
      customInstruction: customInstruction || undefined,
    });

    // --- Call Gemini API ---
    let geminiResult: { data: string; mimeType: string };
    try {
      geminiResult = await generatePaintVisualization(prompt, imageBase64, image.type);
    } catch (err) {
      console.error("Gemini API error:", err);
      return NextResponse.json(
        { error: "Failed to generate visualization. Please try again." },
        { status: 500 }
      );
    }

    // --- Upload result image to Vercel Blob ---
    const resultBuffer = Buffer.from(geminiResult.data, "base64");
    const resultExt = geminiResult.mimeType.split("/")[1] || "png";
    const resultBlob = await put(`results/${nanoid(10)}.${resultExt}`, resultBuffer, {
      access: "public",
      contentType: geminiResult.mimeType,
      token: blobToken,
    });
    const resultUrl = resultBlob.url;

    // --- Generate shareId and store metadata ---
    const shareId = nanoid(10);
    const shareData = {
      originalUrl,
      resultUrl,
      colorName,
      colorNumber,
      colorHex,
      surface,
      createdAt: new Date().toISOString(),
    };

    await put(`shares/${shareId}.json`, JSON.stringify(shareData), {
      access: "public",
      contentType: "application/json",
      token: blobToken,
    });

    // --- Return response ---
    return NextResponse.json(
      { originalUrl, resultUrl, shareId },
      {
        status: 200,
        headers: { "X-RateLimit-Remaining": String(remaining) },
      }
    );
  } catch (err) {
    console.error("Visualize API error:", err);
    return NextResponse.json(
      { error: "An unexpected error occurred. Please try again." },
      { status: 500 }
    );
  }
}
