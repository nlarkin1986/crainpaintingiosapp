"use client";

import { useState, useRef, useEffect } from "react";
import Image from "next/image";
import type { BMColor, ColorResult } from "@/types/colors";
import { StepProgress } from "@/components/visualizer/step-progress";
import { ColorPicker } from "@/components/visualizer/color-picker";
import { PhotoUpload } from "@/components/visualizer/photo-upload";
import { SurfacePicker } from "@/components/visualizer/surface-picker";
import { ResultGallery } from "@/components/visualizer/result-gallery";

export default function HomePage() {
  const [currentStep, setCurrentStep] = useState(1);
  const [selectedColors, setSelectedColors] = useState<BMColor[]>([]);
  const [photo, setPhoto] = useState<File | null>(null);
  const [selectedSurface, setSelectedSurface] = useState("");
  const [customInstruction, setCustomInstruction] = useState("");
  const [results, setResults] = useState<ColorResult[]>([]);
  const [savedProposalId, setSavedProposalId] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const abortControllerRef = useRef<AbortController | null>(null);

  // Derived state
  const isGenerating = results.some(r => r.status === 'generating');

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      abortControllerRef.current?.abort();
    };
  }, []);

  // Warn before leaving with unsaved results
  const hasUnsavedResults = results.some(r => r.status === 'complete') && !savedProposalId;
  useEffect(() => {
    if (!hasUnsavedResults) return;
    const handler = (e: BeforeUnloadEvent) => {
      e.preventDefault();
    };
    window.addEventListener('beforeunload', handler);
    return () => window.removeEventListener('beforeunload', handler);
  }, [hasUnsavedResults]);

  const handleSelectSurface = (surface: string) => {
    if (surface === selectedSurface) {
      setSelectedSurface("");
    } else {
      setSelectedSurface(surface);
    }
    if (surface !== "custom") {
      setCustomInstruction("");
    }
  };

  const handleToggleColor = (color: BMColor) => {
    setSelectedColors(prev => {
      const exists = prev.some(c => c.number === color.number);
      if (exists) {
        return prev.filter(c => c.number !== color.number);
      }
      return [...prev, color];
    });
  };

  const generateResults = async (colorsToGenerate: BMColor[]) => {
    abortControllerRef.current = new AbortController();

    for (let i = 0; i < colorsToGenerate.length; i++) {
      const color = colorsToGenerate[i];

      if (abortControllerRef.current.signal.aborted) break;

      setResults(prev => prev.map(r =>
        r.color.number === color.number
          ? { status: 'generating' as const, color }
          : r
      ));

      try {
        const formData = new FormData();
        formData.append("image", photo!);
        formData.append("colorName", color.name);
        formData.append("colorHex", color.hex);
        formData.append("colorNumber", color.number);
        formData.append("surface", selectedSurface);
        formData.append("brand", color.brand ?? "benjamin_moore");
        if (customInstruction.trim()) {
          formData.append("customInstruction", customInstruction.trim());
        }

        const response = await fetch("/api/visualize", {
          method: "POST",
          body: formData,
          signal: abortControllerRef.current.signal,
        });

        if (response.status === 429) {
          setResults(prev => prev.map(r =>
            r.color.number === color.number
              ? { status: 'failed' as const, color, error: 'Rate limit reached. Try again in a few minutes.' }
              : r.status === 'pending'
              ? { status: 'failed' as const, color: r.color, error: 'Skipped — rate limit reached.' }
              : r
          ));
          break;
        }

        if (!response.ok) {
          const data = await response.json().catch(() => ({}));
          throw new Error(data.error || "Something went wrong.");
        }

        const data = await response.json();

        setResults(prev => prev.map(r =>
          r.color.number === color.number
            ? {
                status: 'complete' as const,
                color,
                originalUrl: data.originalUrl,
                resultUrl: data.resultUrl,
                shareId: data.shareId,
              }
            : r
        ));
      } catch (error) {
        if (error instanceof Error && error.name === 'AbortError') return;

        setResults(prev => prev.map(r =>
          r.color.number === color.number
            ? { status: 'failed' as const, color, error: 'Something went wrong. Tap to retry.' }
            : r
        ));
      }
    }
  };

  const handleSubmit = async () => {
    if (isSubmitting || isGenerating) return;
    if (!photo || selectedColors.length === 0 || !selectedSurface) return;
    if (selectedSurface === "custom" && !customInstruction.trim()) return;

    const existingCompleted = results
      .filter((r): r is Extract<ColorResult, { status: 'complete' }> => r.status === 'complete');
    const existingNumbers = new Set(existingCompleted.map(r => r.color.number));
    const newColors = selectedColors.filter(c => !existingNumbers.has(c.number));
    if (newColors.length === 0) return;

    const newResults: ColorResult[] = [
      ...existingCompleted,
      ...newColors.map(color => ({ status: 'pending' as const, color })),
    ];

    setIsSubmitting(true);
    setSavedProposalId(null);
    try {
      setResults(newResults);
      setCurrentStep(4);
      await generateResults(newColors);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleAddAnotherColor = () => {
    abortControllerRef.current?.abort();
    setSelectedColors(
      results
        .filter((r): r is Extract<ColorResult, { status: 'complete' }> => r.status === 'complete')
        .map(r => r.color)
    );
    setCustomInstruction("");
    setCurrentStep(1);
  };

  const handleStartOver = () => {
    abortControllerRef.current?.abort();
    setSelectedColors([]);
    setPhoto(null);
    setSelectedSurface("");
    setCustomInstruction("");
    setResults([]);
    setSavedProposalId(null);
    setCurrentStep(1);
  };

  const handleRemove = (colorNumber: string) => {
    setResults(prev => prev.filter(r => r.color.number !== colorNumber));
    setSelectedColors(prev => prev.filter(c => c.number !== colorNumber));
  };

  const handleRetry = (colorNumber: string) => {
    if (isGenerating) return;

    const resultToRetry = results.find(r => r.color.number === colorNumber);
    if (!resultToRetry || resultToRetry.status !== 'failed') return;

    setResults(prev => prev.map(r =>
      r.color.number === colorNumber
        ? { status: 'pending' as const, color: r.color }
        : r
    ));
    setSavedProposalId(null);

    generateResults([resultToRetry.color]);
  };

  const handleCancelGeneration = () => {
    abortControllerRef.current?.abort();
    setResults(prev =>
      prev.map((result) => {
        if (result.status === "generating" || result.status === "pending") {
          return {
            status: "failed" as const,
            color: result.color,
            error: "Generation cancelled. Tap to retry.",
          };
        }
        return result;
      })
    );
  };

  const surfaceLabel =
    selectedSurface === "custom"
      ? customInstruction.trim() || "Custom / Other"
      : selectedSurface;

  return (
    <main className="min-h-dvh bg-background">
      <div className="mx-auto max-w-2xl px-4 pb-8 pt-6">
        {/* Header with Crain branding */}
        <header className="mb-8 text-center">
          <div className="mb-3 flex justify-center">
            <Image
              src="/crain-logo.png"
              alt="Crain Painting Contractors"
              width={280}
              height={140}
              className="h-auto w-[180px] sm:w-[220px]"
              priority
            />
          </div>
          <p className="text-sm font-medium tracking-wide text-muted-foreground">
            See your room in a new color
          </p>
        </header>

        {/* Step Progress */}
        {currentStep <= 3 && (
          <StepProgress currentStep={currentStep} totalSteps={3} />
        )}

        {/* Step Content */}
        <div className="step-content">
          {currentStep === 1 && (
            <ColorPicker
              selectedColors={selectedColors}
              onToggleColor={handleToggleColor}
              onNext={() => setCurrentStep(2)}
            />
          )}
          {currentStep === 2 && (
            <PhotoUpload
              photo={photo}
              onPhotoSelected={setPhoto}
              onNext={() => setCurrentStep(3)}
              onBack={() => setCurrentStep(1)}
            />
          )}
          {currentStep === 3 && (
            <SurfacePicker
              selectedSurface={selectedSurface}
              onSelectSurface={handleSelectSurface}
              customInstruction={customInstruction}
              onCustomInstructionChange={setCustomInstruction}
              selectedColors={selectedColors}
              photo={photo}
              onSubmit={handleSubmit}
              onBack={() => setCurrentStep(2)}
              isSubmitting={isSubmitting}
            />
          )}
          {currentStep === 4 && (
            <ResultGallery
              results={results}
              onRemove={handleRemove}
              onRetry={handleRetry}
              onAddAnotherColor={handleAddAnotherColor}
              onStartOver={handleStartOver}
              surface={surfaceLabel}
              onSaved={setSavedProposalId}
              onCancelGeneration={handleCancelGeneration}
            />
          )}
        </div>
      </div>

      {/* Footer */}
      <footer className="border-t border-border/50 bg-muted/30 py-5 px-4">
        <div className="mx-auto max-w-2xl text-center">
          <p className="text-sm font-medium text-muted-foreground">
            Crain Painting Contractors &bull; Trusted since 1952
          </p>
          <p className="mt-1.5 text-xs text-muted-foreground/70">
            <a
              href="https://crainpaintingcontractors.com/contact-us"
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-primary transition-colors"
            >
              Contact Us
            </a>
            {" \u2022 "}
            <a
              href="https://crainpaintingcontractors.com"
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-primary transition-colors"
            >
              crainpaintingcontractors.com
            </a>
          </p>
        </div>
      </footer>
    </main>
  );
}
