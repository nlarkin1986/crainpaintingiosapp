"use client";

import { cn } from "@/lib/utils";

interface QuizProgressProps {
  currentStep: number;
  totalSteps: number;
}

export function QuizProgress({ currentStep, totalSteps }: QuizProgressProps) {
  return (
    <div className="flex items-center justify-center gap-2 py-4">
      {Array.from({ length: totalSteps }).map((_, i) => (
        <div
          key={i}
          className={cn(
            "h-2 rounded-full transition-all duration-300",
            i === currentStep
              ? "w-8 bg-primary-fill"
              : i < currentStep
                ? "w-2 bg-primary-fill/50"
                : "w-2 bg-muted"
          )}
        />
      ))}
    </div>
  );
}
