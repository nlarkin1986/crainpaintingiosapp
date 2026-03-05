import { Star } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { cn } from "@/lib/utils";

const testimonials = [
  {
    name: "Sarah M.",
    project: "Living Room Refresh",
    rating: 5,
    quote:
      "Curt's eye for color is incredible. I was stuck between neutrals and wanted something with personality but not overwhelming. His recommendations were spot-on—the room feels both calming and sophisticated. The video walkthrough helped me understand his thinking, which gave me so much confidence.",
  },
  {
    name: "Mike T.",
    project: "Kitchen Renovation",
    rating: 5,
    quote:
      "The detailed analysis was worth every penny. Curt caught lighting issues I hadn't even considered and steered me away from a color that would have looked terrible with my north-facing windows. His finish recommendations also made a huge difference in durability. Highly recommend!",
  },
  {
    name: "Jennifer & David R.",
    project: "New Construction",
    rating: 5,
    quote:
      "We used the whole-home plan for our new build and it was a game-changer. Curt created a cohesive color flow that feels intentional from room to room, while still giving each space its own character. The shopping list with product codes saved us so much time at the paint store.",
  },
];

export function TestimonialsSection() {
  return (
    <section className="bg-[#F7F7F7] py-16 md:py-24">
      <div className="container mx-auto max-w-7xl px-6">
        {/* Heading */}
        <div className="mb-12 text-center md:mb-16">
          <h2 className="mb-4 font-heading text-3xl font-bold text-foreground md:text-4xl lg:text-5xl">
            What Clients Say
          </h2>
          <p className="mx-auto max-w-2xl text-lg text-muted-foreground">
            Real results from real projects
          </p>
        </div>

        {/* Testimonial Cards */}
        <div className="grid gap-8 md:grid-cols-2 lg:grid-cols-3">
          {testimonials.map((testimonial, index) => (
            <Card
              key={index}
              className="border-border/60 transition-all hover:border-primary/40 hover:shadow-md"
            >
              <CardContent className="flex flex-col gap-4 p-6">
                {/* Decorative quotation mark */}
                <span className="text-6xl font-serif leading-none text-primary/10" aria-hidden="true">
                  &ldquo;
                </span>

                {/* Star Rating */}
                <div className="-mt-6 flex gap-1">
                  {Array.from({ length: testimonial.rating }).map((_, i) => (
                    <Star
                      key={i}
                      className="size-5 fill-yellow-400 text-yellow-400"
                      strokeWidth={1.5}
                    />
                  ))}
                </div>

                {/* Quote */}
                <blockquote className="flex-1 text-base leading-relaxed text-foreground">
                  &ldquo;{testimonial.quote}&rdquo;
                </blockquote>

                {/* Attribution */}
                <div className="border-t pt-4">
                  <p className="font-semibold text-foreground">
                    {testimonial.name}
                  </p>
                  <p className="text-sm text-muted-foreground">
                    {testimonial.project}
                  </p>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    </section>
  );
}
