"use client";

import Link from "next/link";
import { MessageSquare, Star, Home, Check } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";

const packages = [
  {
    id: "quick_review",
    name: "Quick Color Review",
    price: 49,
    icon: MessageSquare,
    scope: "1 room",
    turnaround: "24-48 hours",
    popular: false,
    ctaLabel: "Get Color Review",
    ctaVariant: "outline" as const,
    features: [
      "Color palette recommendations",
      "3-5 Benjamin Moore color options",
      "Basic lighting considerations",
      "Finish recommendations (matte, eggshell, etc.)",
      "Written summary of recommendations",
    ],
  },
  {
    id: "detailed_analysis",
    name: "Detailed Color Analysis",
    price: 149,
    icon: Star,
    scope: "Up to 3 rooms",
    turnaround: "3-5 business days",
    popular: true,
    ctaLabel: "Get Detailed Analysis",
    ctaVariant: "cta" as const,
    features: [
      "Everything in Quick Review, plus:",
      "Detailed color rationale & mood analysis",
      "Trim, ceiling, and accent wall guidance",
      "Color flow between connected spaces",
      "Alternative palette options",
      "Product-specific recommendations",
      "30-minute video walkthrough of your report",
    ],
  },
  {
    id: "whole_home",
    name: "Whole Home Color Plan",
    price: 399,
    icon: Home,
    scope: "Unlimited rooms",
    turnaround: "7-10 business days",
    popular: false,
    ctaLabel: "Get Home Plan",
    ctaVariant: "outline" as const,
    features: [
      "Everything in Detailed Analysis, plus:",
      "Comprehensive whole-home color strategy",
      "Room-by-room color specifications",
      "Coordinated trim & ceiling plan",
      "Exterior color coordination (if applicable)",
      "Budget-conscious alternatives",
      "Shopping list with product codes",
      "60-minute video consultation",
    ],
  },
];

export function PackageCards() {
  return (
    <section id="packages" className="scroll-mt-20 bg-white py-16 md:py-24">
      <div className="container mx-auto max-w-7xl px-6">
        {/* Heading */}
        <div className="mb-12 text-center md:mb-16">
          <h2 className="mb-4 font-heading text-3xl font-bold text-foreground md:text-4xl lg:text-5xl">
            Consultation Packages
          </h2>
          <p className="mx-auto max-w-2xl text-lg text-muted-foreground">
            Choose the level of guidance that fits your project
          </p>
        </div>

        {/* Package Cards */}
        <div className="grid gap-8 lg:grid-cols-3">
          {packages.map((pkg, index) => {
            const Icon = pkg.icon;
            const isPopular = pkg.popular;

            return (
              <Card
                key={pkg.id}
                className={cn(
                  "relative flex flex-col transition-all hover:shadow-lg",
                  isPopular
                    ? "border-primary/40 shadow-md"
                    : "border-border/60"
                )}
              >
                {/* Popular Badge */}
                {isPopular && (
                  <div className="absolute -top-3 left-1/2 z-10 -translate-x-1/2">
                    <Badge className="bg-accent px-4 py-1 text-sm font-semibold text-accent-foreground">
                      Most Popular
                    </Badge>
                  </div>
                )}

                <CardHeader className="border-b pb-6">
                  {/* Icon */}
                  <div className="mb-4 flex size-14 items-center justify-center rounded-lg bg-primary/10">
                    <Icon className="size-7 text-primary" strokeWidth={1.5} />
                  </div>

                  <CardTitle className="mb-2 font-heading text-2xl">
                    {pkg.name}
                  </CardTitle>
                  <CardDescription className="text-base">
                    {pkg.scope}
                  </CardDescription>

                  {/* Price */}
                  <div className="mt-4 flex items-baseline gap-1">
                    <span className="font-heading text-4xl font-bold text-foreground">
                      ${pkg.price}
                    </span>
                    <span className="text-muted-foreground">/ project</span>
                  </div>
                </CardHeader>

                <CardContent className="flex flex-1 flex-col gap-6">
                  {/* Features List */}
                  <ul className="flex-1 space-y-3">
                    {pkg.features.map((feature, i) => (
                      <li key={i} className="flex items-start gap-3">
                        <Check
                          className="mt-0.5 size-5 shrink-0 text-primary"
                          strokeWidth={2}
                        />
                        <span className="text-sm leading-relaxed text-foreground">
                          {feature}
                        </span>
                      </li>
                    ))}
                  </ul>

                  {/* Turnaround Time */}
                  <div className="border-t pt-4">
                    <p className="text-sm text-muted-foreground">
                      Turnaround: <span className="font-medium text-foreground">{pkg.turnaround}</span>
                    </p>
                  </div>

                  {/* CTA Button */}
                  <Button
                    asChild
                    variant={pkg.ctaVariant}
                    size="lg"
                    className={cn(
                      "h-12 w-full text-base font-semibold",
                      isPopular && "shadow-md"
                    )}
                  >
                    <Link href={`/consultation?package=${pkg.id}`}>
                      {pkg.ctaLabel}
                    </Link>
                  </Button>
                </CardContent>
              </Card>
            );
          })}
        </div>
      </div>
    </section>
  );
}
