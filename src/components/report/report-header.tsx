"use client";

import { Paintbrush, MapPin } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import type {
  ConsultationReport,
  ConsultationOrder,
  PackageType,
} from "@/types/consultation";
import { CONSULTATION_PACKAGES } from "@/types/consultation";

interface ReportHeaderProps {
  report: ConsultationReport;
  order: ConsultationOrder;
}

const PACKAGE_LABELS: Record<PackageType, string> = {
  quick_review: "Quick Color Review",
  video_consultation: "Detailed Analysis",
  whole_home: "Whole Home Plan",
};

function formatReportDate(iso: string): string {
  return new Date(iso).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}

export function ReportHeader({ report, order }: ReportHeaderProps) {
  const packageLabel =
    PACKAGE_LABELS[order.packageType] ?? order.packageType;
  const roomType = order.quizResponses?.roomType ?? "Room";

  return (
    <header className="relative overflow-hidden rounded-xl border border-border bg-card">
      {/* Decorative top stripe */}
      <div className="h-1.5 w-full bg-gradient-to-r from-primary via-primary/70 to-[#F6653C]" />

      <div className="px-6 py-6 sm:px-8 sm:py-8">
        {/* Brand line */}
        <div className="flex items-center gap-2 mb-4">
          <div className="flex items-center justify-center size-9 rounded-lg bg-primary/10">
            <Paintbrush className="size-5 text-primary" />
          </div>
          <div>
            <h1 className="font-heading text-xl font-bold text-foreground tracking-tight">
              Crain Painting
            </h1>
            <p className="text-xs text-muted-foreground tracking-wide uppercase">
              Color Consultation Report
            </p>
          </div>
        </div>

        {/* Meta row */}
        <div className="flex flex-wrap items-center gap-2 mt-4">
          <Badge variant="default">{packageLabel}</Badge>
          <Badge variant="secondary">{roomType}</Badge>
          <span className="text-sm text-muted-foreground">
            {formatReportDate(report.createdAt)}
          </span>
        </div>

        {/* Address */}
        {order.address && (
          <div className="flex items-center gap-1.5 mt-3 text-sm text-muted-foreground">
            <MapPin className="size-3.5 flex-shrink-0" />
            <span>{order.address}</span>
          </div>
        )}
      </div>
    </header>
  );
}
