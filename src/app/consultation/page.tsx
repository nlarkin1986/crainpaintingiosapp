"use client";

import { useState, useCallback } from "react";
import type { BMColor } from "@/types/colors";
import type { RoomType, MoodKey } from "@/types/consultation";
import { QuizCard } from "@/components/consultation/quiz-card";
import { QuizProgress } from "@/components/consultation/quiz-progress";
import { RoomTypeCard } from "@/components/consultation/room-type-card";
import { MoodCard } from "@/components/consultation/mood-card";
import { ColorSuggestionCard } from "@/components/consultation/color-suggestion-card";
import { ConsultationForm } from "@/components/consultation/consultation-form";

type Phase = "quiz" | "form";

export default function ConsultationPage() {
  const [phase, setPhase] = useState<Phase>("quiz");
  const [quizStep, setQuizStep] = useState(0);

  // Quiz state
  const [roomType, setRoomType] = useState<RoomType | undefined>();
  const [mood, setMood] = useState<MoodKey | undefined>();
  const [selectedColors, setSelectedColors] = useState<BMColor[]>([]);
  const [suggestions, setSuggestions] = useState<BMColor[]>([]);
  const [suggestionsMessage, setSuggestionsMessage] = useState("Here are some colors we think you'll love");
  const [suggestionsLoading, setSuggestionsLoading] = useState(false);
  const [refinementRound, setRefinementRound] = useState(0);

  const totalQuizSteps = 3;

  const fetchSuggestions = useCallback(async (room: RoomType, moodKey: MoodKey, round: number) => {
    setSuggestionsLoading(true);
    try {
      const res = await fetch("/api/consultation/quiz", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          roomType: room,
          mood: moodKey,
          selectedColors: selectedColors.map(c => c.number),
          round,
        }),
      });
      const data = await res.json();
      if (data.suggestions) {
        setSuggestions(data.suggestions);
        setSuggestionsMessage(data.message || "Here are some colors we think you'll love");
      }
    } catch {
      setSuggestionsMessage("We couldn't load suggestions right now. You can still search for colors manually.");
    } finally {
      setSuggestionsLoading(false);
    }
  }, [selectedColors]);

  const handleRoomSelect = (room: RoomType) => {
    setRoomType(room);
    setQuizStep(1);
  };

  const handleMoodSelect = async (moodKey: MoodKey) => {
    setMood(moodKey);
    setQuizStep(2);
    if (roomType) {
      await fetchSuggestions(roomType, moodKey, 0);
    }
  };

  const handleToggleColor = (color: BMColor) => {
    setSelectedColors((prev) =>
      prev.some((c) => c.number === color.number)
        ? prev.filter((c) => c.number !== color.number)
        : [...prev, color]
    );
  };

  const handleRefine = async () => {
    const newRound = refinementRound + 1;
    setRefinementRound(newRound);
    if (roomType && mood) {
      await fetchSuggestions(roomType, mood, newRound);
    }
  };

  const handleSkipToForm = () => {
    setPhase("form");
  };

  const handleContinueToForm = () => {
    setPhase("form");
  };

  const handleQuizBack = () => {
    if (quizStep > 0) {
      setQuizStep(quizStep - 1);
    }
  };

  if (phase === "form") {
    return (
      <ConsultationForm
        selectedColors={selectedColors}
        onUpdateColors={setSelectedColors}
        roomType={roomType || "Living Room"}
        mood={mood || "clean_modern"}
      />
    );
  }

  return (
    <div>
      <QuizProgress currentStep={quizStep} totalSteps={totalQuizSteps} />

      {quizStep === 0 && (
        <QuizCard
          showBack={false}
          onSkip={selectedColors.length > 0 ? handleSkipToForm : undefined}
        >
          <RoomTypeCard onSelect={handleRoomSelect} selected={roomType} />
        </QuizCard>
      )}

      {quizStep === 1 && (
        <QuizCard
          onBack={handleQuizBack}
          onSkip={selectedColors.length > 0 ? handleSkipToForm : undefined}
        >
          <MoodCard onSelect={handleMoodSelect} selected={mood} />
        </QuizCard>
      )}

      {quizStep === 2 && (
        <QuizCard
          onBack={handleQuizBack}
          onSkip={selectedColors.length > 0 ? handleSkipToForm : undefined}
        >
          <ColorSuggestionCard
            suggestions={suggestions}
            selectedColors={selectedColors}
            onToggleColor={handleToggleColor}
            onRefine={handleRefine}
            onContinue={handleContinueToForm}
            isLoading={suggestionsLoading}
            message={suggestionsMessage}
            round={refinementRound}
          />
        </QuizCard>
      )}
    </div>
  );
}
