import type { Metadata } from "next";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { ShareComparison } from "@/components/share/share-comparison";
import { getBrandLabel } from "@/lib/brands";

interface ShareData {
  originalUrl: string;
  resultUrl: string;
  colorName: string;
  colorNumber: string;
  colorHex: string;
  brand?: string;
  surface: string;
  createdAt: string;
}

async function getShareData(id: string): Promise<ShareData | null> {
  try {
    // Fetch the share JSON from Vercel Blob using the public URL pattern
    // Vercel Blob stores public files at the blob store URL
    const baseUrl = process.env.BLOB_STORE_URL;
    if (!baseUrl) {
      console.error("BLOB_STORE_URL not configured");
      return null;
    }

    const res = await fetch(`${baseUrl}/shares/${id}.json`, {
      next: { revalidate: 0 },
    });

    if (!res.ok) return null;

    const data: ShareData = await res.json();
    return data;
  } catch (err) {
    console.error("Failed to fetch share data:", err);
    return null;
  }
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ id: string }>;
}): Promise<Metadata> {
  const { id } = await params;
  const data = await getShareData(id);

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
      images: [{ url: data.resultUrl, width: 1200, height: 630 }],
      type: "website",
    },
    twitter: {
      card: "summary_large_image",
      title: `${data.colorName} - Crain Painting Color Visualizer`,
      description: `Room visualized in ${brandLabel} ${data.colorName}`,
      images: [data.resultUrl],
    },
  };
}

export default async function SharePage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const data = await getShareData(id);

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

  return (
    <main className="min-h-dvh bg-background">
      <div className="mx-auto max-w-2xl px-4 py-6">
        {/* Header */}
        <div className="mb-6 text-center">
          <h1 className="font-heading text-2xl font-bold text-foreground">
            Crain Painting
          </h1>
          <p className="mt-1 text-sm text-muted-foreground">
            Color Visualizer
          </p>
        </div>

        {/* Before / After Comparison */}
        <ShareComparison
          originalUrl={data.originalUrl}
          resultUrl={data.resultUrl}
          colorName={data.colorName}
        />

        {/* Color Info */}
        <Card className="mt-6 p-4">
          <div className="flex items-center gap-3">
            <div
              className="h-14 w-14 shrink-0 rounded-lg border border-border shadow-sm"
              style={{ backgroundColor: `#${data.colorHex}` }}
              aria-hidden="true"
            />
            <div className="flex flex-col">
              <span className="text-lg font-semibold text-foreground">
                {data.colorName}
              </span>
              <span className="text-sm text-muted-foreground">
                {brandLabel} {data.colorNumber}
              </span>
            </div>
          </div>
        </Card>

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
