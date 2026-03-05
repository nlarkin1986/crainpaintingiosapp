"use client";

import { useState } from "react";
import type { BMColor } from "@/types/colors";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Check, Loader2, RefreshCw } from "lucide-react";

interface ColorSuggestionCardProps {
  suggestions: BMColor[];
  selectedColors: BMColor[];
  onToggleColor: (color: BMColor) => void;
  onRefine: () => void;
  onContinue: () => void;
  isLoading: boolean;
  message: string;
  round: number;
}

export function ColorSuggestionCard({
  suggestions,
  selectedColors,
  onToggleColor,
  onRefine,
  onContinue,
  isLoading,
  message,
  round,
}: ColorSuggestionCardProps) {
  const isSelected = (color: BMColor) =>
    selectedColors.some((c) => c.number === color.number);

  return (
    <div className="w-full max-w-lg">
      <h2 className="mb-2 text-center font-heading text-2xl font-bold md:text-3xl">
        {round === 0 ? "Colors we think you'll love" : "More colors to consider"}
      </h2>
      <p className="mb-6 text-center text-base text-muted-foreground">
        {message}
      </p>

      {isLoading ? (
        <div className="flex flex-col items-center justify-center gap-3 py-16">
          <Loader2 className="size-8 animate-spin text-primary" />
          <p className="text-muted-foreground">Finding perfect colors...</p>
        </div>
      ) : (
        <>
          {/* Color swatches grid */}
          <div className="mb-6 grid grid-cols-2 gap-3 sm:grid-cols-3">
            {suggestions.map((color) => {
              const selected = isSelected(color);
              return (
                <button
                  key={color.number}
                  onClick={() => onToggleColor(color)}
                  aria-pressed={selected}
                  className={cn(
                    "group relative flex flex-col overflow-hidden rounded-xl border-2 transition-all outline-none",
                    "focus-visible:ring-2 focus-visible:ring-primary/50 focus-visible:ring-offset-2",
                    "hover:shadow-md active:scale-[0.97]",
                    selected
                      ? "border-primary ring-2 ring-primary/30"
                      : "border-border"
                  )}
                >
                  {/* Color swatch */}
                  <div
                    className="relative h-20 w-full"
                    style={{ backgroundColor: `#${color.hex}` }}
                  >
                    {selected && (
                      <div className="absolute inset-0 flex items-center justify-center bg-black/20">
                        <Check className="size-8 text-white drop-shadow-md" strokeWidth={3} />
                      </div>
                    )}
                  </div>

                  {/* Color info */}
                  <div className="bg-white p-2.5">
                    <div className="text-xs font-semibold text-foreground truncate">
                      {color.name}
                    </div>
                    <div className="text-xs text-muted-foreground">{color.number}</div>
                  </div>
                </button>
              );
            })}
          </div>

          {/* Selected count */}
          {selectedColors.length > 0 && (
            <div className="mb-4 text-center text-sm text-muted-foreground">
              {selectedColors.length} color{selectedColors.length !== 1 ? "s" : ""} selected
            </div>
          )}

          {/* Action buttons */}
          <div className="flex flex-col gap-3 sm:flex-row">
            <Button
              variant="outline"
              onClick={onRefine}
              className="flex-1 gap-2"
              disabled={isLoading}
            >
              <RefreshCw className="size-4" />
              Show me more
            </Button>
            <Button
              onClick={onContinue}
              className="flex-1"
              disabled={selectedColors.length === 0}
            >
              Continue with {selectedColors.length} color{selectedColors.length !== 1 ? "s" : ""}
            </Button>
          </div>
        </>
      )}
    </div>
  );
}
