import { NextRequest, NextResponse } from "next/server";
import { put } from "@vercel/blob";

const blobToken = process.env.BLOB_READ_WRITE_TOKEN;
import { nanoid } from "nanoid";
import { buildPaintPrompt, normalizeCustomInstruction } from "@/lib/prompt";
import { rateLimit } from "@/lib/rate-limit";
import { generatePaintVisualization, GeminiGenerationError } from "@/lib/gemini";
import {
  assertCanCreateVisualization,
  incrementCompletedVisualization,
  normalizeDeviceId,
  upsertStoreKitEntitlement,
} from "@/lib/visualization-meter";
import { StoreKitVerificationError } from "@/lib/storekit";
import {
  extensionForMimeType,
  isSupportedImageMimeType,
  normalizeImageMimeType,
} from "@/lib/image-mime";

export const maxDuration = 60;

// Vercel serverless body limit is 4.5 MB; keep under that with overhead
const MAX_FILE_SIZE = 4 * 1024 * 1024; // 4 MB

export async function POST(request: NextRequest) {
  try {
    if (!blobToken) {
      return NextResponse.json(
        { error: "Storage is not configured. Please contact support." },
        { status: 500 }
      );
    }

    // --- Parse FormData ---
    const formData = await request.formData();
    const image = formData.get("image") as File | null;
    const colorName = formData.get("colorName") as string | null;
    const colorHex = formData.get("colorHex") as string | null;
    const colorNumber = formData.get("colorNumber") as string | null;
    const surface = formData.get("surface") as string | null;
    const customInstruction = formData.get("customInstruction") as string | null;
    const brand = (formData.get("brand") as string | null) ?? "benjamin_moore";
    const deviceId = normalizeDeviceId(formData.get("deviceId"));
    const signedTransactionJWS = formData.get("signedTransactionJWS") as string | null;
    const normalizedCustomInstruction = normalizeCustomInstruction(customInstruction);

    // --- Validate required fields ---
    if (!image || !colorName || !colorHex || !colorNumber || !surface || !deviceId) {
      return NextResponse.json(
        { error: "Missing required fields: image, colorName, colorHex, colorNumber, surface, deviceId" },
        { status: 400 }
      );
    }

    if (surface === "custom" && !normalizedCustomInstruction) {
      return NextResponse.json(
        { error: "Please describe the custom surface you want to repaint." },
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

    const inputMimeType = normalizeImageMimeType(image.type);
    if (!inputMimeType || !isSupportedImageMimeType(inputMimeType)) {
      return NextResponse.json(
        { error: "Unsupported image type. Please upload JPEG, PNG, WEBP, HEIC, or HEIF." },
        { status: 415 }
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

    // StoreKit entitlements are verified server-side when supplied. If a device
    // has no active entitlement, only successful completed renders count.
    try {
      await upsertStoreKitEntitlement(deviceId, signedTransactionJWS);
    } catch (err) {
      if (err instanceof StoreKitVerificationError) {
        return NextResponse.json(
          { error: "Purchase could not be verified.", code: err.code },
          { status: 402 }
        );
      }
      throw err;
    }

    let usage = await assertCanCreateVisualization(deviceId);

    // --- Upload original image to Vercel Blob ---
    const imageBuffer = Buffer.from(await image.arrayBuffer());
    const ext = extensionForMimeType(inputMimeType);
    const originalBlob = await put(`originals/${nanoid(10)}.${ext}`, imageBuffer, {
      access: "public",
      contentType: inputMimeType,
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
      customInstruction: normalizedCustomInstruction,
    });

    // --- Call Gemini API ---
    let geminiResult: { data: string; mimeType: string };
    try {
      geminiResult = await generatePaintVisualization(prompt, imageBase64, inputMimeType);
    } catch (err) {
      console.error("Gemini API error:", err);
      if (err instanceof GeminiGenerationError) {
        return NextResponse.json(
          { error: err.message, code: err.code },
          { status: err.status }
        );
      }
      return NextResponse.json(
        { error: "Failed to generate visualization. Please try again." },
        { status: 500 }
      );
    }

    // --- Upload result image to Vercel Blob ---
    const resultBuffer = Buffer.from(geminiResult.data, "base64");
    const resultMimeType = normalizeImageMimeType(geminiResult.mimeType) ?? "image/png";
    const resultExt = extensionForMimeType(resultMimeType);
    const resultBlob = await put(`results/${nanoid(10)}.${resultExt}`, resultBuffer, {
      access: "public",
      contentType: resultMimeType,
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
      brand,
      surface,
      createdAt: new Date().toISOString(),
    };

    await put(`shares/${shareId}.json`, JSON.stringify(shareData), {
      access: "public",
      contentType: "application/json",
      token: blobToken,
    });

    usage = await incrementCompletedVisualization(deviceId);

    // --- Return response ---
    return NextResponse.json(
      { originalUrl, resultUrl, shareId, usage },
      {
        status: 200,
        headers: { "X-RateLimit-Remaining": String(remaining) },
      }
    );
  } catch (err) {
    console.error("Visualize API error:", err);
    if (
      err &&
      typeof err === "object" &&
      "code" in err &&
      (err as { code?: string }).code === "FREE_LIMIT_EXCEEDED"
    ) {
      const limited = err as { status?: number; usage?: unknown };
      return NextResponse.json(
        {
          error: "You have used your free AI paint visualizations.",
          code: "FREE_LIMIT_EXCEEDED",
          usage: limited.usage,
        },
        { status: limited.status ?? 402 }
      );
    }

    return NextResponse.json(
      { error: "An unexpected error occurred. Please try again." },
      { status: 500 }
    );
  }
}
