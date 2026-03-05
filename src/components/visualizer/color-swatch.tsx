"use client";

import type { BMColor } from "@/types/colors";
import { cn } from "@/lib/utils";
import { Check } from "lucide-react";

interface ColorSwatchProps {
  color: BMColor;
  isSelected: boolean;
  isDisabled?: boolean;
  onClick: () => void;
}

export function ColorSwatch({ color, isSelected, isDisabled, onClick }: ColorSwatchProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={isDisabled}
      className={cn(
        "relative flex min-h-[48px] w-full flex-col items-center gap-2 rounded-lg border-2 p-2 transition-all",
        "hover:shadow-md focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
        isSelected
          ? "border-primary ring-2 ring-primary ring-offset-2"
          : "border-border hover:border-primary/50",
        isDisabled && !isSelected && "cursor-not-allowed opacity-40"
      )}
      role="checkbox"
      aria-checked={isSelected}
      aria-label={`${color.name} ${color.number}`}
    >
      {/* Color swatch - min 64px */}
      <div
        className="relative h-16 w-full rounded-md border border-border shadow-sm"
        style={{ backgroundColor: `#${color.hex}` }}
        aria-hidden="true"
      >
        {/* Checkmark overlay */}
        {isSelected && (
          <div className="absolute inset-0 flex items-center justify-center rounded-md bg-black/30">
            <Check className="h-6 w-6 text-white drop-shadow-md" strokeWidth={3} />
          </div>
        )}
      </div>

      {/* Color info */}
      <div className="flex flex-col items-center gap-0.5 text-center">
        <span className="text-sm font-medium leading-tight text-foreground">
          {color.name}
        </span>
        <span className="text-xs text-muted-foreground">
          {color.number}
        </span>
      </div>
    </button>
  );
}
