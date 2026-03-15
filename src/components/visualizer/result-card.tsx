"use client";

import { useState, useEffect, useRef } from "react";
import type { ColorResult } from "@/types/colors";
import {
  ReactCompareSlider,
  ReactCompareSliderImage,
} from "react-compare-slider";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Share2, X, RotateCcw, Loader2, MoreHorizontal } from "lucide-react";
import { toast } from "sonner";
import { getBrandLabel } from "@/lib/brands";
import { ShareExportSheet } from "@/components/share/share-export-sheet";
import { shareDesignCardFile } from "@/lib/share-client";
import { getDesignCardFilename, getShareUrls } from "@/lib/share";

interface ResultCardProps {
  result: ColorResult;
  surface: string;
  onRemove: () => void;
  onRetry: () => void;
  isGenerating: boolean;
}

export function ResultCard({
  result,
  surface,
  onRemove,
  onRetry,
  isGenerating,
}: ResultCardProps) {
  switch (result.status) {
    case 'pending':
      return <ShimmerCard color={result.color} label="Waiting..." />;
    case 'generating':
      return <ShimmerCard color={result.color} label="Creating..." showSpinner />;
    case 'complete':
      return (
        <CompletedCard
          result={result}
          surface={surface}
          onRemove={onRemove}
          isGenerating={isGenerating}
        />
      );
    case 'failed':
      return (
        <FailedCard
          result={result}
          onRetry={onRetry}
          onRemove={onRemove}
          isGenerating={isGenerating}
        />
      );
    default: {
      const exhaustiveCheck: never = result;
      return exhaustiveCheck;
    }
  }
}

// --- Shimmer Card (pending / generating) ---

function ShimmerCard({ color, label, showSpinner }: {
  color: { name: string; number: string; hex: string };
  label: string;
  showSpinner?: boolean;
}) {
  return (
    <Card className="overflow-hidden p-0">
      <div className="relative">
        <div className="shimmer aspect-[4/3] w-full" />
        <div className="absolute inset-0 flex flex-col items-center justify-center gap-3">
          {showSpinner && (
            <div className="flex h-12 w-12 items-center justify-center rounded-full bg-white/80 shadow-sm backdrop-blur-sm">
              <Loader2 className="h-6 w-6 animate-spin text-primary" />
            </div>
          )}
          <span className="rounded-full bg-white/80 px-3 py-1 text-sm font-medium text-muted-foreground backdrop-blur-sm">
            {label}
          </span>
        </div>
      </div>
      <div className="flex items-center gap-3 p-3">
        <div
          className="h-10 w-10 shrink-0 rounded-lg border border-black/10 shadow-sm"
          style={{ backgroundColor: `#${color.hex}` }}
          aria-hidden="true"
        />
        <div className="flex flex-col">
          <span className="text-sm font-semibold text-foreground">{color.name}</span>
          <span className="text-xs text-muted-foreground">{color.number}</span>
        </div>
      </div>
    </Card>
  );
}

// --- Completed Card ---

