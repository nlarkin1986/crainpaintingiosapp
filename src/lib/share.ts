import { getBrandLabel } from "@/lib/brands";
import type { ShareVisualizationData } from "@/types/share";

const IMMUTABLE_CACHE_CONTROL = "public, max-age=31536000, immutable";

function normalizeBaseUrl(value?: string | null): string | null {
  if (!value) return null;
  if (value.startsWith("http://") || value.startsWith("https://")) {
    return value.replace(/\/+$/, "");
  }
  return `https://${value}`.replace(/\/+$/, "");
}

function slugifySegment(value: string, maxLength = 40): string {
  const slug = value
    .trim()
    .toLowerCase()
    .replace(/&/g, "and")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");

  return (slug.slice(0, maxLength).replace(/-+$/, "") || "item");
}

export function getAppBaseUrl(origin?: string): string {
  return (
    normalizeBaseUrl(origin) ??
    normalizeBaseUrl(process.env.NEXT_PUBLIC_APP_URL) ??
    normalizeBaseUrl(process.env.VERCEL_URL) ??
    "http://localhost:3000"
  );
}

export function getSharePaths(shareId: string) {
  return {
    sharePath: `/share/${shareId}`,
    cardPath: `/api/share/${shareId}/card`,
    reviewPdfPath: `/api/share/${shareId}/review-pdf`,
  };
}

export function getShareUrls(shareId: string, origin?: string) {
  const baseUrl = getAppBaseUrl(origin);
  const { sharePath, cardPath, reviewPdfPath } = getSharePaths(shareId);

  return {
    shareUrl: `${baseUrl}${sharePath}`,
    cardUrl: `${baseUrl}${cardPath}`,
    reviewPdfUrl: `${baseUrl}${reviewPdfPath}`,
  };
}

export function getShareSurfaceLabel(surface?: string): string {
  const value = surface?.trim();
  if (!value) return "Surface not specified";
  if (value.toLowerCase() === "custom") return "Custom / Other";
  return value;
}

export function getShareHexColor(hex: string): string {
  return hex.startsWith("#") ? hex : `#${hex}`;
}

export function formatShareDate(iso: string): string {
  return new Date(iso).toLocaleDateString("en-US", {
    month: "long",
    day: "numeric",
    year: "numeric",
  });
}

export function getExportFileStem(input: {
  brand?: string;
  colorNumber: string;
  surface: string;
}) {
  const brand = slugifySegment(getBrandLabel(input.brand));
  const colorNumber = slugifySegment(input.colorNumber);
  const surface = slugifySegment(getShareSurfaceLabel(input.surface));

  return `crain-${brand}-${colorNumber}-${surface}`;
}

export function getDesignCardFilename(input: {
  brand?: string;
  colorNumber: string;
  surface: string;
}) {
  return `${getExportFileStem(input)}-design-card.jpg`;
}

export function getReviewSheetFilename(input: {
  brand?: string;
  colorNumber: string;
  surface: string;
}) {
  return `${getExportFileStem(input)}-review-sheet.pdf`;
}

export function getImmutableAssetHeaders(filename: string, contentType: string) {
  return {
    "Cache-Control": IMMUTABLE_CACHE_CONTROL,
    "Content-Disposition": `inline; filename="${filename}"`,
    "Content-Type": contentType,
  };
}

export async function getShareVisualizationData(
  shareId: string
): Promise<ShareVisualizationData | null> {
  const baseUrl = process.env.BLOB_STORE_URL;
  if (!baseUrl) {
    console.error("BLOB_STORE_URL not configured");
    return null;
  }

  try {
    const response = await fetch(`${baseUrl}/shares/${shareId}.json`, {
      next: { revalidate: 0 },
    });

    if (!response.ok) {
      return null;
    }

    return (await response.json()) as ShareVisualizationData;
  } catch (error) {
    console.error("Failed to fetch share data:", error);
    return null;
  }
}
