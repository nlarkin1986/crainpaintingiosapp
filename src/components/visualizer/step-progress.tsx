"use client";

import { cn } from "@/lib/utils";
import { Check, Palette, Camera, Layers } from "lucide-react";

interface StepProgressProps {
  currentStep: number;
  totalSteps: number;
}

const STEP_LABELS = [
  { label: "Color", icon: Palette },
  { label: "Photo", icon: Camera },
  { label: "Surface", icon: Layers },
];

export function StepProgress({ currentStep, totalSteps }: StepProgressProps) {
  const steps = STEP_LABELS.slice(0, totalSteps);

  return (
    <div className="mb-8 px-4">
      {/* Container with equal columns */}
      <div
        className="relative grid"
        style={{ gridTemplateColumns: `repeat(${totalSteps}, 1fr)` }}
      >
        {/* Connecting lines layer — rendered first, behind circles */}
        {steps.map((_, i) => {
          if (i >= totalSteps - 1) return null;
          const isFilled = i + 1 < currentStep;
          return (
            <div
              key={`line-${i}`}
              className="pointer-events-none absolute top-5 h-0.5 -translate-y-1/2"
              style={{
                left: `${((i + 0.5) / totalSteps) * 100}%`,
                width: `${(1 / totalSteps) * 100}%`,
              }}
            >
              <div className="h-full w-full rounded-full bg-muted">
                <div
                  className={cn(
                    "h-full rounded-full bg-primary transition-all duration-500 ease-out",
                    isFilled ? "w-full" : "w-0"
                  )}
                />
              </div>
            </div>
          );
        })}

        {/* Step circles + labels */}
        {steps.map((step, i) => {
          const stepNum = i + 1;
          const isCompleted = stepNum < currentStep;
          const isCurrent = stepNum === currentStep;
          const isFuture = stepNum > currentStep;
          const Icon = step.icon;

          return (
            <div key={step.label} className="flex flex-col items-center gap-1.5">
              <div
                className={cn(
                  "relative z-10 flex h-10 w-10 items-center justify-center rounded-full border-2 transition-all duration-300",
                  isCompleted && "border-primary bg-primary text-primary-foreground",
                  isCurrent && "border-primary bg-primary/10 text-primary shadow-sm shadow-primary/20",
                  isFuture && "border-muted bg-muted text-muted-foreground"
                )}
                aria-label={`Step ${stepNum}${isCurrent ? " (current)" : isCompleted ? " (completed)" : ""}`}
              >
                {isCompleted ? (
                  <Check className="h-5 w-5" strokeWidth={2.5} />
                ) : (
                  <Icon className="h-4.5 w-4.5" strokeWidth={isCurrent ? 2 : 1.5} />
                )}
              </div>

              <span
                className={cn(
                  "text-xs font-medium transition-colors duration-300",
                  isCompleted && "text-primary",
                  isCurrent && "text-foreground",
                  isFuture && "text-muted-foreground"
                )}
              >
                {step.label}
              </span>
            </div>
          );
        })}
      </div>
    </div>
  );
}
