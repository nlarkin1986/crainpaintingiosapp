"use client";

import { ReactNode } from "react";
import { cn } from "@/lib/utils";
import { ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";

interface QuizCardProps {
  children: ReactNode;
  onBack?: () => void;
  showBack?: boolean;
  onSkip?: () => void;
  className?: string;
}

export function QuizCard({ children, onBack, showBack = true, onSkip, className }: QuizCardProps) {
  return (
    <div className={cn(
      "flex min-h-[calc(100dvh-4rem)] flex-col px-4 py-6 md:px-6",
      "animate-[stepFadeIn_0.3s_ease-out]",
      className
    )}>
      {/* Top bar */}
      <div className="mb-6 flex items-center justify-between">
        {showBack && onBack ? (
          <Button
            variant="ghost"
            size="sm"
            onClick={onBack}
            className="gap-1.5 text-muted-foreground"
          >
            <ArrowLeft className="size-4" />
            Back
          </Button>
        ) : (
          <div />
        )}
        {onSkip && (
          <Button
            variant="ghost"
            size="sm"
            onClick={onSkip}
            className="text-muted-foreground underline-offset-4 hover:text-foreground"
          >
            I know what I want →
          </Button>
        )}
      </div>

      {/* Content */}
      <div className="flex flex-1 flex-col items-center justify-center">
        {children}
      </div>
    </div>
  );
}
