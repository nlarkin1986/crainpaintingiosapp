"use client";

import { useState } from "react";
import type { BMColor } from "@/types/colors";
import type { Brand } from "@/lib/colors";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { PopularColors } from "./popular-colors";
import { ColorCatalog } from "./color-catalog";
import { ArrowRight, X } from "lucide-react";
import { cn } from "@/lib/utils";
import { toast } from "sonner";

const MAX_COLORS = 5;

interface ColorPickerProps {
  selectedColors: BMColor[];
  onToggleColor: (color: BMColor) => void;
  onNext: () => void;
}

export function ColorPicker({ selectedColors, onToggleColor, onNext }: ColorPickerProps) {
  const [view, setView] = useState<"popular" | "catalog">("popular");
  const [brand, setBrand] = useState<Brand>('benjamin_moore');

  const handleToggleColor = (color: BMColor) => {
    const isAlreadySelected = selectedColors.some(c => c.number === color.number);
    if (!isAlreadySelected && selectedColors.length >= MAX_COLORS) {
      toast.info(`Maximum ${MAX_COLORS} colors. Remove one to add another.`);
      return;
    }
    onToggleColor(color);
  };

  const handleBrandChange = (newBrand: Brand) => {
    setBrand(newBrand);
    setView("popular");
  };

  return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div className="text-center">
        <h2 className="text-xl font-bold text-foreground sm:text-2xl">
          Pick Your Colors
        </h2>
        <p className="mt-2 text-base text-muted-foreground">
          Choose up to {MAX_COLORS} colors to compare side by side
        </p>
      </div>

      {/* Brand Selector */}
      <div className="flex justify-center gap-4">
        <button
          type="button"
          onClick={() => handleBrandChange('benjamin_moore')}
          className={cn(
            "flex flex-col items-center gap-2 rounded-xl p-3 transition-all duration-200",
            brand === 'benjamin_moore'
              ? "ring-2 ring-foreground/20 bg-muted/60"
              : "opacity-60 hover:opacity-90"
          )}
        >
          <div className="flex h-16 w-16 items-center justify-center rounded-full bg-white shadow-md p-2.5">
            <img src="/logos/bm-logo.svg" alt="Benjamin Moore" className="h-full w-full object-contain" />
          </div>
          <span className="text-xs font-semibold text-foreground">Benjamin Moore</span>
        </button>

        <button
          type="button"
          onClick={() => handleBrandChange('sherwin_williams')}
          className={cn(
            "flex flex-col items-center gap-2 rounded-xl p-3 transition-all duration-200",
            brand === 'sherwin_williams'
              ? "ring-2 ring-foreground/20 bg-muted/60"
              : "opacity-60 hover:opacity-90"
          )}
        >
          <div className="flex h-16 w-16 items-center justify-center rounded-full bg-white shadow-md p-2.5">
            <img src="/logos/sw-logo.svg" alt="Sherwin-Williams" className="h-full w-full object-contain" />
          </div>
          <span className="text-xs font-semibold text-foreground">Sherwin-Williams</span>
        </button>
      </div>

      {/* Segmented Tab Toggle */}
      <div className="flex rounded-xl bg-muted p-1">
        <button
          type="button"
          onClick={() => setView("popular")}
          className={cn(
            "flex-1 rounded-lg py-2.5 text-sm font-semibold transition-all duration-200",
            view === "popular"
              ? "bg-card text-foreground shadow-sm"
              : "text-muted-foreground hover:text-foreground"
          )}
        >
          Popular Colors
        </button>
        <button
          type="button"
          onClick={() => setView("catalog")}
          className={cn(
            "flex-1 rounded-lg py-2.5 text-sm font-semibold transition-all duration-200",
            view === "catalog"
              ? "bg-card text-foreground shadow-sm"
              : "text-muted-foreground hover:text-foreground"
          )}
        >
          All Colors
        </button>
      </div>

      {/* Color Grid */}
      <Card className="p-4">
        {view === "popular" ? (
          <PopularColors
            brand={brand}
            selectedColors={selectedColors}
            onToggleColor={handleToggleColor}
            maxColors={MAX_COLORS}
          />
        ) : (
          <ColorCatalog
            brand={brand}
            selectedColors={selectedColors}
            onToggleColor={handleToggleColor}
            maxColors={MAX_COLORS}
          />
        )}
      </Card>

      {/* Selected Colors Bottom Bar */}
      {selectedColors.length > 0 && (
        <div className="fixed bottom-0 left-0 right-0 z-50 border-t border-border/50 bg-card/80 p-4 shadow-[0_-4px_20px_rgba(0,0,0,0.08)] backdrop-blur-xl">
          <div className="mx-auto flex max-w-2xl flex-col gap-3">
            {/* Selected color chips */}
            <div className="flex items-center gap-2 overflow-x-auto">
              {selectedColors.map((color) => (
                <button
                  key={color.number}
                  type="button"
                  onClick={() => onToggleColor(color)}
                  className="flex shrink-0 items-center gap-2 rounded-full border border-border bg-background px-3 py-1.5 text-sm transition-all duration-200 hover:border-destructive/30 hover:bg-destructive/5 active:scale-95"
                  aria-label={`Remove ${color.name}`}
                >
                  <div
                    className="h-5 w-5 rounded-full border border-black/10 shadow-sm"
                    style={{ backgroundColor: `#${color.hex}` }}
                    aria-hidden="true"
                  />
                  <span className="font-medium text-foreground">{color.name}</span>
                  <X className="h-3.5 w-3.5 text-muted-foreground" />
                </button>
              ))}
            </div>

            {/* Counter + Next button */}
            <div className="flex items-center justify-between">
              <span className="text-sm text-muted-foreground">
                {selectedColors.length} of {MAX_COLORS} selected
              </span>
              <Button
                onClick={onNext}
                size="lg"
                className="h-12 gap-2 text-lg"
              >
                Next
                <ArrowRight className="h-5 w-5" />
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
