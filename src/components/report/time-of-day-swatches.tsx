"use client";

import { Sunrise, Sun, Sunset } from "lucide-react";

interface TimeOfDaySwatchesProps {
  morningHex: string;
  afternoonHex: string;
  eveningHex: string;
}

export function TimeOfDaySwatches({
  morningHex,
  afternoonHex,
  eveningHex,
}: TimeOfDaySwatchesProps) {
  const swatches = [
    {
      label: "Morning",
      hex: morningHex,
      icon: Sunrise,
      description: "Cool, soft light",
    },
    {
      label: "Afternoon",
      hex: afternoonHex,
      icon: Sun,
      description: "Warm, direct light",
    },
    {
      label: "Evening",
      hex: eveningHex,
      icon: Sunset,
      description: "Golden, amber light",
    },
  ];

  return (
    <div className="flex items-stretch gap-3">
      {swatches.map(({ label, hex, icon: Icon, description }) => (
        <div
          key={label}
          className="flex-1 flex flex-col items-center gap-2 rounded-lg border border-border bg-card p-3"
        >
          <div
            className="w-full aspect-[3/2] rounded-md border border-border/60 shadow-sm"
            style={{ backgroundColor: hex }}
          />
          <div className="flex items-center gap-1.5 text-xs font-medium text-foreground">
            <Icon className="size-3.5 text-muted-foreground" />
            <span>{label}</span>
          </div>
          <span className="text-[10px] text-muted-foreground leading-tight text-center">
            {description}
          </span>
          <code className="text-[10px] font-mono text-muted-foreground uppercase">
            {hex}
          </code>
        </div>
      ))}
    </div>
  );
}
