"use client";

export type ShareDesignCardResult =
  | "shared"
  | "downloaded"
  | "unsupported"
  | "cancelled"
  | "error";

function triggerBlobDownload(blob: Blob, filename: string) {
  const objectUrl = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = objectUrl;
  link.download = filename;
  link.click();
  URL.revokeObjectURL(objectUrl);
}

export async function copyTextToClipboard(value: string) {
  await navigator.clipboard.writeText(value);
}

export async function shareDesignCardFile(options: {
  cardUrl: string;
  shareUrl: string;
  filename: string;
  title: string;
  text: string;
  fallbackToDownload?: boolean;
}): Promise<ShareDesignCardResult> {
  try {
    const response = await fetch(options.cardUrl);
    if (!response.ok) {
      return "error";
    }

    const blob = await response.blob();
    const file = new File([blob], options.filename, {
      type: blob.type || "image/jpeg",
    });

    if (typeof navigator.share === "function") {
      try {
        const canShareFiles =
          typeof navigator.canShare !== "function" ||
          navigator.canShare({ files: [file] });

        if (canShareFiles) {
          await navigator.share({
            title: options.title,
            text: options.text,
            url: options.shareUrl,
            files: [file],
          });
          return "shared";
        }
      } catch (error) {
        if (error instanceof Error && error.name === "AbortError") {
          return "cancelled";
        }

        if (!options.fallbackToDownload) {
          return "unsupported";
        }
      }
    } else if (!options.fallbackToDownload) {
      return "unsupported";
    }

    if (options.fallbackToDownload) {
      triggerBlobDownload(blob, options.filename);
      return "downloaded";
    }

    return "unsupported";
  } catch {
    return "error";
  }
}
