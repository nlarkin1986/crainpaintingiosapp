import { NextRequest, NextResponse } from "next/server";
import { normalizeDeviceId, upsertStoreKitEntitlement, getVisualizationUsage } from "@/lib/visualization-meter";
import { StoreKitVerificationError } from "@/lib/storekit";

export async function POST(request: NextRequest) {
  try {
    const body = await request.json() as {
      deviceId?: string;
      signedTransactionJWS?: string;
    };

    const deviceId = normalizeDeviceId(body.deviceId ?? null);
    if (!deviceId || !body.signedTransactionJWS) {
      return NextResponse.json(
        { error: "Missing required StoreKit verification fields." },
        { status: 400 }
      );
    }

    await upsertStoreKitEntitlement(deviceId, body.signedTransactionJWS);
    const usage = await getVisualizationUsage(deviceId);
    return NextResponse.json({ ok: true, usage });
  } catch (error) {
    console.error("StoreKit verification failed:", error);
    if (error instanceof StoreKitVerificationError) {
      return NextResponse.json(
        { error: "Purchase could not be verified.", code: error.code },
        { status: 400 }
      );
    }

    return NextResponse.json(
      { error: "Purchase verification is temporarily unavailable." },
      { status: 503 }
    );
  }
}
