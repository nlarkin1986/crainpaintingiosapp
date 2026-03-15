import { createHmac, timingSafeEqual } from "crypto";
import { put } from "@vercel/blob";
import type { MediaRole, MediaVariant } from "@/types/visualization";

const ASSET_URL_TTL_SECONDS = 15 * 60;

export interface UploadedVisualizationAsset {
  storageKey: string;
  mimeType: string;
  fileSizeBytes: number;
  width: number;
  height: number;
}

function blobToken(): string {
  const token = process.env.BLOB_READ_WRITE_TOKEN;
  if (!token) {
    throw new Error("BLOB_READ_WRITE_TOKEN is not configured");
  }
  return token;
}

function assetSigningSecret(): string {
  return (
    process.env.VISUALIZATION_ASSET_SIGNING_SECRET ||
    process.env.SESSION_SECRET ||
    process.env.BLOB_READ_WRITE_TOKEN ||
    ""
  );
}

function assetSignaturePayload(input: {
  visualizationId: string;
  role: MediaRole;
  variant: MediaVariant;
  exp: number;
}): string {
  return `${input.visualizationId}:${input.role}:${input.variant}:${input.exp}`;
}

function signAssetRequest(input: {
  visualizationId: string;
  role: MediaRole;
  variant: MediaVariant;
  exp: number;
}): string {
  const secret = assetSigningSecret();
  if (!secret) {
    throw new Error("No visualization asset signing secret is configured");
  }

  return createHmac("sha256", secret)
    .update(assetSignaturePayload(input))
    .digest("hex");
}

export async function uploadVisualizationAsset(input: {
  visualizationId: string;
  role: MediaRole;
  variant: MediaVariant;
  buffer: Buffer;
  mimeType: string;
  width: number;
  height: number;
}): Promise<UploadedVisualizationAsset> {
  const pathname = [
    "visualizations",
    input.visualizationId,
    `${input.role}-${input.variant}-${Date.now()}.jpg`,
  ].join("/");

  const uploaded = await put(pathname, input.buffer, {
    access: "public",
    addRandomSuffix: true,
    contentType: input.mimeType,
    token: blobToken(),
  });

  return {
    storageKey: uploaded.url,
    mimeType: input.mimeType,
    fileSizeBytes: input.buffer.byteLength,
    width: input.width,
    height: input.height,
  };
}

export function buildSignedVisualizationAssetUrl(input: {
  origin: string;
  visualizationId: string;
  role: MediaRole;
  variant: MediaVariant;
}): string {
  const exp = Math.floor(Date.now() / 1000) + ASSET_URL_TTL_SECONDS;
  const sig = signAssetRequest({
    visualizationId: input.visualizationId,
    role: input.role,
    variant: input.variant,
    exp,
  });

  const url = new URL(`/api/visualizations/${input.visualizationId}/asset`, input.origin);
  url.searchParams.set("role", input.role);
  url.searchParams.set("variant", input.variant);
  url.searchParams.set("exp", String(exp));
  url.searchParams.set("sig", sig);
  return url.toString();
}

export function verifySignedVisualizationAssetUrl(input: {
  visualizationId: string;
  role: MediaRole;
  variant: MediaVariant;
  exp: string | null;
  sig: string | null;
}): boolean {
  const exp = Number(input.exp);
  const providedSig = input.sig;
  if (!providedSig || !Number.isFinite(exp)) {
    return false;
  }

  if (Math.floor(Date.now() / 1000) > exp) {
    return false;
  }

  const expectedSig = signAssetRequest({
    visualizationId: input.visualizationId,
    role: input.role,
    variant: input.variant,
    exp,
  });

  const expectedBuffer = Buffer.from(expectedSig);
  const providedBuffer = Buffer.from(providedSig);
  if (expectedBuffer.length !== providedBuffer.length) {
    return false;
  }

  return timingSafeEqual(expectedBuffer, providedBuffer);
}

export async function fetchVisualizationAssetBuffer(storageKey: string): Promise<Response> {
  const response = await fetch(storageKey, { cache: "no-store" });
  if (!response.ok) {
    throw new Error(`Failed to fetch blob asset: ${response.status}`);
  }
  return response;
}
