import { getPostgresPool, sql, type VercelPoolClient } from "@/lib/postgres";
import type {
  MediaAssetRow,
  MediaVariant,
  VisualizationAttemptRow,
  VisualizationRow,
} from "@/types/visualization";
import type { UploadedVisualizationAsset } from "@/lib/visualization-assets";

const HOURLY_INSTALLATION_LIMIT = 30;
const HOURLY_IP_LIMIT = 10;
const MAX_ACTIVE_JOBS_PER_INSTALLATION = 3;
export class VisualizationRateLimitError extends Error {
  code = "RATE_LIMITED";
  status = 429;
  retryAfterSeconds: number;

  constructor(message: string, retryAfterSeconds: number) {
    super(message);
    this.name = "VisualizationRateLimitError";
    this.retryAfterSeconds = retryAfterSeconds;
  }
}

async function withTransaction<T>(
  callback: (client: VercelPoolClient) => Promise<T>
): Promise<T> {
  const client = await getPostgresPool().connect();
  try {
    await client.query("BEGIN");
    const result = await callback(client);
    await client.query("COMMIT");
    return result;
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}

function computeRetryAfterSeconds(oldest: string | Date | null): number {
  if (!oldest) {
    return 60;
  }
  const retryAt = new Date(oldest).getTime() + 60 * 60 * 1000;
  return Math.max(1, Math.ceil((retryAt - Date.now()) / 1000));
}

export async function upsertInstallation(input: {
  installationId: string;
  appVersion?: string | null;
}) {
  await sql`
    INSERT INTO installations (id, app_version)
    VALUES (${input.installationId}, ${input.appVersion ?? null})
    ON CONFLICT (id) DO UPDATE
    SET app_version = COALESCE(EXCLUDED.app_version, installations.app_version),
        last_seen_at = now()
  `;
}

export async function getVisualizationByClientRequest(input: {
  installationId: string;
  clientRequestId: string;
}): Promise<VisualizationRow | null> {
  const result = await sql<VisualizationRow>`
    SELECT *
    FROM visualizations
    WHERE installation_id = ${input.installationId}
      AND client_request_id = ${input.clientRequestId}
    LIMIT 1
  `;
  return result.rows[0] ?? null;
}

async function enforceVisualizationRateLimits(input: {
  installationId: string;
  requestIp: string | null;
}) {
  const installResult = await sql<{ count: number; oldest: string | null }>`
    SELECT COUNT(*)::int AS count,
           MIN(created_at)::text AS oldest
    FROM visualizations
    WHERE installation_id = ${input.installationId}
      AND created_at >= now() - interval '1 hour'
  `;

  const installWindow = installResult.rows[0];
  if (installWindow && installWindow.count >= HOURLY_INSTALLATION_LIMIT) {
    throw new VisualizationRateLimitError(
      "This device has reached the hourly preview limit. Please try again shortly.",
      computeRetryAfterSeconds(installWindow.oldest)
    );
  }

  if (input.requestIp) {
    const ipResult = await sql<{ count: number; oldest: string | null }>`
      SELECT COUNT(*)::int AS count,
             MIN(created_at)::text AS oldest
      FROM visualizations
      WHERE request_ip = ${input.requestIp}
        AND created_at >= now() - interval '1 hour'
    `;

    const ipWindow = ipResult.rows[0];
    if (ipWindow && ipWindow.count >= HOURLY_IP_LIMIT) {
      throw new VisualizationRateLimitError(
        "Too many preview requests are coming from this network right now. Please try again shortly.",
        computeRetryAfterSeconds(ipWindow.oldest)
      );
    }
  }

  const activeResult = await sql<{ count: number }>`
    SELECT COUNT(*)::int AS count
    FROM visualizations
    WHERE installation_id = ${input.installationId}
      AND status IN ('queued', 'processing')
  `;

  const activeCount = activeResult.rows[0]?.count ?? 0;
  if (activeCount >= MAX_ACTIVE_JOBS_PER_INSTALLATION) {
    throw new VisualizationRateLimitError(
      "This device already has too many previews in progress. Please wait for one to finish.",
      10
    );
  }
}

export async function createVisualizationJob(input: {
  installationId: string;
  clientRequestId: string;
  brand: string;
  colorName: string;
  colorNumber: string;
  colorHex: string;
  surface: string;
  customInstruction?: string | null;
  promptVersion: string;
  requestIp: string | null;
}): Promise<{ visualization: VisualizationRow; isNew: boolean }> {
  const existing = await getVisualizationByClientRequest({
    installationId: input.installationId,
    clientRequestId: input.clientRequestId,
  });
  if (existing) {
    return { visualization: existing, isNew: false };
  }

  await enforceVisualizationRateLimits({
    installationId: input.installationId,
    requestIp: input.requestIp,
  });

  const inserted = await sql<VisualizationRow>`
    INSERT INTO visualizations (
      installation_id,
      client_request_id,
      status,
      brand,
      color_name,
      color_number,
      color_hex,
      surface,
      custom_instruction,
      prompt_version,
      request_ip
    )
    VALUES (
      ${input.installationId},
      ${input.clientRequestId},
      'queued',
      ${input.brand},
      ${input.colorName},
      ${input.colorNumber},
      ${input.colorHex},
      ${input.surface},
      ${input.customInstruction ?? null},
      ${input.promptVersion},
      ${input.requestIp}
    )
    RETURNING *
  `;

  return { visualization: inserted.rows[0], isNew: true };
}

export async function saveOriginalVisualizationAssets(input: {
  visualizationId: string;
  assets: Record<MediaVariant, UploadedVisualizationAsset>;
  canonicalWidth: number;
  canonicalHeight: number;
}) {
  await withTransaction(async (client) => {
    let originalCanonicalId: string | null = null;

    for (const [variant, asset] of Object.entries(input.assets) as Array<
      [MediaVariant, UploadedVisualizationAsset]
    >) {
      const inserted = await client.sql<{ id: string }>`
        INSERT INTO media_assets (
          visualization_id,
          role,
          variant,
          storage_key,
          mime_type,
          width,
          height,
          file_size_bytes
        )
        VALUES (
          ${input.visualizationId},
          'original',
          ${variant},
          ${asset.storageKey},
          ${asset.mimeType},
          ${asset.width},
          ${asset.height},
          ${asset.fileSizeBytes}
        )
        ON CONFLICT (visualization_id, role, variant) DO UPDATE
        SET storage_key = EXCLUDED.storage_key,
            mime_type = EXCLUDED.mime_type,
            width = EXCLUDED.width,
            height = EXCLUDED.height,
            file_size_bytes = EXCLUDED.file_size_bytes
        RETURNING id
      `;

      if (variant === "canonical") {
        originalCanonicalId = inserted.rows[0]?.id ?? null;
      }
    }

    await client.sql`
      UPDATE visualizations
      SET original_asset_id = ${originalCanonicalId},
          width = ${input.canonicalWidth},
          height = ${input.canonicalHeight},
          updated_at = now()
      WHERE id = ${input.visualizationId}
    `;
  });
}

export async function getVisualizationForInstallation(input: {
  visualizationId: string;
  installationId: string;
}): Promise<VisualizationRow | null> {
  const result = await sql<VisualizationRow>`
    SELECT *
    FROM visualizations
    WHERE id = ${input.visualizationId}
      AND installation_id = ${input.installationId}
    LIMIT 1
  `;
  return result.rows[0] ?? null;
}

export async function getVisualizationById(
  visualizationId: string
): Promise<VisualizationRow | null> {
  const result = await sql<VisualizationRow>`
    SELECT *
    FROM visualizations
    WHERE id = ${visualizationId}
    LIMIT 1
  `;
  return result.rows[0] ?? null;
}

export async function listVisualizationAssets(
  visualizationId: string
): Promise<MediaAssetRow[]> {
  const result = await sql<MediaAssetRow>`
    SELECT *
    FROM media_assets
    WHERE visualization_id = ${visualizationId}
  `;
  return result.rows;
}

export async function getCanonicalOriginalAsset(
  visualizationId: string
): Promise<MediaAssetRow | null> {
  const result = await sql<MediaAssetRow>`
    SELECT *
    FROM media_assets
    WHERE visualization_id = ${visualizationId}
      AND role = 'original'
      AND variant = 'canonical'
    LIMIT 1
  `;
  return result.rows[0] ?? null;
}

export async function claimVisualizationForProcessing(
  visualizationId: string
): Promise<VisualizationRow | null> {
  const result = await sql<VisualizationRow>`
    UPDATE visualizations
    SET status = 'processing',
        updated_at = now(),
        error_code = NULL,
        error_message = NULL
    WHERE id = ${visualizationId}
      AND (
        status = 'queued'
        OR (status = 'processing' AND updated_at < now() - interval '5 minutes')
      )
    RETURNING *
  `;

  return result.rows[0] ?? null;
}

export async function startVisualizationAttempt(input: {
  visualizationId: string;
  provider: string;
  model: string;
}): Promise<VisualizationAttemptRow> {
  const result = await sql<VisualizationAttemptRow>`
    INSERT INTO visualization_attempts (
      visualization_id,
      attempt_no,
      provider,
      model,
      status
    )
    VALUES (
      ${input.visualizationId},
      COALESCE(
        (
          SELECT MAX(attempt_no) + 1
          FROM visualization_attempts
          WHERE visualization_id = ${input.visualizationId}
        ),
        1
      ),
      ${input.provider},
      ${input.model},
      'started'
    )
    RETURNING *
  `;

  return result.rows[0];
}

export async function finishVisualizationAttempt(input: {
  attemptId: string;
  status: "succeeded" | "failed";
  latencyMs: number;
  model?: string | null;
  errorCode?: string | null;
  errorMessage?: string | null;
}) {
  await sql`
    UPDATE visualization_attempts
    SET status = ${input.status},
        model = COALESCE(${input.model ?? null}, model),
        latency_ms = ${input.latencyMs},
        error_code = ${input.errorCode ?? null},
        error_message = ${input.errorMessage ?? null},
        finished_at = now()
    WHERE id = ${input.attemptId}
  `;
}

export async function completeVisualization(input: {
  visualizationId: string;
  provider: string;
  model: string;
  resultAssets: Record<MediaVariant, UploadedVisualizationAsset>;
}) {
  await withTransaction(async (client) => {
    let resultCanonicalId: string | null = null;

    for (const [variant, asset] of Object.entries(input.resultAssets) as Array<
      [MediaVariant, UploadedVisualizationAsset]
    >) {
      const inserted = await client.sql<{ id: string }>`
        INSERT INTO media_assets (
          visualization_id,
          role,
          variant,
          storage_key,
          mime_type,
          width,
          height,
          file_size_bytes
        )
        VALUES (
          ${input.visualizationId},
          'result',
          ${variant},
          ${asset.storageKey},
          ${asset.mimeType},
          ${asset.width},
          ${asset.height},
          ${asset.fileSizeBytes}
        )
        ON CONFLICT (visualization_id, role, variant) DO UPDATE
        SET storage_key = EXCLUDED.storage_key,
            mime_type = EXCLUDED.mime_type,
            width = EXCLUDED.width,
            height = EXCLUDED.height,
            file_size_bytes = EXCLUDED.file_size_bytes
        RETURNING id
      `;

      if (variant === "canonical") {
        resultCanonicalId = inserted.rows[0]?.id ?? null;
      }
    }

    const canonical = input.resultAssets.canonical;
    await client.sql`
      UPDATE visualizations
      SET status = 'completed',
          provider = ${input.provider},
          model = ${input.model},
          result_asset_id = ${resultCanonicalId},
          width = ${canonical.width},
          height = ${canonical.height},
          completed_at = now(),
          updated_at = now(),
          error_code = NULL,
          error_message = NULL
      WHERE id = ${input.visualizationId}
    `;
  });
}

export async function failVisualization(input: {
  visualizationId: string;
  errorCode: string;
  errorMessage: string;
}) {
  await sql`
    UPDATE visualizations
    SET status = 'failed',
        error_code = ${input.errorCode},
        error_message = ${input.errorMessage},
        updated_at = now()
    WHERE id = ${input.visualizationId}
  `;
}

export async function listQueuedVisualizationIds(limit: number): Promise<string[]> {
  const result = await sql<{ id: string }>`
    SELECT id
    FROM visualizations
    WHERE status = 'queued'
    ORDER BY created_at ASC
    LIMIT ${limit}
  `;
  return result.rows.map((row) => row.id);
}

export async function listExpiredVisualizations(limit: number): Promise<
  Array<{ id: string; storage_key: string }>
> {
  const result = await sql<{ id: string; storage_key: string }>`
    WITH expired AS (
      SELECT id
      FROM visualizations
      WHERE status = 'completed'
        AND expires_at < now()
      ORDER BY expires_at ASC
      LIMIT ${limit}
    )
    SELECT e.id, a.storage_key
    FROM expired e
    JOIN media_assets a ON a.visualization_id = e.id
  `;
  return result.rows;
}

export async function markVisualizationsExpired(visualizationIds: string[]) {
  if (visualizationIds.length === 0) {
    return;
  }

  await sql.query(
    `
      UPDATE visualizations
      SET status = 'expired',
          updated_at = now()
      WHERE id = ANY($1::uuid[])
    `,
    [visualizationIds]
  );
}
