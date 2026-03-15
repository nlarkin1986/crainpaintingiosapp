import type { PaintBrand } from "@/types/colors";

export interface ShareVisualizationData {
  originalUrl: string;
  resultUrl: string;
  colorName: string;
  colorNumber: string;
  colorHex: string;
  brand?: PaintBrand | string;
  surface: string;
  createdAt: string;
}
