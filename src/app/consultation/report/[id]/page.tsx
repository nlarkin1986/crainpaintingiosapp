import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { ReportHeader } from "@/components/report/report-header";
import { ColorRecommendation } from "@/components/report/color-recommendation";
import { SunTimeline } from "@/components/report/sun-timeline";
import { ApplicationTips } from "@/components/report/application-tips";
import { ReportFooter } from "@/components/report/report-footer";
import type {
  ConsultationReport,
  ConsultationOrder,
} from "@/types/consultation";
import { Sun } from "lucide-react";

// ---------------------------------------------------------------------------
// Types for Next.js 16 async params / searchParams
// ---------------------------------------------------------------------------

interface PageProps {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ token?: string }>;
}

// ---------------------------------------------------------------------------
// Data fetching helper
// ---------------------------------------------------------------------------

async function getReportData(
  id: string,
  token: string
): Promise<{ report: ConsultationReport; order: ConsultationOrder } | null> {
  const supabase = await createClient();

  const { data: report, error: reportError } = await supabase
    .from("consultation_reports")
    .select("*")
    .eq("id", id)
    .eq("access_token", token)
    .single();

  if (reportError || !report) return null;

  const { data: order, error: orderError } = await supabase
    .from("consultation_orders")
    .select("*")
    .eq("id", report.orderId)
    .single();

  if (orderError || !order) return null;

  return {
    report: report as ConsultationReport,
    order: order as ConsultationOrder,
  };
}

// ---------------------------------------------------------------------------
// Metadata
// ---------------------------------------------------------------------------

export async function generateMetadata({
  params,
  searchParams,
}: PageProps): Promise<Metadata> {
  const { id } = await params;
  const { token } = await searchParams;

  if (!token) {
    return { title: "Report Not Found | Crain Painting" };
  }

  const data = await getReportData(id, token);

  if (!data) {
    return { title: "Report Not Found | Crain Painting" };
  }

  const roomType = data.order.quizResponses?.roomType ?? "Room";

  return {
    title: `${roomType} Color Report | Crain Painting`,
    description: data.report.executiveSummary.slice(0, 160),
    robots: { index: false, follow: false },
  };
}

// ---------------------------------------------------------------------------
// Page component
// ---------------------------------------------------------------------------

export default async function ReportPage({ params, searchParams }: PageProps) {
  const { id } = await params;
  const { token } = await searchParams;

  if (!token) {
    return <ReportNotFound />;
  }

  const data = await getReportData(id, token);

  if (!data) {
    return <ReportNotFound />;
  }

  const { report, order } = data;

  return (
    <main className="min-h-screen py-8 px-4 sm:px-6">
      <div className="mx-auto max-w-3xl space-y-8">
        {/* Header */}
        <ReportHeader report={report} order={order} />

        {/* Executive summary */}
        <section className="rounded-xl border border-border bg-card px-6 py-6 sm:px-8">
          <h2 className="font-heading text-lg font-bold text-foreground mb-3">
            Executive Summary
          </h2>
          <p className="text-sm text-foreground/85 leading-relaxed whitespace-pre-line">
            {report.executiveSummary}
          </p>
        </section>

        {/* Color recommendations */}
        <section className="space-y-6">
          <h2 className="font-heading text-lg font-bold text-foreground px-1">
            Color Recommendations
          </h2>
          {report.recommendations.map((rec, i) => (
            <ColorRecommendation
              key={rec.colorNumber}
              recommendation={rec}
              index={i}
            />
          ))}
        </section>

        {/* Lighting analysis */}
        <section className="rounded-xl border border-border bg-card px-6 py-6 sm:px-8 space-y-5">
          <h2 className="font-heading text-lg font-bold text-foreground flex items-center gap-2">
            <Sun className="size-5 text-amber-500" />
            Lighting Analysis
          </h2>
          <SunTimeline sunData={report.sunData} />
          <p className="text-sm text-foreground/85 leading-relaxed whitespace-pre-line">
            {report.sunData.lightingAnalysis}
          </p>
        </section>

        {/* Application tips + surface prep */}
        {(report.applicationTips.length > 0 ||
          report.surfacePrep.length > 0) && (
          <section className="space-y-4">
            <h2 className="font-heading text-lg font-bold text-foreground px-1">
              Preparation &amp; Application
            </h2>
            <ApplicationTips
              tips={report.applicationTips}
              surfacePrep={report.surfacePrep}
            />
          </section>
        )}

        {/* Footer */}
        <ReportFooter
          pdfUrl={report.pdfUrl}
          reportId={report.id}
          accessToken={report.accessToken}
        />
      </div>
    </main>
  );
}

// ---------------------------------------------------------------------------
// Not-found fallback
// ---------------------------------------------------------------------------

function ReportNotFound() {
  return (
    <main className="min-h-screen flex items-center justify-center px-4">
      <div className="max-w-md w-full text-center space-y-4">
        <div className="mx-auto flex items-center justify-center size-16 rounded-full bg-muted">
          <Sun className="size-7 text-muted-foreground" />
        </div>
        <h1 className="font-heading text-2xl font-bold text-foreground">
          Report Not Found
        </h1>
        <p className="text-sm text-muted-foreground">
          This report link is invalid or has expired. Please check your email
          for the correct link, or contact Crain Painting for assistance.
        </p>
      </div>
    </main>
  );
}
