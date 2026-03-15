/* eslint-disable jsx-a11y/alt-text */

import React from "react";
import {
  Document,
  Image,
  Page,
  StyleSheet,
  Text,
  View,
  renderToBuffer,
} from "@react-pdf/renderer";
import { getBrandLabel } from "@/lib/brands";
import {
  formatShareDate,
  getShareHexColor,
  getShareSurfaceLabel,
} from "@/lib/share";
import type { ShareVisualizationData } from "@/types/share";

const colors = {
  teal: "#0A8080",
  orange: "#F6653C",
  dark: "#0f172a",
  muted: "#64748b",
  border: "#DCE6E8",
  panel: "#F8FAFC",
};

const styles = StyleSheet.create({
  page: {
    paddingTop: 36,
    paddingBottom: 34,
    paddingHorizontal: 36,
    backgroundColor: "#FFFFFF",
    color: colors.dark,
    fontFamily: "Helvetica",
    fontSize: 10,
  },
  topRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "flex-start",
    borderBottomWidth: 2,
    borderBottomColor: colors.border,
    paddingBottom: 16,
    marginBottom: 18,
  },
  brandStack: {
    gap: 3,
  },
  eyebrow: {
    fontSize: 9,
    letterSpacing: 1.4,
    textTransform: "uppercase",
    color: colors.teal,
  },
  brand: {
    fontSize: 22,
    fontFamily: "Helvetica-Bold",
  },
  subtitle: {
    fontSize: 11,
    color: colors.muted,
  },
  date: {
    fontSize: 10,
    color: colors.muted,
  },
  heroCard: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 14,
    padding: 16,
    backgroundColor: colors.panel,
    marginBottom: 18,
  },
  colorRow: {
    flexDirection: "row",
    gap: 14,
    alignItems: "center",
    marginBottom: 14,
  },
  swatch: {
    width: 52,
    height: 52,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: colors.border,
  },
  colorName: {
    fontSize: 18,
    fontFamily: "Helvetica-Bold",
  },
  colorMeta: {
    fontSize: 11,
    color: colors.muted,
    marginTop: 2,
  },
  detailRow: {
    flexDirection: "row",
    gap: 12,
  },
  detailBox: {
    flexGrow: 1,
    flexBasis: 0,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 10,
    padding: 10,
    backgroundColor: "#FFFFFF",
  },
  detailLabel: {
    fontSize: 8,
    textTransform: "uppercase",
    letterSpacing: 1.1,
    color: colors.muted,
    marginBottom: 5,
  },
  detailValue: {
    fontSize: 11,
    color: colors.dark,
    lineHeight: 1.35,
  },
  imageRow: {
    flexDirection: "row",
    gap: 12,
    marginBottom: 18,
  },
  imagePanel: {
    flexGrow: 1,
    flexBasis: 0,
  },
  imageLabel: {
    fontSize: 9,
    textTransform: "uppercase",
    letterSpacing: 1.1,
    color: colors.muted,
    marginBottom: 6,
  },
  imageWrap: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 14,
    overflow: "hidden",
    height: 224,
    backgroundColor: "#E2E8F0",
  },
  image: {
    width: "100%",
    height: "100%",
    objectFit: "cover",
  },
  notesCard: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 14,
    padding: 16,
    backgroundColor: "#FFFFFF",
  },
  notesTitle: {
    fontSize: 10,
    textTransform: "uppercase",
    letterSpacing: 1.2,
    color: colors.teal,
    marginBottom: 10,
  },
  noteLine: {
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
    marginBottom: 18,
    height: 18,
  },
  footer: {
    marginTop: 20,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: colors.border,
    flexDirection: "row",
    justifyContent: "space-between",
    gap: 16,
  },
  footerLeft: {
    flexGrow: 1,
    flexBasis: 0,
    gap: 4,
  },
  footerLabel: {
    fontSize: 8,
    textTransform: "uppercase",
    letterSpacing: 1.1,
    color: colors.muted,
  },
  footerLink: {
    fontSize: 9,
    color: colors.dark,
  },
  footerRight: {
    flexGrow: 1,
    flexBasis: 0,
    fontSize: 8,
    color: colors.muted,
    lineHeight: 1.4,
    textAlign: "right",
  },
});

function ShareReviewPdf({
  data,
  shareUrl,
}: {
  data: ShareVisualizationData;
  shareUrl: string;
}) {
  return (
    <Document>
      <Page size="LETTER" style={styles.page}>
        <View style={styles.topRow}>
          <View style={styles.brandStack}>
            <Text style={styles.eyebrow}>Crain Painting Contractors</Text>
            <Text style={styles.brand}>Paint Review Sheet</Text>
            <Text style={styles.subtitle}>
              Clear handoff for homeowner, painter, or designer review
            </Text>
          </View>
          <Text style={styles.date}>Generated {formatShareDate(data.createdAt)}</Text>
        </View>

        <View style={styles.heroCard}>
          <View style={styles.colorRow}>
            <View
              style={[
                styles.swatch,
                { backgroundColor: getShareHexColor(data.colorHex) },
              ]}
            />
            <View>
              <Text style={styles.colorName}>{data.colorName}</Text>
              <Text style={styles.colorMeta}>
                {getBrandLabel(data.brand)} {data.colorNumber}
              </Text>
            </View>
          </View>

          <View style={styles.detailRow}>
            <View style={styles.detailBox}>
              <Text style={styles.detailLabel}>Surface</Text>
              <Text style={styles.detailValue}>
                {getShareSurfaceLabel(data.surface)}
              </Text>
            </View>
            <View style={styles.detailBox}>
              <Text style={styles.detailLabel}>Color Spec</Text>
              <Text style={styles.detailValue}>
                {getBrandLabel(data.brand)} {data.colorNumber}
              </Text>
            </View>
            <View style={styles.detailBox}>
              <Text style={styles.detailLabel}>Use</Text>
              <Text style={styles.detailValue}>
                Review the visualization, confirm the direction, then test on site.
              </Text>
            </View>
          </View>
        </View>

        <View style={styles.imageRow}>
          <View style={styles.imagePanel}>
            <Text style={styles.imageLabel}>Before</Text>
            <View style={styles.imageWrap}>
              <Image src={data.originalUrl} style={styles.image} />
            </View>
          </View>
          <View style={styles.imagePanel}>
            <Text style={styles.imageLabel}>After</Text>
            <View style={styles.imageWrap}>
              <Image src={data.resultUrl} style={styles.image} />
            </View>
          </View>
        </View>

        <View style={styles.notesCard}>
          <Text style={styles.notesTitle}>Approval / Painter Notes</Text>
          <View style={styles.noteLine} />
          <View style={styles.noteLine} />
          <View style={styles.noteLine} />
        </View>

        <View style={styles.footer}>
          <View style={styles.footerLeft}>
            <Text style={styles.footerLabel}>Live Share Link</Text>
            <Text style={styles.footerLink}>{shareUrl}</Text>
          </View>
          <Text style={styles.footerRight}>
            Visualization is directional. Colors, sheen, and lighting can shift
            in the actual space. Always test before painting.
          </Text>
        </View>
      </Page>
    </Document>
  );
}

export function renderShareReviewPdfToBuffer(
  data: ShareVisualizationData,
  shareUrl: string
) {
  return renderToBuffer(<ShareReviewPdf data={data} shareUrl={shareUrl} />);
}
