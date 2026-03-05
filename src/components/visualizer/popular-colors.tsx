"use client";

import type { BMColor } from "@/types/colors";
import type { Brand } from "@/lib/colors";
import { getPopularColors } from "@/lib/colors";
import { ColorSwatch } from "./color-swatch";

interface PopularColorsProps {
  brand: Brand;
  selectedColors: BMColor[];
  onToggleColor: (color: BMColor) => void;
  maxColors: number;
}

export function PopularColors({ brand, selectedColors, onToggleColor, maxColors }: PopularColorsProps) {
  const popularColors = getPopularColors(brand);
  const atMax = selectedColors.length >= maxColors;

  return (
    <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6">
      {popularColors.map((color) => {
        const isSelected = selectedColors.some(c => c.number === color.number);
        return (
          <ColorSwatch
            key={`${color.number}-${color.name}`}
            color={color}
            isSelected={isSelected}
            isDisabled={atMax && !isSelected}
            onClick={() => onToggleColor(color)}
          />
        );
      })}
    </div>
  );
}
