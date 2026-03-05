"use client";

import Link from "next/link";
import { Button } from "@/components/ui/button";

export function BottomCTA() {
  return (
    <section className="bg-[#F7F7F7] py-20 md:py-28">
      <div className="container mx-auto max-w-4xl px-6 text-center">
        {/* Heading */}
        <h2 className="mb-6 font-heading text-3xl font-bold text-foreground md:text-4xl lg:text-5xl">
          Ready to Get Expert Guidance?
        </h2>

        {/* Body Text */}
        <p className="mb-10 text-lg leading-relaxed text-muted-foreground md:text-xl">
          Start by visualizing your colors with our AI tool, then get a
          professional color report for your space.
        </p>

        {/* CTA Buttons */}
        <div className="flex flex-col items-center justify-center gap-4 sm:flex-row">
          <Button
            asChild
            variant="cta"
            size="lg"
            className="h-12 min-w-56 text-base font-semibold shadow-lg hover:shadow-xl"
          >
            <Link href="/consultation">Get Your Color Report</Link>
          </Button>
          <Button
            asChild
            variant="outline"
            size="lg"
            className="h-12 min-w-56 border-border bg-white text-base font-semibold text-foreground shadow-sm hover:bg-muted"
          >
            <Link href="/">Try the Visualizer Free</Link>
          </Button>
        </div>
      </div>
    </section>
  );
}
