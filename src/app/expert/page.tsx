import type { Metadata } from "next";
import { HeroSection } from "@/components/expert/hero-section";
import { AboutSection } from "@/components/expert/about-section";
import { HowItWorksSection } from "@/components/expert/how-it-works";
import { PackageCards } from "@/components/expert/package-cards";
import { TestimonialsSection } from "@/components/expert/testimonials";
import { BottomCTA } from "@/components/expert/bottom-cta";

export const metadata: Metadata = {
  title: "Expert Color Consultant - Curt Crain | Crain Painting",
  description:
    "Get professional color guidance from Curt Crain, a master painter and fine artist with 20+ years of experience. Choose from three consultation packages tailored to your project needs.",
  keywords: [
    "color consultant",
    "professional painter",
    "Benjamin Moore specialist",
    "color consultation",
    "interior painting",
    "color analysis",
  ],
  openGraph: {
    title: "Expert Color Consultant - Curt Crain",
    description:
      "Professional painter, fine artist, and color expert with 20+ years transforming spaces",
    type: "website",
  },
};

export default function ExpertPage() {
  return (
    <main className="min-h-screen">
      <HeroSection />
      <AboutSection />
      <HowItWorksSection />
      <PackageCards />
      <TestimonialsSection />
      <BottomCTA />
    </main>
  );
}
