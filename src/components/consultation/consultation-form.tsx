"use client";

import { useState } from "react";
import type { BMColor } from "@/types/colors";
import type { PackageType, WindowDirection } from "@/types/consultation";
import { CONSULTATION_PACKAGES, WINDOW_DIRECTIONS, SURFACE_TYPES } from "@/types/consultation";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  X, Plus, Upload, MapPin, Mail, CreditCard,
  Check, ChevronRight, Loader2, Camera, ArrowLeft,
  Compass
} from "lucide-react";
import { searchColors } from "@/lib/colors";

interface ConsultationFormProps {
  selectedColors: BMColor[];
  onUpdateColors: (colors: BMColor[]) => void;
  roomType: string;
  mood: string;
}

export function ConsultationForm({
  selectedColors,
  onUpdateColors,
  roomType,
  mood,
}: ConsultationFormProps) {
  const [step, setStep] = useState(0);
  const [photos, setPhotos] = useState<File[]>([]);
  const [photoPreviews, setPhotoPreviews] = useState<string[]>([]);
  const [surfaceType, setSurfaceType] = useState("");
  const [windowDirection, setWindowDirection] = useState<WindowDirection | "">("");
  const [address, setAddress] = useState("");
  const [addressValidated, setAddressValidated] = useState(false);
  const [addressLoading, setAddressLoading] = useState(false);
  const [addressError, setAddressError] = useState("");
  const [email, setEmail] = useState("");
  const [packageType, setPackageType] = useState<PackageType | "">("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Color search state
  const [colorSearch, setColorSearch] = useState("");
  const [searchResults, setSearchResults] = useState<BMColor[]>([]);
  const [showColorSearch, setShowColorSearch] = useState(false);

  const steps = [
    "Confirm Colors",
    "Upload Photos",
    "Room Details",
    "Your Address",
    "Email",
    "Select Package",
  ];

  const handleColorSearch = (query: string) => {
    setColorSearch(query);
    if (query.length >= 2) {
      const results = searchColors(query).slice(0, 12);
      setSearchResults(results);
    } else {
      setSearchResults([]);
    }
  };

  const addColor = (color: BMColor) => {
    if (!selectedColors.some((c) => c.number === color.number)) {
      onUpdateColors([...selectedColors, color]);
    }
    setColorSearch("");
    setSearchResults([]);
    setShowColorSearch(false);
  };

  const removeColor = (colorNumber: string) => {
    onUpdateColors(selectedColors.filter((c) => c.number !== colorNumber));
  };

  const handlePhotoUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || []);
    const newPhotos = [...photos, ...files].slice(0, 10);
    setPhotos(newPhotos);

    const previews = newPhotos.map((f) => URL.createObjectURL(f));
    setPhotoPreviews(previews);
  };

  const removePhoto = (index: number) => {
    const newPhotos = photos.filter((_, i) => i !== index);
    setPhotos(newPhotos);
    URL.revokeObjectURL(photoPreviews[index]);
    setPhotoPreviews(photoPreviews.filter((_, i) => i !== index));
  };

  const validateAddress = async () => {
    if (!address.trim() || address.trim().length < 5) {
      setAddressError("Please enter a full address");
      return;
    }
    setAddressLoading(true);
    setAddressError("");
    try {
      const res = await fetch("/api/consultation/geocode", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ address }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setAddressValidated(true);
      setAddress(data.formattedAddress || address);
    } catch (err) {
      setAddressError(err instanceof Error ? err.message : "Address validation failed");
    } finally {
      setAddressLoading(false);
    }
  };

  const canProceed = () => {
    switch (step) {
      case 0: return selectedColors.length > 0;
      case 1: return photos.length > 0;
      case 2: return surfaceType !== "" && windowDirection !== "";
      case 3: return addressValidated;
      case 4: return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
      case 5: return packageType !== "";
      default: return false;
    }
  };

  const handleSubmit = async () => {
    setIsSubmitting(true);
    // TODO: Upload photos to Supabase, create order, initiate Stripe checkout
    // For now, this is a placeholder
    console.log("Submitting consultation:", {
      selectedColors: selectedColors.map(c => c.number),
      photos: photos.length,
      surfaceType,
      windowDirection,
      address,
      email,
      packageType,
      roomType,
      mood,
    });
    setIsSubmitting(false);
  };

  return (
    <div className="mx-auto max-w-lg px-4 py-6">
      {/* Progress bar */}
      <div className="mb-8">
        <div className="mb-3 flex items-center justify-between text-sm text-muted-foreground">
          <span className="font-medium">Step {step + 1} of {steps.length}</span>
          <span>{steps[step]}</span>
        </div>
        <div className="h-1 overflow-hidden rounded-full bg-border">
          <div
            className="h-full rounded-full bg-foreground transition-all duration-300"
            style={{ width: `${((step + 1) / steps.length) * 100}%` }}
          />
        </div>
      </div>

      {/* Step 0: Confirm Colors */}
      {step === 0 && (
        <div className="animate-[stepFadeIn_0.3s_ease-out]">
          <h2 className="mb-2 font-heading text-2xl font-bold">Confirm Your Colors</h2>
          <p className="mb-6 text-lg text-muted-foreground">
            These colors will guide our recommendations
          </p>

          <div className="mb-4 flex flex-wrap gap-2">
            {selectedColors.map((color) => (
              <Badge
                key={color.number}
                variant="outline"
                className="gap-2 border-border px-3 py-2 text-sm"
              >
                <div
                  className="size-4 rounded-full border"
                  style={{ backgroundColor: `#${color.hex}` }}
                />
                {color.name}
                <button
                  onClick={() => removeColor(color.number)}
                  aria-label="Remove color"
                  className="p-1 -m-1 rounded-full hover:bg-muted"
                >
                  <X className="size-3" />
                </button>
              </Badge>
            ))}
          </div>

          {!showColorSearch ? (
            <Button
              variant="outline"
              onClick={() => setShowColorSearch(true)}
              className="mb-4 gap-2"
            >
              <Plus className="size-4" />
              Add Color
            </Button>
          ) : (
            <div className="mb-4">
              <Input
                placeholder="Search Benjamin Moore colors..."
                value={colorSearch}
                onChange={(e) => handleColorSearch(e.target.value)}
                autoFocus
                className="mb-2"
              />
              {searchResults.length > 0 && (
                <div className="max-h-48 overflow-y-auto rounded-lg border bg-white">
                  {searchResults.map((color) => (
                    <button
                      key={color.number}
                      onClick={() => addColor(color)}
                      className="flex w-full items-center gap-3 px-3 py-2.5 text-left hover:bg-muted"
                    >
                      <div
                        className="size-6 rounded border"
                        style={{ backgroundColor: `#${color.hex}` }}
                      />
                      <div>
                        <div className="text-sm font-medium">{color.name}</div>
                        <div className="text-xs text-muted-foreground">{color.number}</div>
                      </div>
                    </button>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>
      )}

      {/* Step 1: Upload Photos */}
      {step === 1 && (
        <div className="animate-[stepFadeIn_0.3s_ease-out]">
          <h2 className="mb-2 font-heading text-2xl font-bold">Upload Room Photos</h2>
          <p className="mb-6 text-lg text-muted-foreground">
            Photos help us analyze your lighting and space (1-10 photos)
          </p>

          {photos.length === 0 ? (
            <label className="mb-4 flex cursor-pointer flex-col items-center justify-center gap-3 rounded-xl border-2 border-dashed border-border bg-muted py-16 text-muted-foreground hover:border-primary hover:text-primary transition-colors">
              <Camera className="size-10" />
              <div className="text-center">
                <span className="text-base font-medium">Upload room photos</span>
                <span className="block text-sm">Click or drag to add up to 10 photos</span>
              </div>
              <input
                type="file"
                accept="image/*"
                multiple
                onChange={handlePhotoUpload}
                className="hidden"
              />
            </label>
          ) : (
            <div className="mb-4 grid grid-cols-3 gap-2">
              {photoPreviews.map((preview, i) => (
                <div key={i} className="group relative aspect-square overflow-hidden rounded-lg">
                  <img src={preview} alt="" className="size-full object-cover" />
                  <button
                    onClick={() => removePhoto(i)}
                    aria-label="Remove photo"
                    className="absolute right-1 top-1 rounded-full bg-black/60 p-1 text-white opacity-0 transition-opacity group-hover:opacity-100"
                  >
                    <X className="size-3" />
                  </button>
                </div>
              ))}
              {photos.length < 10 && (
                <label className="flex aspect-square cursor-pointer flex-col items-center justify-center gap-1 rounded-lg border-2 border-dashed border-border bg-muted text-muted-foreground hover:border-primary hover:text-primary transition-colors">
                  <Camera className="size-6" />
                  <span className="text-xs">Add Photo</span>
                  <input
                    type="file"
                    accept="image/*"
                    multiple
                    onChange={handlePhotoUpload}
                    className="hidden"
                  />
                </label>
              )}
            </div>
          )}
        </div>
      )}

      {/* Step 2: Room Details */}
      {step === 2 && (
        <div className="animate-[stepFadeIn_0.3s_ease-out]">
          <h2 className="mb-2 font-heading text-2xl font-bold">Room Details</h2>
          <p className="mb-6 text-lg text-muted-foreground">
            Tell us about the surfaces and lighting
          </p>

          <div className="mb-6">
            <label className="mb-2 block text-sm font-medium">Surface Type</label>
            <div role="radiogroup" aria-label="Surface type" className="grid grid-cols-2 gap-2 sm:grid-cols-3">
              {SURFACE_TYPES.map((surface) => (
                <button
                  key={surface}
                  onClick={() => setSurfaceType(surface)}
                  role="radio"
                  aria-checked={surfaceType === surface}
                  className={cn(
                    "rounded-lg border-2 px-3 py-3 text-sm font-medium transition-all outline-none focus-visible:ring-2 focus-visible:ring-primary/50 focus-visible:ring-offset-2",
                    surfaceType === surface
                      ? "border-primary bg-primary/10 text-primary"
                      : "border-border hover:border-primary/50"
                  )}
                >
                  {surface}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="mb-2 flex items-center gap-2 text-sm font-medium">
              <Compass className="size-4" />
              Window Direction
            </label>
            <div role="radiogroup" aria-label="Window direction" className="grid grid-cols-2 gap-2 sm:grid-cols-3">
              {WINDOW_DIRECTIONS.map((dir) => {
                const isIDontKnow = dir.key === "unknown";
                return (
                  <button
                    key={dir.key}
                    onClick={() => setWindowDirection(dir.key as WindowDirection)}
                    role="radio"
                    aria-checked={windowDirection === dir.key}
                    className={cn(
                      "rounded-lg border-2 px-3 py-2.5 text-left transition-all outline-none focus-visible:ring-2 focus-visible:ring-primary/50 focus-visible:ring-offset-2",
                      windowDirection === dir.key
                        ? "border-primary bg-primary/10"
                        : "border-border hover:border-primary/50",
                      isIDontKnow && "col-span-full"
                    )}
                  >
                    <div className={cn("text-sm font-semibold", windowDirection === dir.key ? "text-primary" : "")}>
                      {dir.label}
                    </div>
                    <div className="text-xs text-muted-foreground line-clamp-1">{dir.description}</div>
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {/* Step 3: Address */}
      {step === 3 && (
        <div className="animate-[stepFadeIn_0.3s_ease-out]">
          <h2 className="mb-2 font-heading text-2xl font-bold">Your Address</h2>
          <p className="mb-2 text-lg text-muted-foreground">
            We use your address to calculate how sunlight enters your room throughout the day
          </p>
          <p className="mb-6 text-xs text-muted-foreground">
            We never share or sell your information. Only city/state appears on your report.
          </p>

          <div className="flex gap-2">
            <Input
              placeholder="123 Main St, City, State ZIP"
              value={address}
              onChange={(e) => {
                setAddress(e.target.value);
                setAddressValidated(false);
                setAddressError("");
              }}
              className="flex-1"
            />
            <Button
              onClick={validateAddress}
              disabled={addressLoading || !address.trim()}
              variant="outline"
              className="shrink-0"
              aria-label="Validate address"
            >
              {addressLoading ? (
                <Loader2 className="size-4 animate-spin" />
              ) : addressValidated ? (
                <Check className="size-4 text-green-600" />
              ) : (
                <MapPin className="size-4" />
              )}
            </Button>
          </div>
          {addressError && (
            <p className="mt-2 text-sm text-red-500">{addressError}</p>
          )}
          {addressValidated && (
            <p className="mt-2 text-sm text-green-600">Address verified</p>
          )}
        </div>
      )}

      {/* Step 4: Email */}
      {step === 4 && (
        <div className="animate-[stepFadeIn_0.3s_ease-out]">
          <h2 className="mb-2 font-heading text-2xl font-bold">Your Email</h2>
          <p className="mb-6 text-lg text-muted-foreground">
            We&apos;ll send your color report to this email
          </p>

          <Input
            type="email"
            placeholder="you@example.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="text-lg"
          />
        </div>
      )}

      {/* Step 5: Package Selection */}
      {step === 5 && (
        <div className="animate-[stepFadeIn_0.3s_ease-out]">
          <h2 className="mb-2 font-heading text-2xl font-bold">Choose Your Package</h2>
          <p className="mb-6 text-lg text-muted-foreground">
            Select the consultation level that fits your project
          </p>

          <div role="radiogroup" aria-label="Package selection" className="flex flex-col gap-3">
            {Object.values(CONSULTATION_PACKAGES).map((pkg) => (
              <button
                key={pkg.key}
                onClick={() => setPackageType(pkg.key)}
                role="radio"
                aria-checked={packageType === pkg.key}
                className={cn(
                  "relative rounded-xl border-2 p-4 text-left transition-all outline-none focus-visible:ring-2 focus-visible:ring-primary/50 focus-visible:ring-offset-2",
                  packageType === pkg.key
                    ? "border-primary bg-primary/5"
                    : pkg.popular
                      ? "border-primary/30 bg-primary/[0.02] shadow-md hover:border-primary/50"
                      : "border-border hover:border-primary/50"
                )}
              >
                {pkg.popular && (
                  <Badge className="absolute -top-3 right-3 bg-accent text-accent-foreground text-xs shadow-sm">
                    Most Popular
                  </Badge>
                )}
                <div className="flex items-baseline justify-between">
                  <h3 className="font-heading text-lg font-bold">{pkg.name}</h3>
                  <span className="text-xl font-bold text-primary">{pkg.priceDisplay}</span>
                </div>
                <p className="mt-1 text-sm text-muted-foreground">{pkg.description}</p>
                <div className="mt-2 text-xs text-muted-foreground">
                  {pkg.roomCount} · {pkg.turnaround}
                </div>
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Navigation buttons */}
      <div className="sticky bottom-0 bg-background/95 backdrop-blur-sm pt-4 pb-6 mt-8 -mx-4 px-4 border-t border-border/50 flex gap-3">
        {step > 0 && (
          <Button
            variant="outline"
            onClick={() => setStep(step - 1)}
            className="gap-1.5"
          >
            <ArrowLeft className="size-4" />
            Back
          </Button>
        )}

        {step < steps.length - 1 ? (
          <Button
            onClick={() => setStep(step + 1)}
            disabled={!canProceed()}
            className="ml-auto gap-1.5"
          >
            Continue
            <ChevronRight className="size-4" />
          </Button>
        ) : (
          <Button
            onClick={handleSubmit}
            disabled={!canProceed() || isSubmitting}
            variant="cta"
            className="ml-auto gap-1.5"
          >
            {isSubmitting ? (
              <Loader2 className="size-4 animate-spin" />
            ) : (
              <CreditCard className="size-4" />
            )}
            Proceed to Payment
          </Button>
        )}
      </div>
    </div>
  );
}
