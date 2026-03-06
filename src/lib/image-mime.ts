const SUPPORTED_IMAGE_MIME_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/heic",
  "image/heif",
]);

const MIME_TO_EXTENSION: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
  "image/heic": "heic",
  "image/heif": "heif",
};

export function normalizeImageMimeType(mimeType?: string | null): string | null {
  if (!mimeType) return null;
  const normalized = mimeType.split(";")[0]?.trim().toLowerCase();
  if (!normalized) return null;
  return normalized;
}

export function isSupportedImageMimeType(mimeType?: string | null): boolean {
  const normalized = normalizeImageMimeType(mimeType);
  return normalized ? SUPPORTED_IMAGE_MIME_TYPES.has(normalized) : false;
}

export function extensionForMimeType(mimeType?: string | null): string {
  const normalized = normalizeImageMimeType(mimeType);
  if (!normalized) return "jpg";
  return MIME_TO_EXTENSION[normalized] ?? "jpg";
}
