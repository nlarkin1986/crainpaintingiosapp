import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { CONSULTATION_PACKAGES } from "@/types/consultation";
import type { PackageType, ReportStatus } from "@/types/consultation";

type OrderRow = {
  id: string;
  package_type: PackageType;
  report_status: ReportStatus;
  retry_count: number | null;
  quiz_responses: { roomType?: string } | null;
  created_at: string;
  updated_at: string;
};

type ReportRow = {
  id: string;
  order_id: string;
  access_token: string;
  report_data: {
    executiveSummary?: string;
  } | null;
  color_recommendations: Array<{
    colorName: string;
    colorNumber: string;
    hex: string;
    rationale: string;
    originalUrl?: string;
    visualizationUrl?: string;
  }> | null;
  created_at: string;
};

function buildStatusMessage(status: ReportStatus, packageName: string) {
  switch (status) {
    case "pending":
      return `${packageName} is confirmed. We're preparing the report workflow now.`;
    case "generating":
      return `Your ${packageName.toLowerCase()} is in progress. We'll keep this status current.`;
    case "complete":
      return "Your report is ready to review.";
    case "failed":
      return "We hit an issue while generating the report. Please check back shortly.";
  }
}

export async function GET(
  request: NextRequest,
  context: { params: Promise<{ orderId: string }> }
) {
  try {
    const { orderId } = await context.params;
    const supabase = await createClient();

    const { data: order, error: orderError } = await supabase
      .from("orders")
      .select("id, package_type, report_status, retry_count, quiz_responses, created_at, updated_at")
      .eq("id", orderId)
      .single();

    if (orderError || !order) {
      return NextResponse.json(
        { error: "Order not found." },
        { status: 404 }
      );
    }

    const typedOrder = order as OrderRow;
    const packageInfo = CONSULTATION_PACKAGES[typedOrder.package_type];
    const roomType = typedOrder.quiz_responses?.roomType ?? "Your Room";
    const title = `${roomType} Color Report`;
    const subtitle = packageInfo?.name ?? "Color Consultation";

    let reportPayload: Record<string, unknown> | null = null;

    if (typedOrder.report_status === "complete") {
      const { data: report } = await supabase
        .from("reports")
        .select("id, order_id, access_token, report_data, color_recommendations, created_at")
        .eq("order_id", orderId)
        .single();

      if (report) {
        const typedReport = report as ReportRow;
        const reportUrl = `${request.nextUrl.origin}/consultation/report/${typedReport.id}?token=${typedReport.access_token}`;
        const pdfUrl = `${request.nextUrl.origin}/api/consultation/report/${typedReport.id}/pdf?token=${typedReport.access_token}`;
        reportPayload = {
          report_id: typedReport.id,
          access_token: typedReport.access_token,
          title,
          subtitle,
          video_title: "Curt's Video Walkthrough",
          video_duration: 760,
          created_at: typedReport.created_at,
          report_url: reportUrl,
          pdf_url: pdfUrl,
          recommendations: (typedReport.color_recommendations ?? []).map((recommendation) => ({
            room_name: roomType,
            ...recommendation,
          })),
          executive_summary: typedReport.report_data?.executiveSummary ?? "",
        };
      }
    }

    return NextResponse.json({
      order_id: typedOrder.id,
      package_type: typedOrder.package_type,
      status: typedOrder.report_status === "complete" ? "ready" : typedOrder.report_status,
      title,
      subtitle,
      message: buildStatusMessage(typedOrder.report_status, subtitle),
      created_at: typedOrder.created_at,
      updated_at: typedOrder.updated_at,
      retry_after_seconds: typedOrder.report_status === "failed" ? 300 : null,
      report: reportPayload,
    });
  } catch (error) {
    console.error("Consultation order status error:", error);
    return NextResponse.json(
      { error: "Unable to load report status right now." },
      { status: 500 }
    );
  }
}
