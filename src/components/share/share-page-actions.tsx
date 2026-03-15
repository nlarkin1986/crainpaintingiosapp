"use client";

import { useState } from "react";
import { Copy, FileText, Share2 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { ShareExportSheet } from "@/components/share/share-export-sheet";
import { copyTextToClipboard, shareDesignCardFile } from "@/lib/share-client";
import {
  getDesignCardFilename,
  getReviewSheetFilename,
  getSharePaths,
  getShareUrls,
} from "@/lib/share";
import { getBrandLabel } from "@/lib/brands";

interface SharePageActionsProps {
  shareId: string;
  colorName: string;
  colorNumber: string;
  brand?: string;
  surface: string;
  rawImageUrl: string;
}

export function SharePageActions({
  shareId,
  colorName,
  colorNumber,
  brand,
  surface,
  rawImageUrl,
}: SharePageActionsProps) {
  const [showExportSheet, setShowExportSheet] = useState(false);

  const origin = typeof window !== "undefined" ? window.location.origin : undefined;
  const { cardPath, reviewPdfPath } = getSharePaths(shareId);
  const { shareUrl } = getShareUrls(shareId, origin);
  const brandLabel = getBrandLabel(brand);

  const handleShare = async () => {
    const result = await shareDesignCardFile({
      cardUrl: cardPath,
      shareUrl,
      filename: getDesignCardFilename({ brand, colorNumber, surface }),
      title: `${brandLabel} ${colorName}`,
      text: `Sharing a Crain Painting design card for ${brandLabel} ${colorName}.`,
    });

    if (result === "shared") {
      toast.success("Design card shared.");
      return;
    }

    if (result === "unsupported") {
      setShowExportSheet(true);
      return;
    }

    if (result === "error") {
      toast.error("Could not prepare the design card.");
      setShowExportSheet(true);
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

  return (
    <>
      <div className="flex flex-col gap-3 sm:flex-row">
        <Button size="lg" className="h-12 gap-2" onClick={handleShare}>
          <Share2 className="h-4 w-4" />
          Share Design Card
        </Button>

        <Button asChild variant="outline" size="lg" className="h-12 gap-2">
          <a
            href={reviewPdfPath}
            download={getReviewSheetFilename({ brand, colorNumber, surface })}
          >
            <FileText className="h-4 w-4" />
            Download PDF
          </a>
        </Button>

        <Button variant="outline" size="lg" className="h-12 gap-2" onClick={handleCopyLink}>
          <Copy className="h-4 w-4" />
          Copy Link
        </Button>
      </div>

      <ShareExportSheet
        open={showExportSheet}
        onClose={() => setShowExportSheet(false)}
        shareId={shareId}
        colorName={colorName}
        colorNumber={colorNumber}
        brand={brand}
        surface={surface}
        rawImageUrl={rawImageUrl}
      />
    </>
  );
}
