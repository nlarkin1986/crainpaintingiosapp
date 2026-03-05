"use client";

import { useState, useEffect, useRef } from "react";
import type { ColorResult } from "@/types/colors";
import {
  ReactCompareSlider,
  ReactCompareSliderImage,
} from "react-compare-slider";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Download, Share2, X, RotateCcw, Loader2 } from "lucide-react";
import { toast } from "sonner";

interface ResultCardProps {
  result: ColorResult;
  onRemove: () => void;
  onRetry: () => void;
  isGenerating: boolean;
}

export function ResultCard({ result, onRemove, onRetry, isGenerating }: ResultCardProps) {
  switch (result.status) {
    case 'pending':
      return <ShimmerCard color={result.color} label="Waiting..." />;
    case 'generating':
      return <ShimmerCard color={result.color} label="Creating..." showSpinner />;
    case 'complete':
      return (
        <CompletedCard
          result={result}
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
      const _exhaustive: never = result;
      return null;
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

function CompletedCard({ result, onRemove, isGenerating }: {
  result: Extract<ColorResult, { status: 'complete' }>;
  onRemove: () => void;
  isGenerating: boolean;
}) {
  const [shouldLoadSlider, setShouldLoadSlider] = useState(false);
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

  const shareUrl =
    typeof window !== "undefined"
      ? `${window.location.origin}/share/${result.shareId}`
      : "";

  const handleShare = async () => {
    if (navigator.share) {
      try {
        await navigator.share({
          title: `${result.color.name} - Crain Painting Visualizer`,
          text: `Check out this room visualized in Benjamin Moore ${result.color.name}!`,
          url: shareUrl,
        });
      } catch {
        // User cancelled
      }
    } else {
      try {
        await navigator.clipboard.writeText(shareUrl);
        toast.success("Link copied to clipboard!");
      } catch {
        toast.error("Could not copy link");
      }
    }
  };

  const safeName = result.color.name.toLowerCase().replace(/[^a-z0-9]+/g, '-');
  const safeNumber = result.color.number.replace(/[^a-zA-Z0-9-]/g, '');

  return (
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

        {/* Action buttons */}
        <div className="ml-auto flex shrink-0 items-center gap-1">
          <Button asChild variant="ghost" size="icon" className="h-9 w-9">
            <a href={result.resultUrl} download={`crain-${safeName}-${safeNumber}.jpg`} aria-label="Save">
              <Download className="h-4 w-4" />
            </a>
          </Button>
          <Button variant="ghost" size="icon" className="h-9 w-9" onClick={handleShare} aria-label="Share">
            <Share2 className="h-4 w-4" />
          </Button>
          <Button
            variant="ghost"
            size="icon"
            className="h-9 w-9 text-muted-foreground hover:text-destructive"
            onClick={onRemove}
            disabled={isGenerating}
            aria-label={`Remove ${result.color.name}`}
          >
            <X className="h-4 w-4" />
          </Button>
        </div>
      </div>
    </Card>
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
