"use client";

import { useEffect, type MouseEvent } from "react";
import Image from "next/image";
import { Copy, Download, FileText, Share2, X } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { copyTextToClipboard, shareDesignCardFile } from "@/lib/share-client";
import {
  getDesignCardFilename,
  getReviewSheetFilename,
  getSharePaths,
  getShareUrls,
} from "@/lib/share";
import { getBrandLabel } from "@/lib/brands";

interface ShareExportSheetProps {
  open: boolean;
  onClose: () => void;
  shareId: string;
  colorName: string;
  colorNumber: string;
  brand?: string;
  surface: string;
  rawImageUrl: string;
}

export function ShareExportSheet({
  open,
  onClose,
  shareId,
  colorName,
  colorNumber,
  brand,
  surface,
  rawImageUrl,
}: ShareExportSheetProps) {
  useEffect(() => {
    if (!open) return;

    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        onClose();
      }
    };

    window.addEventListener("keydown", onKeyDown);

    return () => {
      document.body.style.overflow = previousOverflow;
      window.removeEventListener("keydown", onKeyDown);
    };
  }, [onClose, open]);

  if (!open) return null;

  const origin = typeof window !== "undefined" ? window.location.origin : undefined;
  const { cardPath, reviewPdfPath } = getSharePaths(shareId);
  const { shareUrl } = getShareUrls(shareId, origin);
  const brandLabel = getBrandLabel(brand);
  const cardFilename = getDesignCardFilename({ brand, colorNumber, surface });
  const reviewPdfFilename = getReviewSheetFilename({ brand, colorNumber, surface });

  const handleShareJpeg = async () => {
    const result = await shareDesignCardFile({
      cardUrl: cardPath,
      shareUrl,
      filename: cardFilename,
      title: `${brandLabel} ${colorName}`,
      text: `Sharing a Crain Painting design card for ${brandLabel} ${colorName}.`,
      fallbackToDownload: true,
    });

    if (result === "downloaded") {
      toast.success("Design card downloaded.");
      return;
    }

    if (result === "shared") {
      toast.success("Design card shared.");
      onClose();
      return;
    }

    if (result === "error") {
      toast.error("Could not prepare the design card.");
    }
  };

  const handleCopyLink = async () => {
    try {
      await copyTextToClipboard(shareUrl);
      toast.success("Share link copied.");
    } catch {
      toast.error("Could not copy the share link.");
    }
  };

  const handleBackdropClick = (event: MouseEvent<HTMLDivElement>) => {
    if (event.target === event.currentTarget) {
      onClose();
    }
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-end bg-black/55 p-0 sm:items-center sm:justify-center sm:p-4"
      onClick={handleBackdropClick}
    >
      <div className="w-full rounded-t-3xl border border-border bg-background shadow-2xl sm:max-w-2xl sm:rounded-3xl">
        <div className="flex items-start justify-between gap-4 border-b border-border px-5 py-4 sm:px-6">
          <div>
            <h2 className="font-heading text-xl font-bold text-foreground">
              Share Design Card
            </h2>
            <p className="mt-1 text-sm text-muted-foreground">
              Save or share a painter-ready card plus a formal review PDF.
            </p>
          </div>
          <Button variant="ghost" size="icon-sm" onClick={onClose} aria-label="Close">
            <X className="h-4 w-4" />
          </Button>
        </div>

        <div className="grid gap-5 px-5 py-5 sm:grid-cols-[minmax(0,1.2fr)_minmax(280px,0.8fr)] sm:px-6">
          <div className="overflow-hidden rounded-2xl border border-border bg-muted/20 shadow-sm">
            <div className="relative aspect-[4/5] w-full">
              <Image
                src={cardPath}
                alt={`${colorName} design card preview`}
                fill
                className="object-cover"
                sizes="(min-width: 640px) 520px, 100vw"
              />
            </div>
          </div>

          <div className="flex flex-col gap-3">
            <div className="rounded-2xl border border-border bg-card p-4">
              <p className="text-sm font-semibold text-foreground">{colorName}</p>
              <p className="mt-1 text-sm text-muted-foreground">
                {brandLabel} {colorNumber}
              </p>
            </div>

            <Button size="lg" className="h-12 justify-start" onClick={handleShareJpeg}>
              <Share2 className="h-4 w-4" />
              Share JPEG
            </Button>

            <Button asChild variant="outline" size="lg" className="h-12 justify-start">
              <a href={reviewPdfPath} download={reviewPdfFilename}>
                <FileText className="h-4 w-4" />
                Download PDF
              </a>
            </Button>

            <Button variant="outline" size="lg" className="h-12 justify-start" onClick={handleCopyLink}>
              <Copy className="h-4 w-4" />
              Copy Link
            </Button>

            <Button asChild variant="outline" size="lg" className="h-12 justify-start">
              <a href={rawImageUrl} download>
                <Download className="h-4 w-4" />
                Download Raw Image
              </a>
            </Button>

            <p className="pt-1 text-xs leading-5 text-muted-foreground">
              If preview export is unavailable, the live share link and raw image remain usable.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
