import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import {
  mapConsultationOrder,
  mapConsultationReport,
} from "@/lib/consultation-report";
import { generatePdfBuffer } from "@/lib/pdf-report";

export const maxDuration = 30;

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const token = request.nextUrl.searchParams.get("token");

  if (!id || !token) {
    return NextResponse.json(
      { error: "Missing report id or access token" },
      { status: 400 }
    );
  }

  try {
    const supabase = await createClient();

    // Fetch report
    const { data: report, error: reportError } = await supabase
      .from("reports")
      .select("*")
      .eq("id", id)
      .eq("access_token", token)
      .single();

    if (reportError || !report) {
      return NextResponse.json(
        { error: "Report not found or invalid token" },
        { status: 404 }
      );
    }

    // Fetch order
    const { data: order, error: orderError } = await supabase
      .from("orders")
      .select("*")
      .eq("id", report.order_id)
      .single();

    if (orderError || !order) {
      return NextResponse.json(
        { error: "Associated order not found" },
        { status: 404 }
      );
    }

    const mappedReport = mapConsultationReport(report);
    const mappedOrder = mapConsultationOrder(order);

    // Generate PDF
    const pdfBuffer = await generatePdfBuffer(mappedReport, mappedOrder);

    const roomType = mappedOrder.quizResponses?.roomType ?? "Room";
    const filename = `Crain-Painting-${roomType.replace(/\s+/g, "-")}-Color-Report.pdf`;

    return new NextResponse(new Uint8Array(pdfBuffer), {
      status: 200,
      headers: {
        "Content-Type": "application/pdf",
        "Content-Disposition": `attachment; filename="${filename}"`,
        "Cache-Control": "private, max-age=3600",
      },
    });
  } catch (err) {
    console.error("[PDF Generation Error]", err);
    return NextResponse.json(
      { error: "Failed to generate PDF" },
      { status: 500 }
    );
  }
}
