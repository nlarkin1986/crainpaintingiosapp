"use client";

import type { BMColor } from "@/types/colors";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { ArrowLeft, PaintRoller, LayoutGrid, DoorOpen, Minus, ArrowUpFromDot, PanelLeftClose, Pencil, Home } from "lucide-react";
import { Input } from "@/components/ui/input";
import { cn } from "@/lib/utils";
import { useMemo } from "react";

interface SurfacePickerProps {
  selectedSurface: string;
  onSelectSurface: (surface: string) => void;
  customInstruction: string;
  onCustomInstructionChange: (value: string) => void;
  selectedColors: BMColor[];
  photo: File | null;
  onSubmit: () => void;
  onBack: () => void;
}

const CUSTOM_SURFACE = "custom";

const SURFACES = [
  { label: "Exterior / Siding", icon: Home },
  { label: "Walls", icon: PaintRoller },
  { label: "Cabinets", icon: LayoutGrid },
  { label: "Front Door", icon: DoorOpen },
  { label: "Trim", icon: Minus },
  { label: "Ceiling", icon: ArrowUpFromDot },
  { label: "Shutters", icon: PanelLeftClose },
] as const;

export function SurfacePicker({
  selectedSurface,
  onSelectSurface,
  customInstruction,
  onCustomInstructionChange,
  selectedColors,
  photo,
  onSubmit,
  onBack,
}: SurfacePickerProps) {
  const photoPreviewUrl = useMemo(() => {
    if (photo) {
      return URL.createObjectURL(photo);
    }
    return null;
  }, [photo]);

  return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div className="text-center">
        <h2 className="text-xl font-bold text-foreground sm:text-2xl">
          Select Surface
        </h2>
        <p className="mt-2 text-base text-muted-foreground">
          Which surface would you like to visualize?
        </p>
      </div>

      {/* Context Reminder */}
      <Card className="overflow-hidden p-0">
        <div className="flex items-center gap-4 p-4">
          {/* Photo Thumbnail */}
          {photoPreviewUrl && (
            <img
              src={photoPreviewUrl}
              alt="Selected photo"
              className="h-14 w-14 rounded-lg border border-border object-cover shadow-sm"
            />
          )}

          {/* Selected Colors + Label */}
          <div className="flex flex-1 flex-col gap-1.5">
            <span className="text-xs font-medium uppercase tracking-wider text-muted-foreground">
              Your selections
            </span>
            <div className="flex items-center gap-1.5">
              {selectedColors.map((color) => (
                <div
                  key={color.number}
                  className="h-7 w-7 rounded-md border border-black/10 shadow-sm"
                  style={{ backgroundColor: `#${color.hex}` }}
                  title={color.name}
                  aria-label={color.name}
                />
              ))}
              <span className="ml-1 text-sm text-muted-foreground">
                {selectedColors.length} {selectedColors.length === 1 ? 'color' : 'colors'}
              </span>
            </div>
          </div>
        </div>
      </Card>

      {/* Surface Selection */}
      <Card className="p-4">
        <div className="grid grid-cols-2 gap-3">
          {SURFACES.map((surface) => {
            const Icon = surface.icon;
            const isSelected = selectedSurface === surface.label;
            return (
              <button
                key={surface.label}
                type="button"
                onClick={() => onSelectSurface(surface.label)}
                className={cn(
                  "flex h-20 flex-col items-center justify-center gap-2 rounded-xl border-2 transition-all duration-200",
                  "hover:shadow-md focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
                  "active:scale-[0.98]",
                  isSelected
                    ? "border-primary bg-primary/5 shadow-sm"
                    : "border-border bg-background hover:border-primary/40"
                )}
                aria-pressed={isSelected}
              >
                <Icon
                  className={cn(
                    "h-5 w-5 transition-colors",
                    isSelected ? "text-primary" : "text-muted-foreground"
                  )}
                  strokeWidth={isSelected ? 2 : 1.5}
                />
                <span
                  className={cn(
                    "text-sm font-medium transition-colors",
                    isSelected ? "text-primary" : "text-foreground"
                  )}
                >
                  {surface.label}
                </span>
              </button>
            );
          })}

          {/* Custom / Other tile */}
          {(() => {
            const isCustomSelected = selectedSurface === CUSTOM_SURFACE;
            return (
              <button
                type="button"
                onClick={() => onSelectSurface(CUSTOM_SURFACE)}
                className={cn(
                  "flex h-20 flex-col items-center justify-center gap-2 rounded-xl border-2 transition-all duration-200",
                  "hover:shadow-md focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
                  "active:scale-[0.98]",
                  isCustomSelected
                    ? "border-primary bg-primary/5 shadow-sm"
                    : "border-border bg-background hover:border-primary/40"
                )}
                aria-pressed={isCustomSelected}
              >
                <Pencil
                  className={cn(
                    "h-5 w-5 transition-colors",
                    isCustomSelected ? "text-primary" : "text-muted-foreground"
                  )}
                  strokeWidth={isCustomSelected ? 2 : 1.5}
                />
                <span
                  className={cn(
                    "text-sm font-medium transition-colors",
                    isCustomSelected ? "text-primary" : "text-foreground"
                  )}
                >
                  Custom / Other
                </span>
              </button>
            );
          })()}
        </div>

        {/* Inline custom input */}
        {selectedSurface === CUSTOM_SURFACE && (
          <div className="mt-3 animate-in slide-in-from-top-2 fade-in duration-200">
            <Input
              value={customInstruction}
              onChange={(e) => onCustomInstructionChange(e.target.value)}
              placeholder="e.g., garage door, fence, brick exterior..."
              className="h-12 text-base"
              style={{ fontSize: "16px" }}
              autoFocus
              aria-label="Custom surface description"
            />
          </div>
        )}
      </Card>

      {/* Navigation Buttons */}
      <div className="flex gap-3">
        <Button
          variant="outline"
          size="lg"
          onClick={onBack}
          className="h-12 gap-2 text-lg"
        >
          <ArrowLeft className="h-5 w-5" />
          Back
        </Button>
        <Button
          variant="cta"
          onClick={onSubmit}
          disabled={!selectedSurface || (selectedSurface === CUSTOM_SURFACE && !customInstruction.trim())}
          size="lg"
          className="h-12 flex-1 text-lg"
        >
          {selectedColors.length > 1 ? `See My ${selectedColors.length} Colors` : "See My Room"}
        </Button>
      </div>
    </div>
  );
}
