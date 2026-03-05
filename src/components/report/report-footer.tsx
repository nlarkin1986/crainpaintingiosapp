"use client";

import Link from "next/link";
import { Download, MessageCircle, Paintbrush } from "lucide-react";
import { Button } from "@/components/ui/button";

interface ReportFooterProps {
  pdfUrl?: string;
  reportId: string;
  accessToken: string;
}

export function ReportFooter({
  pdfUrl,
  reportId,
  accessToken,
}: ReportFooterProps) {
  const pdfDownloadUrl =
    pdfUrl ?? `/api/consultation/report/${reportId}/pdf?token=${accessToken}`;

  return (
    <footer className="rounded-xl border border-border bg-card overflow-hidden">
      {/* Actions */}
      <div className="px-6 py-6 sm:px-8 flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
        <Button asChild size="lg" className="flex-1 sm:flex-none">
          <a href={pdfDownloadUrl} download>
            <Download className="size-4" />
            Download PDF Report
          </a>
        </Button>

        <Button asChild variant="cta" size="lg" className="flex-1 sm:flex-none">
          <Link href="/expert">
            <MessageCircle className="size-4" />
            Book a Follow-up
          </Link>
        </Button>
      </div>

      {/* Branding strip */}
      <div className="border-t border-border px-6 py-4 sm:px-8 flex flex-col sm:flex-row items-center justify-between gap-2 bg-muted/40">
        <div className="flex items-center gap-2">
          <Paintbrush className="size-4 text-primary" />
          <span className="text-sm font-medium text-foreground">
            Crain Painting
          </span>
        </div>
        <p className="text-[11px] text-muted-foreground text-center sm:text-right">
          Powered by AI color analysis. Recommendations are advisory;
          always test colors in your space before painting.
        </p>
      </div>
    </footer>
  );
}
