/* eslint-disable @next/next/no-img-element */

import { getBrandLabel } from "@/lib/brands";
import {
  formatShareDate,
  getShareHexColor,
  getShareSurfaceLabel,
} from "@/lib/share";
import type { ShareVisualizationData } from "@/types/share";

export const DESIGN_CARD_WIDTH = 1600;
export const DESIGN_CARD_HEIGHT = 2000;

const BRAND_DARK = "#0f172a";
const BRAND_TEAL = "#0A8080";
const BRAND_ORANGE = "#F6653C";
const BORDER = "#DCE6E8";
const PAPER = "#FFFFFF";
const BACKGROUND = "#F2F7F7";
const MUTED = "#64748B";

export function renderShareDesignCard(data: ShareVisualizationData) {
  const brandLabel = getBrandLabel(data.brand);
  const createdAt = formatShareDate(data.createdAt);
  const surfaceLabel = getShareSurfaceLabel(data.surface);
  const swatchColor = getShareHexColor(data.colorHex);

  return (
    <div
      style={{
        width: "100%",
        height: "100%",
        display: "flex",
        background: BACKGROUND,
        padding: 48,
        color: BRAND_DARK,
      }}
    >
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          flex: 1,
          background: PAPER,
          border: `1px solid ${BORDER}`,
          borderRadius: 44,
          padding: 56,
          position: "relative",
          overflow: "hidden",
        }}
      >
        <div
          style={{
            display: "flex",
            alignItems: "flex-start",
            justifyContent: "space-between",
            gap: 24,
            marginBottom: 32,
          }}
        >
          <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: 10,
                fontSize: 20,
                letterSpacing: 4,
                textTransform: "uppercase",
                color: BRAND_TEAL,
              }}
            >
              <span>Crain Painting</span>
              <span style={{ color: BORDER }}>•</span>
              <span style={{ color: MUTED }}>Design Card</span>
            </div>
            <div
              style={{
                display: "flex",
                flexDirection: "column",
                gap: 6,
                maxWidth: 860,
              }}
            >
              <span
                style={{
                  fontSize: 76,
                  fontWeight: 700,
                  lineHeight: 1.04,
                }}
              >
                {data.colorName}
              </span>
              <span
                style={{
                  fontSize: 30,
                  color: MUTED,
                }}
              >
                {brandLabel} {data.colorNumber}
              </span>
            </div>
          </div>

          <div
            style={{
              display: "flex",
              flexDirection: "column",
              alignItems: "flex-end",
              gap: 10,
              marginTop: 8,
            }}
          >
            <div
              style={{
                display: "flex",
                alignItems: "center",
                padding: "10px 18px",
                borderRadius: 999,
                background: "#E9F7F7",
                color: BRAND_TEAL,
                fontSize: 24,
                fontWeight: 600,
              }}
            >
              Surface: {surfaceLabel}
            </div>
            <span style={{ fontSize: 24, color: MUTED }}>Generated on {createdAt}</span>
          </div>
        </div>

        <div
          style={{
            display: "flex",
            position: "relative",
            height: 1060,
            borderRadius: 36,
            overflow: "hidden",
            background: "#E2E8F0",
            border: `1px solid ${BORDER}`,
          }}
        >
          <img
            src={data.resultUrl}
            alt={`Room visualized in ${data.colorName}`}
            style={{
              width: "100%",
              height: "100%",
              objectFit: "cover",
            }}
          />

          <div
            style={{
              position: "absolute",
              top: 28,
              left: 28,
              display: "flex",
              padding: "10px 18px",
              borderRadius: 999,
              background: "rgba(15, 23, 42, 0.72)",
              color: "#FFFFFF",
              fontSize: 24,
              fontWeight: 600,
              textTransform: "uppercase",
              letterSpacing: 1,
            }}
          >
            After
          </div>

          <div
            style={{
              position: "absolute",
              right: 36,
              bottom: 36,
              display: "flex",
              flexDirection: "column",
              width: 390,
              background: PAPER,
              borderRadius: 28,
              overflow: "hidden",
              border: `1px solid ${BORDER}`,
            }}
          >
            <div
              style={{
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                padding: "18px 22px 14px",
                borderBottom: `1px solid ${BORDER}`,
                fontSize: 22,
                fontWeight: 600,
                color: BRAND_DARK,
              }}
            >
              <span>Before</span>
              <span style={{ color: MUTED, fontWeight: 500 }}>Original photo</span>
            </div>
            <img
              src={data.originalUrl}
              alt="Original room photo"
              style={{
                width: "100%",
                height: 280,
                objectFit: "cover",
              }}
            />
          </div>
        </div>

        <div
          style={{
            display: "flex",
            alignItems: "stretch",
            gap: 28,
            marginTop: 32,
          }}
        >
          <div
            style={{
              width: 144,
              height: 144,
              borderRadius: 30,
              border: `1px solid ${BORDER}`,
              background: swatchColor,
            }}
          />

          <div
            style={{
              display: "flex",
              flexDirection: "column",
              flex: 1,
              gap: 12,
              paddingTop: 4,
            }}
          >
            <span
              style={{
                fontSize: 28,
                color: MUTED,
                textTransform: "uppercase",
                letterSpacing: 2,
              }}
            >
              Paint Selection
            </span>
            <span
              style={{
                fontSize: 54,
                fontWeight: 700,
                lineHeight: 1.08,
              }}
            >
              {data.colorName}
            </span>
            <span style={{ fontSize: 30, color: MUTED }}>
              {brandLabel} {data.colorNumber}
            </span>
          </div>

          <div
            style={{
              width: 360,
              display: "flex",
              flexDirection: "column",
              justifyContent: "center",
              gap: 12,
              padding: 28,
              borderRadius: 28,
              background: "#F8FAFC",
              border: `1px solid ${BORDER}`,
            }}
          >
            <span
              style={{
                fontSize: 24,
                color: MUTED,
                textTransform: "uppercase",
                letterSpacing: 1.5,
              }}
            >
              Review Notes
            </span>
            <span style={{ fontSize: 26, lineHeight: 1.35 }}>
              Ready to share with a painter, designer, or anyone reviewing your
              preferred finish.
            </span>
          </div>
        </div>

        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            gap: 24,
            paddingTop: 32,
            marginTop: "auto",
            borderTop: `2px solid ${BORDER}`,
          }}
        >
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 14,
              fontSize: 24,
              color: BRAND_DARK,
            }}
          >
            <div
              style={{
                width: 12,
                height: 12,
                borderRadius: 999,
                background: BRAND_ORANGE,
              }}
            />
            <span style={{ fontWeight: 600 }}>Crain Painting Contractors</span>
          </div>
          <span
            style={{
              maxWidth: 760,
              fontSize: 22,
              lineHeight: 1.4,
              color: MUTED,
              textAlign: "right",
            }}
          >
            Visualization is directional. Always test color in the actual space
            before painting.
          </span>
        </div>
      </div>
    </div>
  );
}
