import { Card } from "@/components/ui/card";

export function EstimateCTA() {
  return (
    <Card className="border border-border/50 bg-gradient-to-br from-primary/5 to-transparent p-5">
      <div className="flex items-center gap-4">
        <div className="flex-1">
          <p className="text-sm font-semibold text-foreground">
            Love the look?
          </p>
          <p className="mt-0.5 text-sm text-muted-foreground">
            Get a free estimate — no obligation.
          </p>
        </div>
        <a
          href="https://crainpaintingcontractors.com/contact-us"
          target="_blank"
          rel="noopener noreferrer"
          className="shrink-0 rounded-lg bg-primary/10 px-4 py-2 text-sm font-semibold text-primary transition-colors hover:bg-primary/20"
        >
          Contact Us
        </a>
      </div>
    </Card>
  );
}
