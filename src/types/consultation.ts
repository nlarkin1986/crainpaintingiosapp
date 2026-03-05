import type { BMColor } from '@/types/colors';

// ---------------------------------------------------------------------------
// Package types
// ---------------------------------------------------------------------------

export type PackageType = 'quick_review' | 'video_consultation' | 'whole_home';

export interface ConsultationPackage {
  key: PackageType;
  name: string;
  description: string;
  priceCents: number;
  priceDisplay: string;
  turnaround: string;
  roomCount: string;
  features: string[];
  popular?: boolean;
}

// ---------------------------------------------------------------------------
// Package definitions
// ---------------------------------------------------------------------------

export const CONSULTATION_PACKAGES: Record<PackageType, ConsultationPackage> = {
  quick_review: {
    key: 'quick_review',
    name: 'Quick Color Review',
    description: 'Fast, expert color feedback for a single room.',
    priceCents: 4900,
    priceDisplay: '$49',
    turnaround: '24-48 hours',
    roomCount: '1 room',
    features: [
      '2-3 color recommendations',
      'Basic lighting analysis',
      'Written color rationale',
      'Finish & sheen specs',
      'Delivered via email + web',
    ],
  },
  video_consultation: {
    key: 'video_consultation',
    name: 'Detailed Color Analysis',
    description: 'In-depth analysis with time-of-day lighting insights.',
    priceCents: 14900,
    priceDisplay: '$149',
    turnaround: '2-3 business days',
    roomCount: 'Up to 3 rooms',
    popular: true,
    features: [
      '4-5 color recommendations',
      'Detailed lighting analysis',
      'Time-of-day color shift analysis',
      'Finish & sheen specs',
      'Before/after visualizations',
      'Application tips',
    ],
  },
  whole_home: {
    key: 'whole_home',
    name: 'Whole Home Color Plan',
    description: 'Comprehensive color strategy for your entire home.',
    priceCents: 39900,
    priceDisplay: '$399',
    turnaround: '5-7 business days',
    roomCount: 'Unlimited rooms',
    features: [
      '6-8 color recommendations',
      'Comprehensive lighting analysis',
      'Seasonal light variation notes',
      'Finish & sheen specs per surface',
      'Before/after visualizations',
      'Surface prep & application guide',
      'Downloadable PDF report',
    ],
  },
} as const;

// ---------------------------------------------------------------------------
// Room types
// ---------------------------------------------------------------------------

export const ROOM_TYPES = [
  'Living Room',
  'Kitchen',
  'Bedroom',
  'Bathroom',
  'Dining Room',
  'Home Office',
  'Hallway / Entryway',
  'Exterior',
  'Other',
] as const;

export type RoomType = (typeof ROOM_TYPES)[number];

// ---------------------------------------------------------------------------
// Mood / vibe options
// ---------------------------------------------------------------------------

export const MOOD_OPTIONS = [
  { key: 'warm_cozy', label: 'Warm & Cozy', description: 'Rich tones, inviting atmosphere', icon: 'Flame' },
  { key: 'clean_modern', label: 'Clean & Modern', description: 'Crisp whites, cool neutrals', icon: 'Sparkles' },
  { key: 'bold_dramatic', label: 'Bold & Dramatic', description: 'Deep colors, high contrast', icon: 'Zap' },
  { key: 'calm_serene', label: 'Calm & Serene', description: 'Soft pastels, natural tones', icon: 'Leaf' },
  { key: 'classic_timeless', label: 'Classic & Timeless', description: 'Traditional palettes, enduring style', icon: 'Crown' },
  { key: 'coastal_airy', label: 'Coastal & Airy', description: 'Ocean blues, sandy neutrals', icon: 'Waves' },
] as const;

export type MoodKey = (typeof MOOD_OPTIONS)[number]['key'];

// ---------------------------------------------------------------------------
// Window directions
// ---------------------------------------------------------------------------

