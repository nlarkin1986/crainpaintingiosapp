"use client";

import { useState } from "react";
import Image from "next/image";
import { Palette, Droplets } from "lucide-react";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { TimeOfDaySwatches } from "@/components/report/time-of-day-swatches";
import type { ColorRecommendation as ColorRec } from "@/types/consultation";

interface ColorRecommendationProps {
  recommendation: ColorRec;
  index: number;
}

export function ColorRecommendation({
  recommendation,
  index,
}: ColorRecommendationProps) {
  const {
    colorName,
    colorNumber,
    hex,
    rationale,
    finishSheen,
    morningHex,
    afternoonHex,
    eveningHex,
    visualizationUrl,
    originalUrl,
  } = recommendation;

  return (
    <Card className="overflow-hidden">
      <CardHeader className="pb-0">
        <CardTitle className="flex items-start gap-4">
          {/* Large color swatch */}
          <div
            className="flex-shrink-0 size-16 sm:size-20 rounded-lg border border-border/60 shadow-sm"
            style={{ backgroundColor: hex }}
            aria-label={`Color swatch: ${hex}`}
          />
          <div className="min-w-0">
            <p className="text-xs text-muted-foreground font-normal mb-0.5">
              Recommendation {index + 1}
            </p>
            <h3 className="font-heading text-lg font-bold text-foreground leading-tight">
              {colorName}
            </h3>
            <p className="text-sm text-primary font-medium mt-0.5">
              {colorNumber}
            </p>
          </div>
        </CardTitle>
      </CardHeader>

      <CardContent className="space-y-5">
        {/* Rationale */}
        <div>
          <div className="flex items-center gap-1.5 mb-2">
            <Palette className="size-3.5 text-primary" />
            <span className="text-xs font-medium text-muted-foreground uppercase tracking-wide">
              Why This Color
            </span>
          </div>
          <p className="text-sm text-foreground/85 leading-relaxed">
            {rationale}
          </p>
        </div>

        {/* Finish / sheen */}
        <div className="flex items-center gap-2 text-sm">
          <Droplets className="size-3.5 text-primary flex-shrink-0" />
          <span className="text-muted-foreground">Recommended finish:</span>
          <span className="font-medium text-foreground">{finishSheen}</span>
        </div>

        {/* Before / after visualization */}
        {visualizationUrl && originalUrl && (
          <BeforeAfterSlider
            originalUrl={originalUrl}
            visualizationUrl={visualizationUrl}
            colorName={colorName}
          />
        )}

        {/* Time-of-day swatches */}
        <div>
          <p className="text-xs font-medium text-muted-foreground uppercase tracking-wide mb-2">
            How Light Changes This Color
          </p>
          <TimeOfDaySwatches
            morningHex={morningHex}
            afternoonHex={afternoonHex}
            eveningHex={eveningHex}
          />
        </div>
      </CardContent>
    </Card>
  );
}

/* ------------------------------------------------------------------ */
/* CSS-only before/after slider                                       */
/* ------------------------------------------------------------------ */

interface BeforeAfterSliderProps {
  originalUrl: string;
  visualizationUrl: string;
  colorName: string;
}

function BeforeAfterSlider({
  originalUrl,
  visualizationUrl,
  colorName,
}: BeforeAfterSliderProps) {
  const [position, setPosition] = useState(50);

  return (
    <div>
      <p className="text-xs font-medium text-muted-foreground uppercase tracking-wide mb-2">
        Before &amp; After
      </p>
      <div className="relative w-full aspect-[4/3] rounded-lg overflow-hidden border border-border select-none">
        {/* After image (full width, underneath) */}
        <Image
          src={visualizationUrl}
          alt={`Room with ${colorName}`}
          fill
          className="object-cover"
          sizes="(max-width: 768px) 100vw, 600px"
        />

        {/* Before image (clipped by slider position) */}
        <div
          className="absolute inset-0 overflow-hidden"
          style={{ width: `${position}%` }}
        >
          <Image
            src={originalUrl}
            alt="Original room"
            fill
            className="object-cover"
            sizes="(max-width: 768px) 100vw, 600px"
          />
        </div>

        {/* Slider line */}
        <div
          className="absolute top-0 bottom-0 w-0.5 bg-white shadow-md z-10 pointer-events-none"
          style={{ left: `${position}%` }}
        >
          {/* Handle */}
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 size-8 rounded-full bg-white shadow-lg border-2 border-primary flex items-center justify-center">
            <svg
              width="12"
              height="12"
              viewBox="0 0 12 12"
              fill="none"
              className="text-primary"
            >
              <path
                d="M3 2L1 6L3 10M9 2L11 6L9 10"
                stroke="currentColor"
                strokeWidth="1.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </div>
        </div>

        {/* Range input overlay */}
        <input
          type="range"
          min={0}
          max={100}
          value={position}
          onChange={(e) => setPosition(Number(e.target.value))}
          className="absolute inset-0 w-full h-full opacity-0 cursor-ew-resize z-20"
          aria-label="Drag to compare before and after"
        />

        {/* Labels */}
        <span className="absolute top-2 left-2 bg-black/50 text-white text-[10px] font-medium px-2 py-0.5 rounded z-10">
          Before
        </span>
        <span className="absolute top-2 right-2 bg-black/50 text-white text-[10px] font-medium px-2 py-0.5 rounded z-10">
          After
        </span>
      </div>
    </div>
  );
}
