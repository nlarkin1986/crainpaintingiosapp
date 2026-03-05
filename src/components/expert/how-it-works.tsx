import { Palette, Camera, Package, FileText } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";

const steps = [
  {
    number: 1,
    icon: Palette,
    title: "Discover",
    description: "Take our color quiz to find your perfect palette",
  },
  {
    number: 2,
    icon: Camera,
    title: "Upload",
    description: "Share photos of your room and lighting",
  },
  {
    number: 3,
    icon: Package,
    title: "Choose",
    description: "Select the level of detail you need for your project",
  },
  {
    number: 4,
    icon: FileText,
    title: "Receive",
    description: "Get your professional color report",
  },
];

export function HowItWorksSection() {
  return (
    <section className="bg-[#F7F7F7] py-16 md:py-24">
      <div className="container mx-auto max-w-7xl px-6">
        {/* Heading */}
        <div className="mb-12 text-center md:mb-16">
          <h2 className="mb-4 font-heading text-3xl font-bold text-foreground md:text-4xl lg:text-5xl">
            How It Works
          </h2>
          <p className="mx-auto max-w-2xl text-lg text-muted-foreground">
            Get expert color guidance in four simple steps
          </p>
        </div>

        {/* Steps Flow */}
        <div className="relative mx-auto max-w-6xl">
          {/* Connection Line - Hidden on mobile, shown on md+ */}
          <div className="absolute left-0 right-0 top-16 hidden h-px bg-border md:block" />

          <div className="grid gap-8 md:grid-cols-4 md:gap-6">
            {steps.map((step, index) => {
              const Icon = step.icon;
              return (
                <div key={index} className="relative flex flex-col items-center text-center">
                  {/* Number Badge */}
                  <Badge
                    className="absolute -top-3 left-1/2 z-10 size-8 -translate-x-1/2 items-center justify-center rounded-full bg-foreground p-0 text-sm font-bold text-white md:top-12"
                  >
                    {step.number}
                  </Badge>

                  {/* Icon Circle */}
                  <div className="relative z-20 mb-6 flex size-32 items-center justify-center rounded-full border-4 border-white bg-card shadow-md transition-all hover:scale-105 hover:shadow-lg">
                    <Icon className="size-12 text-primary" strokeWidth={1.5} />
                  </div>

                  {/* Content */}
                  <h3 className="mb-2 font-heading text-xl font-semibold text-foreground md:text-2xl">
                    {step.title}
                  </h3>
                  <p className="max-w-xs text-base leading-relaxed text-muted-foreground">
                    {step.description}
                  </p>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </section>
  );
}
