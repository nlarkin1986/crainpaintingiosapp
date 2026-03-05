export interface BMColor {
  number: string;    // "HC-70"
  name: string;      // "Van Buren Brown"
  family: string;    // "Brown"
  hex: string;       // "5F4F46" (no # prefix)
  brand?: 'benjamin_moore' | 'sherwin_williams';
}

// Discriminated union for multi-color generation results
interface ColorResultBase {
  color: BMColor;
}

interface ColorResultPending extends ColorResultBase {
  status: 'pending';
}

interface ColorResultGenerating extends ColorResultBase {
  status: 'generating';
}

interface ColorResultComplete extends ColorResultBase {
  status: 'complete';
  originalUrl: string;
  resultUrl: string;
  shareId: string;
}

interface ColorResultFailed extends ColorResultBase {
  status: 'failed';
  error: string;
}

export type ColorResult =
  | ColorResultPending
  | ColorResultGenerating
  | ColorResultComplete
  | ColorResultFailed;
