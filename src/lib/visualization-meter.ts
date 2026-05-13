import { sql } from "@vercel/postgres";
import { hashDeviceId, verifyStoreKitTransaction } from "@/lib/storekit";

export const FREE_COMPLETED_VISUALIZATION_LIMIT = Number(
  process.env.FREE_COMPLETED_VISUALIZATION_LIMIT ?? 5
);

export interface VisualizationUsage {
  completedCount: number;
  freeLimit: number;
  remainingFree: number;
  hasEntitlement: boolean;
}

async function ensureMeterTables(): Promise<void> {
  await sql`
    CREATE TABLE IF NOT EXISTS visualizer_usage (
      device_id_hash TEXT PRIMARY KEY,
      completed_count INTEGER NOT NULL DEFAULT 0,
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  `;

  await sql`
    CREATE TABLE IF NOT EXISTS visualizer_entitlements (
      device_id_hash TEXT PRIMARY KEY,
      product_id TEXT NOT NULL,
      transaction_id TEXT NOT NULL,
      original_transaction_id TEXT NOT NULL,
      expires_at TIMESTAMPTZ,
      revoked_at TIMESTAMPTZ,
      updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  `;
}

export function normalizeDeviceId(deviceId: FormDataEntryValue | null): string | null {
  if (typeof deviceId !== "string") return null;
  const normalized = deviceId.trim();
  if (!/^[a-zA-Z0-9._:-]{16,128}$/.test(normalized)) return null;
  return normalized;
}

async function hasActiveEntitlement(deviceIdHash: string): Promise<boolean> {
  const result = await sql<{ active: boolean }>`
    SELECT EXISTS (
      SELECT 1
      FROM visualizer_entitlements
      WHERE device_id_hash = ${deviceIdHash}
        AND revoked_at IS NULL
        AND (expires_at IS NULL OR expires_at > now())
    ) AS active
  `;

  return result.rows[0]?.active ?? false;
}

export async function upsertStoreKitEntitlement(
  deviceId: string,
  signedTransactionJWS?: string | null
): Promise<boolean> {
  if (!signedTransactionJWS) return false;
  await ensureMeterTables();

  const verified = verifyStoreKitTransaction(signedTransactionJWS);
  const deviceIdHash = hashDeviceId(deviceId);

  await sql`
    INSERT INTO visualizer_entitlements
      (device_id_hash, product_id, transaction_id, original_transaction_id, expires_at, revoked_at, updated_at)
    VALUES
      (${deviceIdHash}, ${verified.productId}, ${verified.transactionId}, ${verified.originalTransactionId}, ${verified.expiresAt?.toISOString() ?? null}, NULL, now())
    ON CONFLICT (device_id_hash)
    DO UPDATE SET
      product_id = EXCLUDED.product_id,
      transaction_id = EXCLUDED.transaction_id,
      original_transaction_id = EXCLUDED.original_transaction_id,
      expires_at = EXCLUDED.expires_at,
      revoked_at = NULL,
      updated_at = now()
  `;

  return true;
}

export async function getVisualizationUsage(deviceId: string): Promise<VisualizationUsage> {
  await ensureMeterTables();
  const deviceIdHash = hashDeviceId(deviceId);

  const [usageResult, entitlementActive] = await Promise.all([
    sql<{ completed_count: number }>`
      SELECT completed_count
      FROM visualizer_usage
      WHERE device_id_hash = ${deviceIdHash}
    `,
    hasActiveEntitlement(deviceIdHash),
  ]);

  const completedCount = usageResult.rows[0]?.completed_count ?? 0;
  return {
    completedCount,
    freeLimit: FREE_COMPLETED_VISUALIZATION_LIMIT,
    remainingFree: Math.max(FREE_COMPLETED_VISUALIZATION_LIMIT - completedCount, 0),
    hasEntitlement: entitlementActive,
  };
}

export async function assertCanCreateVisualization(deviceId: string): Promise<VisualizationUsage> {
  const usage = await getVisualizationUsage(deviceId);
  if (!usage.hasEntitlement && usage.completedCount >= usage.freeLimit) {
    const error = new Error("Free visualization limit reached.") as Error & {
      status: number;
      code: string;
      usage: VisualizationUsage;
    };
    error.status = 402;
    error.code = "FREE_LIMIT_EXCEEDED";
    error.usage = usage;
    throw error;
  }
  return usage;
}

export async function incrementCompletedVisualization(deviceId: string): Promise<VisualizationUsage> {
  await ensureMeterTables();
  const deviceIdHash = hashDeviceId(deviceId);

  await sql`
    INSERT INTO visualizer_usage (device_id_hash, completed_count, updated_at)
    VALUES (${deviceIdHash}, 1, now())
    ON CONFLICT (device_id_hash)
    DO UPDATE SET
      completed_count = visualizer_usage.completed_count + 1,
      updated_at = now()
  `;

  return getVisualizationUsage(deviceId);
}