function CompletedCard({ result, surface, onRemove, isGenerating }: {
  result: Extract<ColorResult, { status: 'complete' }>;
  surface: string;
  onRemove: () => void;
  isGenerating: boolean;
}) {
  const [shouldLoadSlider, setShouldLoadSlider] = useState(false);
  const [showExportSheet, setShowExportSheet] = useState(false);
  const cardRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = cardRef.current;
    if (!el) return;
    const observer = new IntersectionObserver(
      ([entry]) => { if (entry.isIntersecting) setShouldLoadSlider(true); },
      { rootMargin: '200px' }
    );
    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  const brandLabel = getBrandLabel(result.color.brand);

  const handleShare = async () => {
    const origin = typeof window !== "undefined" ? window.location.origin : undefined;
    const { shareUrl, cardUrl } = getShareUrls(result.shareId, origin);
    const outcome = await shareDesignCardFile({
      cardUrl,
      shareUrl,
      filename: getDesignCardFilename({
        brand: result.color.brand,
        colorNumber: result.color.number,
        surface,
      }),
      title: `${brandLabel} ${result.color.name}`,
      text: `Sharing a Crain Painting design card for ${brandLabel} ${result.color.name}.`,
    });

    if (outcome === "shared") {
      toast.success("Design card shared.");
      return;
    }

    if (outcome === "unsupported") {
      setShowExportSheet(true);
      return;
    }

    if (outcome === "error") {
      toast.error("Could not prepare the design card.");
      setShowExportSheet(true);
    }
  };

  return (
    <>
      <Card className="overflow-hidden p-0 transition-shadow hover:shadow-md" ref={cardRef}>
        {/* Before/After Slider */}
        <div className="relative">
          {shouldLoadSlider ? (
            <ReactCompareSlider
              changePositionOnHover={false}
              itemOne={
                <ReactCompareSliderImage src={result.originalUrl} alt="Original photo" />
              }
              itemTwo={
                <ReactCompareSliderImage
                  src={result.resultUrl}
                  alt={`Room visualized in ${result.color.name}`}
                />
              }
              className="aspect-[4/3] w-full"
            />
          ) : (
            <div className="shimmer aspect-[4/3] w-full" />
          )}
          {/* Labels */}
          <span className="pointer-events-none absolute left-2 top-2 rounded-full bg-black/60 px-2.5 py-1 text-xs font-semibold tracking-wide text-white uppercase backdrop-blur-sm">
            Before
          </span>
          <span className="pointer-events-none absolute right-2 top-2 rounded-full bg-white/80 px-2.5 py-1 text-xs font-semibold tracking-wide text-foreground uppercase backdrop-blur-sm">
            After
          </span>
        </div>

        {/* Color Info + Actions */}
        <div className="flex flex-col gap-3 p-3">
          <div className="flex items-center gap-3">
            <div
              className="h-10 w-10 shrink-0 rounded-lg border border-black/10 shadow-sm"
              style={{ backgroundColor: `#${result.color.hex}` }}
              aria-hidden="true"
            />
            <div className="flex min-w-0 flex-col">
              <span className="truncate text-sm font-semibold text-foreground">{result.color.name}</span>
              <span className="text-xs text-muted-foreground">{result.color.number}</span>
            </div>

            <Button
              variant="ghost"
              size="icon"
              className="ml-auto h-9 w-9 text-muted-foreground hover:text-destructive"
              onClick={onRemove}
              disabled={isGenerating}
              aria-label={`Remove ${result.color.name}`}
            >
              <X className="h-4 w-4" />
            </Button>
          </div>

          <div className="flex items-center gap-2">
            <Button size="sm" className="flex-1" onClick={handleShare}>
              <Share2 className="h-4 w-4" />
              Share Design Card
            </Button>

            <Button
              variant="outline"
              size="sm"
              className="shrink-0"
              onClick={() => setShowExportSheet(true)}
            >
              <MoreHorizontal className="h-4 w-4" />
              More
            </Button>
          </div>
        </div>
      </Card>

      <ShareExportSheet
        open={showExportSheet}
        onClose={() => setShowExportSheet(false)}
        shareId={result.shareId}
        colorName={result.color.name}
        colorNumber={result.color.number}
        brand={result.color.brand}
        surface={surface}
        rawImageUrl={result.resultUrl}
      />
    </>
  );
}

// --- Failed Card ---

function FailedCard({ result, onRetry, onRemove, isGenerating }: {
  result: Extract<ColorResult, { status: 'failed' }>;
  onRetry: () => void;
  onRemove: () => void;
  isGenerating: boolean;
}) {
  return (
    <Card className="overflow-hidden p-0">
      <div className="flex aspect-[4/3] w-full flex-col items-center justify-center gap-3 bg-muted/30 px-4 text-center">
        <div className="flex h-12 w-12 items-center justify-center rounded-full bg-destructive/10">
          <RotateCcw className="h-5 w-5 text-destructive" />
        </div>
        <p className="text-sm text-muted-foreground">{result.error}</p>
        <Button
          variant="outline"
          size="sm"
          onClick={onRetry}
          disabled={isGenerating}
          className="gap-1.5"
        >
          <RotateCcw className="h-3.5 w-3.5" />
          Retry
        </Button>
      </div>
      <div className="flex items-center gap-3 p-3">
        <div
          className="h-10 w-10 shrink-0 rounded-lg border border-black/10 shadow-sm"
          style={{ backgroundColor: `#${result.color.hex}` }}
          aria-hidden="true"
        />
        <div className="flex min-w-0 flex-col">
          <span className="truncate text-sm font-semibold text-foreground">{result.color.name}</span>
          <span className="text-xs text-muted-foreground">{result.color.number}</span>
        </div>
        <Button
          variant="ghost"
          size="icon"
          className="ml-auto h-9 w-9 shrink-0 text-muted-foreground hover:text-destructive"
          onClick={onRemove}
          disabled={isGenerating}
          aria-label={`Remove ${result.color.name}`}
        >
          <X className="h-4 w-4" />
        </Button>
      </div>
    </Card>
  );
}
