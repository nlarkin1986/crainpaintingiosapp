export const VISUALIZATION_STATUSES = [
  "queued",
  "processing",
  "completed",
  "failed",
  "expired",
] as const;

export type VisualizationStatus = (typeof VISUALIZATION_STATUSES)[number];

export const MEDIA_ROLES = ["original", "result"] as const;
export type MediaRole = (typeof MEDIA_ROLES)[number];

export const MEDIA_VARIANTS = ["canonical", "job", "card", "full"] as const;
export type MediaVariant = (typeof MEDIA_VARIANTS)[number];

export interface VisualizationRow {
  id: string;
  installation_id: string;
  client_request_id: string;
  status: VisualizationStatus;
  brand: string;
  color_name: string;
  color_number: string;
  color_hex: string;
  surface: string;
  custom_instruction: string | null;
  prompt_version: string;
  provider: string | null;
  model: string | null;
  original_asset_id: string | null;
  result_asset_id: string | null;
  share_token: string;
  request_ip: string | null;
  width: number | null;
  height: number | null;
  error_code: string | null;
  error_message: string | null;
  created_at: string | Date;
  updated_at: string | Date;
  completed_at: string | Date | null;
  expires_at: string | Date;
}

export interface MediaAssetRow {
  id: string;
  visualization_id: string;
  role: MediaRole;
  variant: MediaVariant;
  storage_key: string;
  mime_type: string;
  width: number;
  height: number;
  file_size_bytes: number;
  created_at: string | Date;
}

export interface VisualizationAttemptRow {
  id: string;
  visualization_id: string;
  attempt_no: number;
  provider: string;
  model: string;
  status: "started" | "succeeded" | "failed";
  latency_ms: number | null;
  error_code: string | null;
  error_message: string | null;
  started_at: string | Date;
  finished_at: string | Date | null;
}
