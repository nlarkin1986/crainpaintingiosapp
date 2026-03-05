"use client";

import { MOOD_OPTIONS } from "@/types/consultation";
import type { MoodKey } from "@/types/consultation";
import { cn } from "@/lib/utils";
import {
  Flame, Sparkles, Zap, Leaf, Crown, Waves
} from "lucide-react";

const MOOD_ICONS: Record<string, React.ComponentType<{ className?: string }>> = {
  Flame, Sparkles, Zap, Leaf, Crown, Waves,
};

interface MoodCardProps {
  onSelect: (mood: MoodKey) => void;
  selected?: MoodKey;
}

export function MoodCard({ onSelect, selected }: MoodCardProps) {
  return (
    <div className="w-full max-w-lg">
      <h2 className="mb-2 text-center font-heading text-2xl font-bold md:text-3xl">
        What vibe are you going for?
      </h2>
      <p className="mb-6 text-center text-lg text-muted-foreground">
        Choose the mood that best describes your ideal space
      </p>

      <div role="radiogroup" aria-label="Room mood" className="grid grid-cols-1 gap-3 sm:grid-cols-2">
        {MOOD_OPTIONS.map((mood) => {
          const Icon = MOOD_ICONS[mood.icon];
          const isSelected = selected === mood.key;
          return (
            <button
              key={mood.key}
              onClick={() => onSelect(mood.key)}
              role="radio"
              aria-checked={isSelected}
              className={cn(
                "flex min-h-[72px] items-center gap-4 rounded-xl border-2 px-5 py-4 text-left transition-all outline-none",
                "focus-visible:ring-2 focus-visible:ring-primary/50 focus-visible:ring-offset-2",
                "hover:border-primary hover:bg-primary/5",
                "active:scale-[0.97]",
                isSelected
                  ? "border-primary bg-primary/10"
                  : "border-border bg-white"
              )}
            >
              {Icon && <Icon className={cn("size-7 shrink-0", isSelected ? "text-primary" : "text-muted-foreground")} />}
              <div>
                <div className={cn("text-base font-semibold", isSelected ? "text-primary" : "text-foreground")}>
                  {mood.label}
                </div>
                <div className="text-sm text-muted-foreground">{mood.description}</div>
              </div>
            </button>
          );
        })}
      </div>
    </div>
  );
}
