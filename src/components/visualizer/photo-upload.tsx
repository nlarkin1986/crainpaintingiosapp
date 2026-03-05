"use client";

import { useState, useRef, useCallback } from "react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Camera, Image as ImageIcon, Upload, ArrowRight, ArrowLeft, Loader2 } from "lucide-react";
import { compressImage } from "@/lib/compress-image";

interface PhotoUploadProps {
  photo: File | null;
  onPhotoSelected: (file: File) => void;
  onNext: () => void;
  onBack: () => void;
}

export function PhotoUpload({
  photo,
  onPhotoSelected,
  onNext,
  onBack,
}: PhotoUploadProps) {
  const [isCompressing, setIsCompressing] = useState(false);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [isDragging, setIsDragging] = useState(false);
  const cameraInputRef = useRef<HTMLInputElement>(null);
  const libraryInputRef = useRef<HTMLInputElement>(null);
  const dragCounterRef = useRef(0);

  const handleFileSelect = async (file: File) => {
    setIsCompressing(true);

    try {
      const compressed = await compressImage(file);
      onPhotoSelected(compressed);
      const url = URL.createObjectURL(compressed);
      setPreviewUrl(url);
    } catch (error) {
      console.error("Error compressing image:", error);
      onPhotoSelected(file);
      const url = URL.createObjectURL(file);
      setPreviewUrl(url);
    } finally {
      setIsCompressing(false);
    }
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      handleFileSelect(file);
    }
  };

  const handleChangePhoto = () => {
    if (previewUrl) {
      URL.revokeObjectURL(previewUrl);
      setPreviewUrl(null);
    }
    onPhotoSelected(null as unknown as File);
  };

  const handleDragEnter = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    dragCounterRef.current++;
    if (e.dataTransfer.types.includes("Files")) {
      setIsDragging(true);
    }
  }, []);

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    dragCounterRef.current--;
    if (dragCounterRef.current === 0) {
      setIsDragging(false);
    }
  }, []);

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
  }, []);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    dragCounterRef.current = 0;
    setIsDragging(false);

    const file = e.dataTransfer.files?.[0];
    if (file && file.type.startsWith("image/")) {
      handleFileSelect(file);
    }
  }, []);

  return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div className="text-center">
        <h2 className="text-xl font-bold text-foreground sm:text-2xl">
          Upload a Photo
        </h2>
        <p className="mt-2 text-base text-muted-foreground">
          Take a picture or choose from your library
        </p>
      </div>

      {/* Upload Options or Preview */}
      <Card className="overflow-hidden p-0">
        {isCompressing ? (
          <div className="flex flex-col items-center justify-center gap-4 py-16">
            <Loader2 className="h-12 w-12 animate-spin text-primary" />
            <p className="text-lg text-muted-foreground">
              Preparing your photo...
            </p>
          </div>
        ) : photo && previewUrl ? (
          /* Photo Preview */
          <div className="animate-in fade-in duration-300">
            <div className="overflow-hidden">
              <img
                src={previewUrl}
                alt="Selected photo preview"
                className="h-auto w-full"
              />
            </div>
            <div className="p-4">
              <Button
                variant="outline"
                size="lg"
                onClick={handleChangePhoto}
                className="h-12 w-full text-lg"
              >
                Change Photo
              </Button>
            </div>
          </div>
        ) : (
          /* Upload Area */
          <div className="p-6">
            {/* Drag & Drop Zone */}
            <div
              onDragEnter={handleDragEnter}
              onDragLeave={handleDragLeave}
              onDragOver={handleDragOver}
              onDrop={handleDrop}
              onClick={() => libraryInputRef.current?.click()}
              className={`drop-zone mb-4 flex cursor-pointer flex-col items-center justify-center gap-3 rounded-xl border-2 border-dashed py-10 transition-all ${
                isDragging
                  ? "drop-zone-active border-primary bg-primary/5"
                  : "border-border hover:border-primary/40 hover:bg-muted/50"
              }`}
            >
              <div className="flex h-14 w-14 items-center justify-center rounded-full bg-primary/10">
                <Upload className="h-6 w-6 text-primary" />
              </div>
              <div className="text-center">
                <p className="text-base font-medium text-foreground">
                  Drag & drop a photo here
                </p>
                <p className="mt-1 text-sm text-muted-foreground">
                  or tap to browse your files
                </p>
              </div>
            </div>

            {/* Camera / Library Buttons */}
            <div className="grid grid-cols-2 gap-3">
              <button
                type="button"
                onClick={() => cameraInputRef.current?.click()}
                className="flex flex-col items-center gap-2 rounded-xl border border-border bg-background p-4 transition-all hover:border-primary/40 hover:shadow-sm active:scale-[0.98]"
              >
                <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary/10">
                  <Camera className="h-5 w-5 text-primary" />
                </div>
                <span className="text-sm font-medium text-foreground">Take Photo</span>
              </button>
              <button
                type="button"
                onClick={() => libraryInputRef.current?.click()}
                className="flex flex-col items-center gap-2 rounded-xl border border-border bg-background p-4 transition-all hover:border-primary/40 hover:shadow-sm active:scale-[0.98]"
              >
                <div className="flex h-10 w-10 items-center justify-center rounded-full bg-accent/10">
                  <ImageIcon className="h-5 w-5 text-accent" />
                </div>
                <span className="text-sm font-medium text-foreground">From Library</span>
              </button>
            </div>

            <input
              ref={cameraInputRef}
              type="file"
              accept="image/*"
              capture="environment"
              onChange={handleInputChange}
              className="hidden"
              aria-label="Take a photo"
            />
            <input
              ref={libraryInputRef}
              type="file"
              accept="image/*"
              onChange={handleInputChange}
              className="hidden"
              aria-label="Choose from library"
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
          onClick={onNext}
          disabled={!photo}
          size="lg"
          className="h-12 flex-1 gap-2 text-lg"
        >
          Next
          <ArrowRight className="h-5 w-5" />
        </Button>
      </div>
    </div>
  );
}
