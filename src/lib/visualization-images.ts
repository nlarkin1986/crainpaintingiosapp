import sharp from "sharp";
import type { MediaVariant } from "@/types/visualization";
import {
  MAX_IMAGE_UPLOAD_BYTES,
  MAX_IMAGE_UPLOAD_ERROR_MESSAGE,
} from "@/lib/image-upload-limits";

const MIN_IMAGE_DIMENSION = 512;
const MAX_INPUT_LONG_EDGE = 6_000;
const FULL_LONG_EDGE = 2_048;
const CARD_LONG_EDGE = 1_280;
const JOB_LONG_EDGE = 640;
const CANONICAL_MIME_TYPE = "image/jpeg";
const CANONICAL_QUALITY = 88;

export class VisualizationImageError extends Error {
  code: string;
  status: number;

  constructor(message: string, options: { code: string; status?: number }) {
    super(message);
    this.name = "VisualizationImageError";
    this.code = options.code;
    this.status = options.status ?? 400;
  }
}

export interface EncodedVisualizationImage {
  buffer: Buffer;
  mimeType: string;
  width: number;
  height: number;
  fileSizeBytes: number;
}

export interface CanonicalDimensions {
  width: number;
  height: number;
}

type DerivativeConfig = Record<MediaVariant, { longEdge: number; quality: number } | null>;

const DERIVATIVE_CONFIG: DerivativeConfig = {
  canonical: null,
  job: { longEdge: JOB_LONG_EDGE, quality: 78 },
  card: { longEdge: CARD_LONG_EDGE, quality: 82 },
  full: { longEdge: FULL_LONG_EDGE, quality: 88 },
};

function buildBasePipeline(input: sharp.Sharp) {
  return input.rotate().flatten({ background: "#ffffff" }).toColorspace("srgb");
}

async function ensureReadableMetadata(
  buffer: Buffer
): Promise<{ width: number; height: number }> {
  try {
    const metadata = await sharp(buffer, { failOn: "error" }).metadata();
    const width = metadata.width ?? 0;
    const height = metadata.height ?? 0;
    if (!width || !height) {
      throw new VisualizationImageError("The uploaded image could not be read.", {
        code: "INVALID_INPUT",
      });
    }
    return { width, height };
  } catch (error) {
    if (error instanceof VisualizationImageError) {
      throw error;
    }
    throw new VisualizationImageError(
      "Unsupported or unreadable image. Please upload JPEG, PNG, WEBP, HEIC, or HEIF.",
      {
        code: "UNSUPPORTED_IMAGE",
        status: 415,
      }
    );
  }
}

async function encodeJpeg(
  pipeline: sharp.Sharp,
  quality: number
): Promise<EncodedVisualizationImage> {
  const { data, info } = await pipeline
    .jpeg({ quality, mozjpeg: true })
    .toBuffer({ resolveWithObject: true });

  return {
    buffer: data,
    mimeType: CANONICAL_MIME_TYPE,
    width: info.width,
    height: info.height,
    fileSizeBytes: data.byteLength,
  };
}

export async function normalizeUploadedVisualizationImage(
  buffer: Buffer
): Promise<EncodedVisualizationImage> {
  if (buffer.byteLength > MAX_IMAGE_UPLOAD_BYTES) {
    throw new VisualizationImageError(MAX_IMAGE_UPLOAD_ERROR_MESSAGE, {
      code: "IMAGE_TOO_LARGE",
    });
  }

  const metadata = await ensureReadableMetadata(buffer);
  if (
    metadata.width < MIN_IMAGE_DIMENSION ||
    metadata.height < MIN_IMAGE_DIMENSION
  ) {
    throw new VisualizationImageError(
      "Image must be at least 512 by 512 pixels.",
      { code: "INVALID_INPUT" }
    );
  }

  if (Math.max(metadata.width, metadata.height) > MAX_INPUT_LONG_EDGE) {
    throw new VisualizationImageError(
      "Image dimensions are too large. Please upload an image with a long edge of 6000px or less.",
      { code: "INVALID_INPUT" }
    );
  }

  const pipeline = buildBasePipeline(sharp(buffer, { failOn: "error" })).resize({
    width: FULL_LONG_EDGE,
    height: FULL_LONG_EDGE,
    fit: "inside",
    withoutEnlargement: true,
  });

  return encodeJpeg(pipeline, CANONICAL_QUALITY);
}

export async function normalizeGeneratedVisualizationImage(
  buffer: Buffer,
  expected: CanonicalDimensions
): Promise<EncodedVisualizationImage> {
  const metadata = await ensureReadableMetadata(buffer);
  const expectedRatio = expected.width / expected.height;
  const actualRatio = metadata.width / metadata.height;
  const ratioDelta = Math.abs(actualRatio - expectedRatio) / expectedRatio;

  if (ratioDelta > 0.02) {
    throw new VisualizationImageError(
      "The generated preview did not match the source framing.",
      { code: "INVALID_OUTPUT", status: 422 }
    );
  }

  const pipeline = buildBasePipeline(sharp(buffer, { failOn: "error" })).resize(
    expected.width,
    expected.height,
    {
      fit: "fill",
      withoutEnlargement: false,
    }
  );

  return encodeJpeg(pipeline, CANONICAL_QUALITY);
}

export async function createVisualizationDerivatives(
  canonical: EncodedVisualizationImage
): Promise<Record<MediaVariant, EncodedVisualizationImage>> {
  const derivatives = {} as Record<MediaVariant, EncodedVisualizationImage>;
  derivatives.canonical = canonical;

  for (const [variant, config] of Object.entries(DERIVATIVE_CONFIG) as Array<
    [MediaVariant, DerivativeConfig[MediaVariant]]
  >) {
    if (variant === "canonical" || !config) {
      continue;
    }

    const pipeline = buildBasePipeline(sharp(canonical.buffer, { failOn: "error" })).resize({
      width: config.longEdge,
      height: config.longEdge,
      fit: "inside",
      withoutEnlargement: true,
    });

    derivatives[variant] = await encodeJpeg(pipeline, config.quality);
  }

  return derivatives;
}
