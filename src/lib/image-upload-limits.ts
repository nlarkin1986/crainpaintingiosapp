export const MAX_IMAGE_UPLOAD_BYTES = 4_100_000;
export const MAX_IMAGE_UPLOAD_MB = Number(
  (MAX_IMAGE_UPLOAD_BYTES / 1_000_000).toFixed(1)
);
export const MAX_IMAGE_UPLOAD_LABEL = `${MAX_IMAGE_UPLOAD_MB.toFixed(1)} MB`;
export const MAX_IMAGE_UPLOAD_ERROR_MESSAGE = `Image must be ${MAX_IMAGE_UPLOAD_LABEL} or smaller.`;
