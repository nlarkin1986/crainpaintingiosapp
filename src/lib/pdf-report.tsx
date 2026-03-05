import React from "react";
import {
  Document,
  Page,
  Text,
  View,
  StyleSheet,
  renderToBuffer,
} from "@react-pdf/renderer";
import type {
  ConsultationReport,
  ConsultationOrder,
  ColorRecommendation,
} from "@/types/consultation";
import { CONSULTATION_PACKAGES } from "@/types/consultation";

// ---------------------------------------------------------------------------
// Styles
// ---------------------------------------------------------------------------

const teal = "#27CCC0";
const orange = "#F6653C";
const dark = "#0f172a";
const muted = "#64748b";
const border = "#E2E8F0";
const bg = "#FAFAFA";

const s = StyleSheet.create({
  page: {
    paddingTop: 40,
    paddingBottom: 50,
    paddingHorizontal: 40,
    fontFamily: "Helvetica",
    fontSize: 10,
    color: dark,
    backgroundColor: "#ffffff",
  },

  /* Header */
  header: {
    marginBottom: 24,
    borderBottomWidth: 2,
    borderBottomColor: teal,
    paddingBottom: 16,
  },
  brand: {
    fontSize: 22,
    fontFamily: "Helvetica-Bold",
    color: dark,
    marginBottom: 2,
  },
  subtitle: {
    fontSize: 10,
    color: muted,
    letterSpacing: 1.2,
    textTransform: "uppercase",
    marginBottom: 10,
  },
  metaRow: {
    flexDirection: "row",
    gap: 16,
    fontSize: 9,
    color: muted,
  },
  badge: {
    backgroundColor: teal,
    color: "#ffffff",
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 10,
    fontSize: 8,
    fontFamily: "Helvetica-Bold",
  },

  /* Sections */
  section: {
    marginBottom: 18,
  },
  sectionTitle: {
    fontSize: 14,
    fontFamily: "Helvetica-Bold",
    color: dark,
    marginBottom: 8,
    borderBottomWidth: 1,
    borderBottomColor: border,
    paddingBottom: 4,
  },
  bodyText: {
    fontSize: 10,
    lineHeight: 1.6,
    color: "#334155",
  },

  /* Color recommendation card */
  colorCard: {
    marginBottom: 14,
    borderWidth: 1,
    borderColor: border,
    borderRadius: 6,
    padding: 12,
    backgroundColor: bg,
  },
  colorCardHeader: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    marginBottom: 8,
  },
  swatch: {
    width: 44,
    height: 44,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: border,
  },
  colorName: {
    fontSize: 13,
    fontFamily: "Helvetica-Bold",
    color: dark,
  },
  colorNumber: {
    fontSize: 10,
    color: teal,
    fontFamily: "Helvetica-Bold",
  },
  finishRow: {
    flexDirection: "row",
    gap: 4,
    fontSize: 9,
    color: muted,
    marginTop: 4,
  },

  /* Time-of-day strip */
  todRow: {
    flexDirection: "row",
    gap: 8,
    marginTop: 8,
  },
  todItem: {
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
  },
  todSwatch: {
    width: 16,
    height: 16,
    borderRadius: 3,
    borderWidth: 1,
    borderColor: border,
  },
  todLabel: {
    fontSize: 8,
    color: muted,
  },

  /* Tips */
  tipRow: {
    flexDirection: "row",
    gap: 6,
    marginBottom: 4,
  },
  tipNumber: {
    width: 16,
    height: 16,
    borderRadius: 8,
    backgroundColor: teal,
    color: "#ffffff",
    fontSize: 8,
    textAlign: "center",
    lineHeight: 1,
    paddingTop: 4,
    fontFamily: "Helvetica-Bold",
  },
  checkBox: {
    width: 10,
    height: 10,
    borderWidth: 1.5,
    borderColor: teal,
    borderRadius: 2,
    marginTop: 2,
  },

  /* Footer */
  footer: {
    position: "absolute",
    bottom: 20,
    left: 40,
    right: 40,
    borderTopWidth: 1,
    borderTopColor: border,
    paddingTop: 8,
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
  footerBrand: {
    fontSize: 9,
    fontFamily: "Helvetica-Bold",
    color: dark,
  },
  footerDisclaimer: {
    fontSize: 7,
    color: muted,
    maxWidth: "60%",
    textAlign: "right",
  },
});

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}

function formatTime(iso: string): string {
  try {
    return new Date(iso).toLocaleTimeString("en-US", {
      hour: "numeric",
      minute: "2-digit",
    });
  } catch {
    return iso;
  }
}

// ---------------------------------------------------------------------------
// Color recommendation block
// ---------------------------------------------------------------------------

