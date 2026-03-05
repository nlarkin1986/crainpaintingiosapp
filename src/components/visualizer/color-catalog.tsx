"use client";

import { useState, useMemo } from "react";
import type { BMColor } from "@/types/colors";
import type { Brand } from "@/lib/colors";
import {
  getAllColors,
  searchColors,
  getColorFamilies,
  filterByFamily,
} from "@/lib/colors";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { ColorSwatch } from "./color-swatch";
import { Search, X } from "lucide-react";

interface ColorCatalogProps {
  brand: Brand;
  selectedColors: BMColor[];
  onToggleColor: (color: BMColor) => void;
  maxColors: number;
}

export function ColorCatalog({ brand, selectedColors, onToggleColor, maxColors }: ColorCatalogProps) {
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedFamily, setSelectedFamily] = useState<string | null>(null);

  const families = useMemo(() => getColorFamilies(brand), [brand]);
  const atMax = selectedColors.length >= maxColors;

  const displayedColors = useMemo(() => {
    let colors: BMColor[];

    if (searchQuery.trim()) {
      colors = searchColors(searchQuery, brand);
    } else if (selectedFamily) {
      colors = filterByFamily(selectedFamily, brand);
    } else {
      colors = getAllColors(brand).slice(0, 100);
    }

    return colors;
  }, [searchQuery, selectedFamily, brand]);

  const handleClearSearch = () => {
    setSearchQuery("");
  };

  const handleFamilyClick = (family: string) => {
    setSelectedFamily(selectedFamily === family ? null : family);
    setSearchQuery("");
  };

  return (
    <div className="flex flex-col gap-4">
      {/* Search Input */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-muted-foreground" aria-hidden="true" />
        <Input
          type="text"
          placeholder="Search by name, number, or hex..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="h-12 pl-10 pr-10 text-base"
          style={{ fontSize: "16px" }}
        />
        {searchQuery && (
          <button
            type="button"
            onClick={handleClearSearch}
            className="absolute right-3 top-1/2 -translate-y-1/2 rounded-sm p-1 hover:bg-accent focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
            aria-label="Clear search"
          >
            <X className="h-4 w-4 text-muted-foreground" />
          </button>
        )}
      </div>

      {/* Family Filter Buttons */}
      {!searchQuery && (
        <div className="relative -mx-4 px-4">
          <div className="flex gap-2 overflow-x-auto pb-2">
            {families.map(({ family, count }) => (
              <Button
                key={family}
                variant={selectedFamily === family ? "default" : "outline"}
                size="sm"
                onClick={() => handleFamilyClick(family)}
                className="h-10 shrink-0 text-base"
              >
                {family} ({count})
              </Button>
            ))}
          </div>
        </div>
      )}

      {/* Results count */}
      <p className="text-sm text-muted-foreground">
        {displayedColors.length} {displayedColors.length === 1 ? "color" : "colors"}
        {searchQuery && " found"}
      </p>

      {/* Color Grid */}
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6">
        {displayedColors.map((color) => {
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

      {displayedColors.length === 0 && (
        <div className="py-12 text-center">
          <p className="text-lg text-muted-foreground">No colors found</p>
          <p className="text-sm text-muted-foreground">
            Try a different search term
          </p>
        </div>
      )}
    </div>
  );
}
