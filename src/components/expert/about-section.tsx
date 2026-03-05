import Image from "next/image";
import { Building2, Palette, Paintbrush, Home } from "lucide-react";
import { Card } from "@/components/ui/card";
import { cn } from "@/lib/utils";

const expertiseItems = [
  {
    icon: Building2,
    title: "Commercial & Residential Painting",
    description:
      "20+ years leading projects from single rooms to entire buildings, with meticulous attention to surface preparation and finish quality.",
  },
  {
    icon: Palette,
    title: "Color Theory & Fine Art",
    description:
      "Active fine artist with gallery exhibitions. This dual expertise brings a nuanced understanding of how colors interact and evolve in different lighting.",
  },
  {
    icon: Paintbrush,
    title: "Benjamin Moore Specialist",
    description:
      "Extensive experience with the full Benjamin Moore product line, from premium finishes to specialty coatings for unique surfaces.",
  },
  {
    icon: Home,
    title: "Whole-Home Color Flow",
    description:
      "Expert at creating color plans that flow naturally from room to room while honoring each space's unique character and lighting.",
  },
];

export function AboutSection() {
  return (
    <section className="bg-white py-16 md:py-24">
      <div className="container mx-auto max-w-7xl px-6">
        {/* Heading */}
        <div className="mb-12 text-center md:mb-16">
          <h2 className="mb-4 font-heading text-3xl font-bold text-foreground md:text-4xl lg:text-5xl">
            Meet Your Color Expert
          </h2>
          <p className="mx-auto max-w-2xl text-lg text-muted-foreground">
            A unique blend of technical mastery and artistic vision
          </p>
        </div>

        {/* Two Column Layout */}
        <div className="grid gap-12 lg:grid-cols-2 lg:gap-16">
          {/* Left: Photo + Bio Copy */}
          <div className="space-y-6">
            {/* Profile Photo */}
            <div className="overflow-hidden rounded-xl">
              <Image
                src="/curt-crain-profile.jpg"
                alt="Curt Crain painting at his easel"
                width={600}
                height={400}
                className="h-auto w-full object-cover"
              />
            </div>
            <p className="text-lg leading-relaxed text-foreground">
              Curt Crain isn't just a painter—he's an artist who happens to
              excel at transforming homes and commercial spaces. With over two
              decades of hands-on experience, Curt has developed an eye for
              color that goes beyond paint chips and fan decks.
            </p>
            <p className="text-lg leading-relaxed text-foreground">
              His dual expertise as both a professional painter and exhibiting
              fine artist gives him a unique perspective on color. While most
              painters focus solely on application, Curt understands how colors
              interact, how light transforms throughout the day, and how to
              create harmonious palettes that feel intentional rather than
              accidental.
            </p>
            <p className="text-lg leading-relaxed text-foreground">
              Whether you're refreshing a single room or orchestrating a
              whole-home color transformation, Curt's consultations provide the
              professional guidance that eliminates guesswork and buyer's
              remorse. His recommendations are grounded in real-world experience
              with thousands of projects and refined by an artist's sensitivity
              to nuance.
            </p>
          </div>

          {/* Right: Expertise Cards Grid */}
          <div className="grid gap-6 sm:grid-cols-2">
            {expertiseItems.map((item, index) => {
              const Icon = item.icon;
              return (
                <Card
                  key={index}
                  className="border-border/60 p-6 transition-all hover:border-primary/40 hover:shadow-md"
                >
                  <div className="mb-4 flex size-12 items-center justify-center rounded-lg bg-primary/10">
                    <Icon className="size-6 text-primary" strokeWidth={1.5} />
                  </div>
                  <h3 className="mb-2 font-heading text-base font-semibold leading-snug text-foreground">
                    {item.title}
                  </h3>
                  <p className="text-sm leading-relaxed text-muted-foreground">
                    {item.description}
                  </p>
                </Card>
              );
            })}
          </div>
        </div>
      </div>
    </section>
  );
}
