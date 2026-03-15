CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS installations (
  id            UUID PRIMARY KEY,
  platform      TEXT NOT NULL DEFAULT 'ios',
  app_version   TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_seen_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS visualizations (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  installation_id    UUID NOT NULL REFERENCES installations(id) ON DELETE CASCADE,
  client_request_id  UUID NOT NULL,
  status             TEXT NOT NULL CHECK (status IN ('queued', 'processing', 'completed', 'failed', 'expired')),
  brand              TEXT NOT NULL,
  color_name         TEXT NOT NULL,
  color_number       TEXT NOT NULL,
  color_hex          CHAR(6) NOT NULL,
  surface            TEXT NOT NULL,
  custom_instruction TEXT,
  prompt_version     TEXT NOT NULL,
  provider           TEXT,
  model              TEXT,
  original_asset_id  UUID,
  result_asset_id    UUID,
  share_token        TEXT NOT NULL DEFAULT encode(gen_random_bytes(12), 'hex'),
  width              INT,
  height             INT,
  request_ip         TEXT,
  error_code         TEXT,
  error_message      TEXT,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at       TIMESTAMPTZ,
  expires_at         TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '30 days'),
  UNIQUE (installation_id, client_request_id)
);

CREATE INDEX IF NOT EXISTS idx_visualizations_installation_created
  ON visualizations (installation_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_visualizations_status_created
  ON visualizations (status, created_at);
CREATE INDEX IF NOT EXISTS idx_visualizations_expires_at
  ON visualizations (expires_at);
CREATE INDEX IF NOT EXISTS idx_visualizations_request_ip_created
  ON visualizations (request_ip, created_at DESC);

CREATE TABLE IF NOT EXISTS media_assets (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  visualization_id UUID NOT NULL REFERENCES visualizations(id) ON DELETE CASCADE,
  role             TEXT NOT NULL CHECK (role IN ('original', 'result')),
  variant          TEXT NOT NULL CHECK (variant IN ('canonical', 'job', 'card', 'full')),
  storage_key      TEXT NOT NULL,
  mime_type        TEXT NOT NULL,
  width            INT NOT NULL,
  height           INT NOT NULL,
  file_size_bytes  BIGINT NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_media_assets_visualization_role_variant
  ON media_assets (visualization_id, role, variant);

CREATE TABLE IF NOT EXISTS visualization_attempts (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  visualization_id UUID NOT NULL REFERENCES visualizations(id) ON DELETE CASCADE,
  attempt_no       INT NOT NULL,
  provider         TEXT NOT NULL,
  model            TEXT NOT NULL,
  status           TEXT NOT NULL CHECK (status IN ('started', 'succeeded', 'failed')),
  latency_ms       INT,
  error_code       TEXT,
  error_message    TEXT,
  started_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at      TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_visualization_attempts_visualization_attempt
  ON visualization_attempts (visualization_id, attempt_no);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'visualizations_original_asset_id_fkey'
  ) THEN
    ALTER TABLE visualizations
      ADD CONSTRAINT visualizations_original_asset_id_fkey
      FOREIGN KEY (original_asset_id) REFERENCES media_assets(id) ON DELETE SET NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'visualizations_result_asset_id_fkey'
  ) THEN
    ALTER TABLE visualizations
      ADD CONSTRAINT visualizations_result_asset_id_fkey
      FOREIGN KEY (result_asset_id) REFERENCES media_assets(id) ON DELETE SET NULL;
  END IF;
END $$;
