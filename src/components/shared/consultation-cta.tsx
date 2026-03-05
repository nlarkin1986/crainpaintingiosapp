import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Sparkles, ArrowRight } from "lucide-react";

export function ConsultationCTA() {
  return (
    <section className="border-t bg-gradient-to-b from-white to-gray-50/50 px-4 py-16 md:py-20">
      <div className="mx-auto max-w-2xl text-center">
        <div className="mb-4 inline-flex items-center gap-2 rounded-full border bg-white px-4 py-1.5 text-sm text-muted-foreground">
          <Sparkles className="size-4 text-[#F6653C]" />
          AI-Powered Color Analysis
        </div>

        <h2 className="mb-4 font-heading text-3xl font-bold md:text-4xl">
          Not sure which color is right?
        </h2>

        <p className="mb-8 text-lg leading-relaxed text-muted-foreground">
          Get a professional AI color report with personalized recommendations
          based on your room&apos;s natural lighting, style preferences, and
          expert color science.
        </p>

        <div className="flex flex-col items-center gap-3 sm:flex-row sm:justify-center">
          <Button asChild size="lg" className="gap-2 bg-[#F6653C] text-white hover:bg-[#F6653C]/90">
            <Link href="/expert">
              Get a Professional Color Report
              <ArrowRight className="size-4" />
            </Link>
          </Button>
          <span className="text-sm text-muted-foreground">Starting at $49</span>
        </div>
      </div>
    </section>
  );
}