export const WINDOW_DIRECTIONS = [
  { key: 'N', label: 'North', description: 'Cool, consistent indirect light' },
  { key: 'NE', label: 'Northeast', description: 'Morning light, cool afternoon' },
  { key: 'E', label: 'East', description: 'Bright morning sun, cooler afternoon' },
  { key: 'SE', label: 'Southeast', description: 'Morning to midday sun' },
  { key: 'S', label: 'South', description: 'Warm, strong light most of the day' },
  { key: 'SW', label: 'Southwest', description: 'Afternoon to evening sun' },
  { key: 'W', label: 'West', description: 'Intense afternoon and evening light' },
  { key: 'NW', label: 'Northwest', description: 'Late afternoon light' },
  { key: 'unknown', label: "I don't know", description: "We'll analyze from your photos" },
] as const;

export type WindowDirection = (typeof WINDOW_DIRECTIONS)[number]['key'];

// ---------------------------------------------------------------------------
// Surface types (mirrors the existing surfaces used in the visualizer)
// ---------------------------------------------------------------------------

export const SURFACE_TYPES = [
  'Walls',
  'Cabinets',
  'Front Door',
  'Trim',
  'Ceiling',
  'Shutters',
  'Other',
] as const;

export type SurfaceType = (typeof SURFACE_TYPES)[number];

// ---------------------------------------------------------------------------
// Order & report status enums
// ---------------------------------------------------------------------------

export type PaymentStatus = 'pending' | 'paid' | 'failed' | 'refunded';
export type ReportStatus = 'pending' | 'generating' | 'complete' | 'failed';

// ---------------------------------------------------------------------------
// Quiz response (captured during the style-quiz flow)
// ---------------------------------------------------------------------------

export interface QuizResponse {
  roomType: RoomType;
  mood: MoodKey;
  selectedColorNumbers: string[]; // BM color numbers e.g. ["HC-70", "OC-17"]
  refinementRounds: number;
}

// ---------------------------------------------------------------------------
// Consultation order (persisted row)
// ---------------------------------------------------------------------------

export interface ConsultationOrder {
  id: string; // UUID
  email: string;
  packageType: PackageType;
  priceCents: number;
  stripePaymentIntentId?: string;
  stripeSessionId?: string;
  paymentStatus: PaymentStatus;
  reportStatus: ReportStatus;
  retryCount: number;
  quizResponses: QuizResponse;
  selectedColors: string[]; // BM color numbers confirmed in Phase B
  photoUrls: string[];
  surfaceType: string;
  windowDirection: WindowDirection;
  address: string;
  latitude?: number;
  longitude?: number;
  createdAt: string; // ISO 8601
  updatedAt: string; // ISO 8601
}

// ---------------------------------------------------------------------------
// Color recommendation (single entry in the report)
// ---------------------------------------------------------------------------

export interface ColorRecommendation {
  colorName: string;
  colorNumber: string; // BM color number
  hex: string;
  rationale: string;
  finishSheen: string;
  morningHex: string;   // Time-of-day shift hex
  afternoonHex: string;
  eveningHex: string;
  visualizationUrl?: string; // Before/after image URL
  originalUrl?: string;
}

// ---------------------------------------------------------------------------
// Sun / lighting data
// ---------------------------------------------------------------------------

export interface SunData {
  sunrise: string;    // ISO datetime
  sunset: string;
  solarNoon: string;
  goldenHour: string;
  sunPath: Array<{
    time: string;
    altitude: number;  // degrees above horizon
    azimuth: number;   // degrees from north
    isVisible: boolean;
  }>;
  dayLengthHours: number;
  lightingAnalysis: string; // Written analysis from Claude
}

// ---------------------------------------------------------------------------
// Consultation report (delivered to the customer)
// ---------------------------------------------------------------------------

export interface ConsultationReport {
  id: string; // UUID
  orderId: string;
  accessToken: string;
  executiveSummary: string;
  recommendations: ColorRecommendation[];
  sunData: SunData;
  applicationTips: string[];
  surfacePrep: string[];
  pdfUrl?: string;
  createdAt: string; // ISO 8601
}
