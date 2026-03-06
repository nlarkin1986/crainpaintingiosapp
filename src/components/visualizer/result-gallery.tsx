"use client";

import { useState } from "react";
import type { ColorResult } from "@/types/colors";
import { ResultCard } from "./result-card";
import { SaveProposalModal } from "./save-proposal-modal";
import { Button } from "@/components/ui/button";
import { EstimateCTA } from "@/components/shared/estimate-cta";
import { Download, Palette, RotateCcw, Bookmark, Check } from "lucide-react";

interface ResultGalleryProps {
  results: ColorResult[];
  onRemove: (colorNumber: string) => void;
  onRetry: (colorNumber: string) => void;
  onAddAnotherColor: () => void;
  onStartOver: () => void;
  onCancelGeneration: () => void;
  surface: string;
  onSaved?: (proposalId: string) => void;
}

export function ResultGallery({
  results,
  onRemove,
  onRetry,
  onAddAnotherColor,
  onStartOver,
  onCancelGeneration,
  surface,
  onSaved,
}: ResultGalleryProps) {
  const [showSaveModal, setShowSaveModal] = useState(false);
  const [savedProposalId, setSavedProposalId] = useState<string | null>(null);

  const isGenerating = results.some(r => r.status === 'generating');
  const completedResults = results.filter(
    (r): r is Extract<ColorResult, { status: 'complete' }> => r.status === 'complete'
  );
  const totalCount = results.length;
  const completedCount = completedResults.length;
  const generatingIndex = results.findIndex(r => r.status === 'generating');

  const handleDownloadAll = async () => {
    for (const result of completedResults) {
      const safeName = result.color.name.toLowerCase().replace(/[^a-z0-9]+/g, '-');
      const safeNumber = result.color.number.replace(/[^a-zA-Z0-9-]/g, '');
      const link = document.createElement('a');
      link.href = result.resultUrl;
      link.download = `crain-${safeName}-${safeNumber}.jpg`;
      link.click();
      await new Promise(resolve => setTimeout(resolve, 500));
    }
  };

  const handleStartOver = () => {
    const confirmed = window.confirm(
      "Start over? This will clear your current photo and selections."
    );
    if (confirmed) onStartOver();
  };

  const handleSaved = (proposalId: string) => {
    setSavedProposalId(proposalId);
    setShowSaveModal(false);
    onSaved?.(proposalId);
  };

  return (
    <div className="flex flex-col gap-6">
      {/* Saved success banner */}
      {savedProposalId && (
        <div className="flex items-center gap-2 rounded-lg border border-green-200 bg-green-50 px-4 py-3 text-sm text-green-800">
          <Check className="h-4 w-4 shrink-0" />
          <span>Proposal saved.</span>
          <a
            href={`/admin/proposals/${savedProposalId}`}
            target="_blank"
            rel="noopener noreferrer"
            className="ml-auto font-medium text-green-700 hover:underline"
          >
            View in Admin
          </a>
        </div>
      )}

      {/* Progress / Status */}
      {isGenerating && (
        <div className="text-center">
          <div className="mb-2 inline-flex items-center gap-2 rounded-full bg-primary/10 px-4 py-2">
            <div className="h-2 w-2 animate-pulse rounded-full bg-primary-fill" />
            <span className="text-sm font-medium text-primary">
              Generating {generatingIndex + 1} of {totalCount}...
            </span>
          </div>
        </div>
      )}

      {!isGenerating && completedCount > 0 && (
        <div className="text-center">
          <h2 className="text-xl font-bold text-foreground sm:text-2xl">
            Your Visualizations
          </h2>
          <p className="mt-1 text-base text-muted-foreground">
            {completedCount} {completedCount === 1 ? 'color' : 'colors'} generated -- slide to compare
          </p>
        </div>
      )}

      {/* Global Actions */}
      <div className="flex flex-wrap gap-2">
        {results.length < 5 && (
          <Button
            variant="outline"
            size="lg"
            className="h-11 gap-2 text-sm"
            onClick={onAddAnotherColor}
            disabled={isGenerating}
          >
            <Palette className="h-4 w-4" />
            Add Another Color
          </Button>
        )}
        {completedCount >= 1 && !isGenerating && (
          <Button
            variant="outline"
            size="lg"
            className="h-11 gap-2 text-sm"
            onClick={() => setShowSaveModal(true)}
            disabled={!!savedProposalId}
          >
            <Bookmark className="h-4 w-4" />
            {savedProposalId ? 'Saved' : 'Save as Proposal'}
          </Button>
        )}
        {completedCount >= 2 && (
          <Button
            variant="outline"
            size="lg"
            className="h-11 gap-2 text-sm"
            onClick={handleDownloadAll}
            disabled={isGenerating}
          >
            <Download className="h-4 w-4" />
            Download All
          </Button>
        )}
        {isGenerating && (
          <Button
            variant="outline"
            size="lg"
            className="h-11 gap-2 text-sm"
            onClick={onCancelGeneration}
          >
            <RotateCcw className="h-4 w-4" />
            Cancel Generation
          </Button>
        )}
      </div>

      {/* Gallery Grid */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        {results.map((result) => (
          <ResultCard
            key={result.color.number}
            result={result}
            onRemove={() => onRemove(result.color.number)}
            onRetry={() => onRetry(result.color.number)}
            isGenerating={isGenerating}
          />
        ))}
      </div>

      {/* Estimate CTA */}
      {completedCount > 0 && !isGenerating && <EstimateCTA />}

      {/* Start Over */}
      {!isGenerating && (
        <Button
          variant="ghost"
          size="lg"
          className="h-12 text-base text-muted-foreground"
          onClick={handleStartOver}
        >
          <RotateCcw className="h-4 w-4" />
          Start Over
        </Button>
      )}

      {/* Save Proposal Modal */}
      {showSaveModal && (
        <SaveProposalModal
          results={completedResults}
          onClose={() => setShowSaveModal(false)}
          onSaved={handleSaved}
          surface={surface}
        />
      )}
    </div>
  );
}
