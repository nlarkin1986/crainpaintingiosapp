export const BRAND_LABEL: Record<string, string> = {
  benjamin_moore: "Benjamin Moore",
  sherwin_williams: "Sherwin-Williams",
};

export function getBrandLabel(brand?: string): string {
  if (!brand) return BRAND_LABEL.benjamin_moore;
  return BRAND_LABEL[brand] ?? BRAND_LABEL.benjamin_moore;
}
