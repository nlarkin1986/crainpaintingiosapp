import imageCompression from 'browser-image-compression';
import { MAX_IMAGE_UPLOAD_MB, MAX_IMAGE_UPLOAD_BYTES } from "@/lib/image-upload-limits";

export async function compressImage(file: File): Promise<File> {
  // Keep the file under the deployed multipart request ceiling while still
  // allowing source images that started above 4 MB.
  if (file.size <= MAX_IMAGE_UPLOAD_BYTES) return file;

  return imageCompression(file, {
    maxSizeMB: MAX_IMAGE_UPLOAD_MB,
    maxWidthOrHeight: 2048,
    fileType: 'image/jpeg',
    initialQuality: 0.8,
    useWebWorker: true,
  });
}
