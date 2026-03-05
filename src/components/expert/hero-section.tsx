"use client";

import Link from "next/link";
import Image from "next/image";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";

export function HeroSection() {
  return (
    <section className="bg-white py-20 md:py-32">
      <div className="container mx-auto max-w-5xl px-6">
        <div className="flex flex-col items-center text-center">
          {/* Badge */}
          <Badge
            variant="outline"
            className="mb-6 border-border bg-muted/50 text-foreground font-medium"
          >
            Expert Color Consultant
          </Badge>

          {/* Profile Photo */}
          <div className="mb-8 size-28 overflow-hidden rounded-full border-4 border-border md:size-32">
            <Image
              src="/curt-crain-profile.jpg"
              alt="Curt Crain — professional painter and color expert"
              width={256}
              height={256}
              className="size-full object-cover object-[center_20%]"
              priority
            />
          </div>

          {/* Name */}
          <h1 className="mb-6 font-heading text-4xl font-bold leading-tight text-foreground md:text-5xl lg:text-6xl">
            Curt Crain
          </h1>

          {/* Tagline */}
          <p className="mb-10 max-w-3xl text-lg leading-relaxed text-muted-foreground md:text-xl">
            Professional painter, fine artist, and color expert with 20+ years
            transforming spaces across residential and commercial projects.
          </p>

          {/* Credential Badges */}
          <div className="flex flex-wrap items-center justify-center gap-3">
            <Badge
              variant="outline"
              className="border-border bg-white px-4 py-2 text-sm text-foreground shadow-sm"
            >
              Commercial & Residential
            </Badge>
            <Badge
              variant="outline"
              className="border-border bg-white px-4 py-2 text-sm text-foreground shadow-sm"
            >
              Fine Artist
            </Badge>
            <Badge
              variant="outline"
              className="border-border bg-white px-4 py-2 text-sm text-foreground shadow-sm"
            >
              Benjamin Moore Specialist
            </Badge>
          </div>

          {/* CTA Buttons */}
          <div className="mt-10 flex flex-col items-center gap-4 sm:flex-row sm:justify-center">
            <Button asChild variant="cta" size="lg" className="h-12 min-w-56 text-base font-semibold shadow-lg">
              <Link href="#packages">Get Your Color Report</Link>
            </Button>
            <Button asChild variant="ghost" size="lg" className="text-foreground underline underline-offset-4 hover:bg-muted">
              <Link href="/">Try the Visualizer Free</Link>
            </Button>
          </div>
        </div>
      </div>
    </section>
  );
}
