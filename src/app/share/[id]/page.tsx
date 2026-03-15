import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { ShareComparison } from "@/components/share/share-comparison";
import { SharePageActions } from "@/components/share/share-page-actions";
import { getBrandLabel } from "@/lib/brands";
import {
  getSharePaths,
  getShareSurfaceLabel,
  getShareUrls,
  getShareVisualizationData,
} from "@/lib/share";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ id: string }>;
}): Promise<Metadata> {
  const { id } = await params;
  const data = await getShareVisualizationData(id);

  if (!data) {
    return {
      title: "Visualization Not Found - Crain Painting",
      description: "This visualization may have expired or been removed.",
    };
  }

  const brandLabel = getBrandLabel(data.brand);

  return {
    title: `${data.colorName} Visualization - Crain Painting`,
    description: `See this room painted in ${brandLabel} ${data.colorName} (${data.colorNumber}). Visualize your own space with Crain Painting.`,
    openGraph: {
      title: `${data.colorName} - Crain Painting Color Visualizer`,
      description: `Room visualized in ${brandLabel} ${data.colorName} (${data.colorNumber})`,
      images: [{ url: getShareUrls(id).cardUrl, width: 1600, height: 2000 }],
      type: "website",
    },
    twitter: {
      card: "summary_large_image",
      title: `${data.colorName} - Crain Painting Color Visualizer`,
      description: `Room visualized in ${brandLabel} ${data.colorName}`,
      images: [getShareUrls(id).cardUrl],
    },
  };
}

export default async function SharePage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const data = await getShareVisualizationData(id);

  if (!data) {
    return (
      <main className="min-h-dvh bg-background">
        <div className="mx-auto flex max-w-2xl flex-col items-center px-4 py-16 text-center">
          <Card className="w-full max-w-md p-8">
            <div className="flex flex-col items-center gap-4">
              <h1 className="font-heading text-2xl font-bold text-foreground">
                Visualization Not Found
              </h1>
              <p className="text-base text-muted-foreground">
                This visualization may have expired or been removed. Visualizations are
                available for a limited time.
              </p>
              <Link href="/visualize" className="w-full pt-2">
                <Button size="lg" className="h-12 w-full text-lg">
                  Try It Yourself
                </Button>
              </Link>
            </div>
          </Card>
        </div>
      </main>
    );
  }

  const brandLabel = getBrandLabel(data.brand);
  const { cardPath } = getSharePaths(id);
  const surfaceLabel = getShareSurfaceLabel(data.surface);

  return (
    <main className="min-h-dvh bg-background">
      <div className="mx-auto max-w-4xl px-4 py-6 sm:py-8">
        {/* Header */}
        <div className="mb-6 text-center sm:mb-8">
          <h1 className="font-heading text-3xl font-bold text-foreground">
            Crain Painting
          </h1>
          <p className="mt-1 text-sm text-muted-foreground">
            Color Visualizer
          </p>
        </div>

        <Card className="overflow-hidden p-0">
          <div className="border-b border-border px-5 py-5 sm:px-6">
            <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
              <div>
                <p className="text-sm font-medium uppercase tracking-[0.18em] text-primary">
                  Shareable Review
                </p>
                <h2 className="mt-2 font-heading text-2xl font-bold text-foreground sm:text-3xl">
                  {data.colorName}
                </h2>
                <p className="mt-2 text-sm text-muted-foreground sm:text-base">
                  {brandLabel} {data.colorNumber} on {surfaceLabel}
                </p>
              </div>

              <SharePageActions
                shareId={id}
                colorName={data.colorName}
                colorNumber={data.colorNumber}
                brand={data.brand}
                surface={data.surface}
                rawImageUrl={data.resultUrl}
              />
            </div>
          </div>

          <div className="p-4 sm:p-6">
            <div className="overflow-hidden rounded-2xl border border-border bg-muted/20 shadow-sm">
              <div className="relative aspect-[4/5] w-full">
                <Image
                  src={cardPath}
                  alt={`${data.colorName} design card`}
                  fill
                  className="object-cover"
                  sizes="(min-width: 1024px) 896px, 100vw"
                />
              </div>
            </div>
          </div>
        </Card>

        <div className="mt-8">
          <div className="mb-4">
            <h3 className="font-heading text-xl font-bold text-foreground">
              Live Before / After Comparison
            </h3>
            <p className="mt-1 text-sm text-muted-foreground">
              Use the interactive slider for a closer look, then send the design card or review PDF.
            </p>
          </div>

          <ShareComparison
            originalUrl={data.originalUrl}
            resultUrl={data.resultUrl}
            colorName={data.colorName}
          />
        </div>

        {/* CTA */}
        <div className="mt-6">
          <Link href="/visualize">
            <Button size="lg" className="h-14 w-full text-lg font-semibold">
              Try It Yourself
            </Button>
          </Link>
        </div>

        {/* Footer */}
        <footer className="mt-12 border-t border-border pt-6 text-center">
          <p className="text-base text-muted-foreground">
            Powered by{" "}
            <span className="font-semibold text-foreground">
              Crain Painting
            </span>
          </p>
          <p className="mt-1 text-sm text-muted-foreground">
            {brandLabel} Color Visualizer
          </p>
        </footer>
      </div>
    </main>
  );
}
