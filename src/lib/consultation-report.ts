import type {
  ColorRecommendation,
  ConsultationOrder,
  ConsultationReport,
  MoodKey,
  PackageType,
  PaymentStatus,
  QuizResponse,
  ReportStatus,
  RoomType,
  SunData,
  WindowDirection,
} from "@/types/consultation";

type ReportRow = {
  id: string;
  order_id: string;
  access_token: string;
  report_data?: {
    executiveSummary?: string;
    applicationTips?: string[];
    surfacePrep?: string[];
  } | null;
  color_recommendations?: unknown[] | null;
  sun_data?: Partial<SunData> | null;
  created_at: string;
};

type OrderRow = {
  id: string;
  email: string;
  package_type: PackageType;
  price_cents: number;
  stripe_payment_intent_id?: string | null;
  stripe_session_id?: string | null;
  payment_status: PaymentStatus;
  report_status: ReportStatus;
  retry_count?: number | null;
  quiz_responses?: Partial<QuizResponse> | null;
  selected_colors?: string[] | null;
  photo_urls?: string[] | null;
  surface_type?: string | null;
  window_direction?: WindowDirection | null;
  address?: string | null;
  latitude?: number | null;
  longitude?: number | null;
  created_at: string;
  updated_at: string;
};

export function mapConsultationOrder(row: OrderRow): ConsultationOrder {
  const quizResponses = row.quiz_responses ?? {};

  return {
    id: row.id,
    email: row.email,
    packageType: row.package_type,
    priceCents: row.price_cents,
    stripePaymentIntentId: row.stripe_payment_intent_id ?? undefined,
    stripeSessionId: row.stripe_session_id ?? undefined,
    paymentStatus: row.payment_status,
    reportStatus: row.report_status,
    retryCount: row.retry_count ?? 0,
    quizResponses: {
      roomType: (quizResponses.roomType ?? "Living Room") as RoomType,
      mood: (quizResponses.mood ?? "clean_modern") as MoodKey,
      selectedColorNumbers: quizResponses.selectedColorNumbers ?? [],
      refinementRounds: quizResponses.refinementRounds ?? 0,
    },
    selectedColors: row.selected_colors ?? [],
    photoUrls: row.photo_urls ?? [],
    surfaceType: row.surface_type ?? "Walls",
    windowDirection: row.window_direction ?? "unknown",
    address: row.address ?? "",
    latitude: row.latitude ?? undefined,
    longitude: row.longitude ?? undefined,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export function mapConsultationReport(row: ReportRow): ConsultationReport {
  const reportData = row.report_data ?? {};

  return {
    id: row.id,
    orderId: row.order_id,
    accessToken: row.access_token,
    executiveSummary: reportData.executiveSummary ?? "",
    recommendations: (row.color_recommendations ?? []).map(mapColorRecommendation),
    sunData: mapSunData(row.sun_data),
    applicationTips: reportData.applicationTips ?? [],
    surfacePrep: reportData.surfacePrep ?? [],
    pdfUrl: `/api/consultation/report/${row.id}/pdf?token=${row.access_token}`,
    createdAt: row.created_at,
  };
}

function mapColorRecommendation(raw: unknown): ColorRecommendation {
  const recommendation = (raw ?? {}) as Partial<ColorRecommendation>;
  const hex = recommendation.hex ?? "FFFFFF";

  return {
    colorName: recommendation.colorName ?? "Recommended Color",
    colorNumber: recommendation.colorNumber ?? "N/A",
    hex,
    rationale: recommendation.rationale ?? "",
    finishSheen: recommendation.finishSheen ?? "Eggshell",
    morningHex: recommendation.morningHex ?? hex,
    afternoonHex: recommendation.afternoonHex ?? hex,
    eveningHex: recommendation.eveningHex ?? hex,
    visualizationUrl: recommendation.visualizationUrl,
    originalUrl: recommendation.originalUrl,
  };
}

function mapSunData(raw: Partial<SunData> | null | undefined): SunData {
  return {
    sunrise: raw?.sunrise ?? "",
    sunset: raw?.sunset ?? "",
    solarNoon: raw?.solarNoon ?? "",
    goldenHour: raw?.goldenHour ?? "",
    sunPath: raw?.sunPath ?? [],
    dayLengthHours: raw?.dayLengthHours ?? 0,
    lightingAnalysis: raw?.lightingAnalysis ?? "",
  };
}