function ColorBlock({ rec, index }: { rec: ColorRecommendation; index: number }) {
  return (
    <View style={s.colorCard} wrap={false}>
      <View style={s.colorCardHeader}>
        <View style={[s.swatch, { backgroundColor: rec.hex }]} />
        <View>
          <Text style={s.colorName}>{rec.colorName}</Text>
          <Text style={s.colorNumber}>{rec.colorNumber}</Text>
        </View>
      </View>

      <Text style={s.bodyText}>{rec.rationale}</Text>

      <View style={s.finishRow}>
        <Text style={{ fontFamily: "Helvetica-Bold", color: dark, fontSize: 9 }}>
          Finish:
        </Text>
        <Text>{rec.finishSheen}</Text>
      </View>

      {/* Time-of-day strip */}
      <View style={s.todRow}>
        <View style={s.todItem}>
          <View style={[s.todSwatch, { backgroundColor: rec.morningHex }]} />
          <Text style={s.todLabel}>Morning</Text>
        </View>
        <View style={s.todItem}>
          <View style={[s.todSwatch, { backgroundColor: rec.afternoonHex }]} />
          <Text style={s.todLabel}>Afternoon</Text>
        </View>
        <View style={s.todItem}>
          <View style={[s.todSwatch, { backgroundColor: rec.eveningHex }]} />
          <Text style={s.todLabel}>Evening</Text>
        </View>
      </View>
    </View>
  );
}

// ---------------------------------------------------------------------------
// Document
// ---------------------------------------------------------------------------

interface ReportDocProps {
  report: ConsultationReport;
  order: ConsultationOrder;
}

function ReportDocument({ report, order }: ReportDocProps) {
  const packageName =
    CONSULTATION_PACKAGES[order.packageType]?.name ?? order.packageType;
  const roomType = order.quizResponses?.roomType ?? "";

  return (
    <Document
      title={`Color Report - ${roomType}`}
      author="Crain Painting"
      subject="Color Consultation Report"
    >
      <Page size="LETTER" style={s.page}>
        {/* Header */}
        <View style={s.header}>
          <Text style={s.brand}>Crain Painting</Text>
          <Text style={s.subtitle}>Color Consultation Report</Text>
          <View style={s.metaRow}>
            <Text style={s.badge}>{packageName}</Text>
            {roomType ? <Text>{roomType}</Text> : null}
            <Text>{formatDate(report.createdAt)}</Text>
            {order.address ? <Text>{order.address}</Text> : null}
          </View>
        </View>

        {/* Executive summary */}
        <View style={s.section}>
          <Text style={s.sectionTitle}>Executive Summary</Text>
          <Text style={s.bodyText}>{report.executiveSummary}</Text>
        </View>

        {/* Recommendations */}
        <View style={s.section}>
          <Text style={s.sectionTitle}>Color Recommendations</Text>
          {report.recommendations.map((rec, i) => (
            <ColorBlock key={rec.colorNumber} rec={rec} index={i} />
          ))}
        </View>

        {/* Lighting analysis */}
        <View style={s.section}>
          <Text style={s.sectionTitle}>Lighting Analysis</Text>
          <View style={{ flexDirection: "row", gap: 20, marginBottom: 8 }}>
            <Text style={{ fontSize: 9, color: muted }}>
              Sunrise: {formatTime(report.sunData.sunrise)}
            </Text>
            <Text style={{ fontSize: 9, color: muted }}>
              Solar Noon: {formatTime(report.sunData.solarNoon)}
            </Text>
            <Text style={{ fontSize: 9, color: muted }}>
              Sunset: {formatTime(report.sunData.sunset)}
            </Text>
            <Text style={{ fontSize: 9, color: muted }}>
              Day Length: {report.sunData.dayLengthHours.toFixed(1)}h
            </Text>
          </View>
          <Text style={s.bodyText}>{report.sunData.lightingAnalysis}</Text>
        </View>

        {/* Application tips */}
        {report.applicationTips.length > 0 && (
          <View style={s.section}>
            <Text style={s.sectionTitle}>Application Tips</Text>
            {report.applicationTips.map((tip, i) => (
              <View key={i} style={s.tipRow}>
                <Text style={s.tipNumber}>{i + 1}</Text>
                <Text style={[s.bodyText, { flex: 1 }]}>{tip}</Text>
              </View>
            ))}
          </View>
        )}

        {/* Surface prep */}
        {report.surfacePrep.length > 0 && (
          <View style={s.section}>
            <Text style={s.sectionTitle}>Surface Preparation</Text>
            {report.surfacePrep.map((step, i) => (
              <View key={i} style={s.tipRow}>
                <View style={s.checkBox} />
                <Text style={[s.bodyText, { flex: 1 }]}>{step}</Text>
              </View>
            ))}
          </View>
        )}

        {/* Footer */}
        <View style={s.footer} fixed>
          <Text style={s.footerBrand}>Crain Painting</Text>
          <Text style={s.footerDisclaimer}>
            Powered by AI color analysis. Recommendations are advisory; always
            test colors in your space before painting.
          </Text>
        </View>
      </Page>
    </Document>
  );
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

export async function generatePdfBuffer(
  report: ConsultationReport,
  order: ConsultationOrder
): Promise<Buffer> {
  const buffer = await renderToBuffer(
    <ReportDocument report={report} order={order} />
  );
  return Buffer.from(buffer);
}
