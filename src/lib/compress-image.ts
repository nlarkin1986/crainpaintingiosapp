import imageCompression from 'browser-image-compression';

export async function compressImage(file: File): Promise<File> {
  // Always compress to stay under Vercel's 4.5 MB body limit
  if (file.size <= 1 * 1024 * 1024) return file;

  return imageCompression(file, {
    maxSizeMB: 3.5,
    maxWidthOrHeight: 2048,
    fileType: 'image/jpeg',
    initialQuality: 0.8,
    useWebWorker: true,
  });
}
