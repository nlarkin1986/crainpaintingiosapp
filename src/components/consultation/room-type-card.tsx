"use client";

import { ROOM_TYPES } from "@/types/consultation";
import type { RoomType } from "@/types/consultation";
import { cn } from "@/lib/utils";
import {
  Sofa, CookingPot, BedDouble, Bath, UtensilsCrossed,
  Monitor, DoorOpen, TreePine, MoreHorizontal
} from "lucide-react";

const ROOM_ICONS: Record<RoomType, React.ComponentType<{ className?: string }>> = {
  "Living Room": Sofa,
  "Kitchen": CookingPot,
  "Bedroom": BedDouble,
  "Bathroom": Bath,
  "Dining Room": UtensilsCrossed,
  "Home Office": Monitor,
  "Hallway / Entryway": DoorOpen,
  "Exterior": TreePine,
  "Other": MoreHorizontal,
};

interface RoomTypeCardProps {
  onSelect: (room: RoomType) => void;
  selected?: RoomType;
}

export function RoomTypeCard({ onSelect, selected }: RoomTypeCardProps) {
  return (
    <div className="w-full max-w-lg">
      <h2 className="mb-2 text-center font-heading text-2xl font-bold md:text-3xl">
        What room are you painting?
      </h2>
      <p className="mb-6 text-center text-lg text-muted-foreground">
        Select the type of room for your color consultation
      </p>

      <div role="radiogroup" aria-label="Room type" className="grid grid-cols-2 gap-3 sm:grid-cols-3">
        {ROOM_TYPES.map((room) => {
          const Icon = ROOM_ICONS[room];
          const isSelected = selected === room;
          return (
            <button
              key={room}
              onClick={() => onSelect(room)}
              role="radio"
              aria-checked={isSelected}
              className={cn(
                "flex min-h-[80px] flex-col items-center justify-center gap-2 rounded-xl border-2 p-4 transition-all outline-none",
                "focus-visible:ring-2 focus-visible:ring-primary/50 focus-visible:ring-offset-2",
                "hover:border-primary hover:bg-primary/5",
                "active:scale-[0.97]",
                isSelected
                  ? "border-primary bg-primary/10 text-primary"
                  : "border-border bg-white text-foreground"
              )}
            >
              <Icon className="size-6" />
              <span className="text-sm font-medium leading-tight text-center">{room}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
}
