import {
  createPool as createVercelPool,
  sql as vercelSql,
  type VercelPoolClient,
} from "@vercel/postgres";

const DATABASE_ENV_KEYS = [
  "POSTGRES_URL",
  "DATABASE_URL",
  "crainios_POSTGRES_URL",
  "crainios_DATABASE_URL",
] as const;

let pool: ReturnType<typeof createVercelPool> | null = null;

export function getDatabaseConnectionString(): string | null {
  for (const key of DATABASE_ENV_KEYS) {
    const value = process.env[key]?.trim();
    if (value) {
      return value;
    }
  }

  return null;
}

export function hasDatabaseConnectionString(): boolean {
  return getDatabaseConnectionString() !== null;
}

export function requireDatabaseConnectionString(): string {
  const connectionString = getDatabaseConnectionString();
  if (!connectionString) {
    throw new Error(
      "Database connection string is not configured. Set POSTGRES_URL or DATABASE_URL."
    );
  }

  return connectionString;
}

export function getPostgresPool() {
  if (!pool) {
    pool = createVercelPool({
      connectionString: requireDatabaseConnectionString(),
    });
  }

  return pool;
}

export const sql: typeof vercelSql = ((strings: TemplateStringsArray, ...values: unknown[]) =>
  getPostgresPool().sql(strings, ...(values as never[]))) as typeof vercelSql;

export type { VercelPoolClient };
