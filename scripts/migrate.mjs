import { createPool } from '@vercel/postgres';
import { readdirSync, readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

function getDatabaseConnectionString() {
  const keys = [
    'POSTGRES_URL',
    'DATABASE_URL',
    'crainios_POSTGRES_URL',
    'crainios_DATABASE_URL',
  ];

  for (const key of keys) {
    const value = process.env[key]?.trim();
    if (value) {
      return value;
    }
  }

  throw new Error('Database connection string is not configured. Set POSTGRES_URL or DATABASE_URL.');
}

const pool = createPool({ connectionString: getDatabaseConnectionString() });

async function migrate() {
  console.log('Running migrations...');
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        name TEXT PRIMARY KEY,
        applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
      )
    `);

    const migrationDir = join(__dirname, '../migrations');
    const migrationFiles = readdirSync(migrationDir)
      .filter((file) => file.endsWith('.sql'))
      .sort();

    for (const file of migrationFiles) {
      const alreadyApplied = await pool.query(
        'SELECT 1 FROM schema_migrations WHERE name = $1 LIMIT 1',
        [file]
      );

      if (alreadyApplied.rowCount) {
        console.log(`Skipping ${file} (already applied).`);
        continue;
      }

      const sql = readFileSync(join(migrationDir, file), 'utf-8');
      console.log(`Applying ${file}...`);

      await pool.query('BEGIN');
      try {
        await pool.query(sql);
        await pool.query(
          'INSERT INTO schema_migrations (name) VALUES ($1)',
          [file]
        );
        await pool.query('COMMIT');
      } catch (error) {
        await pool.query('ROLLBACK');
        throw error;
      }
    }

    console.log('Migrations complete.');
  } catch (err) {
    console.error('Migration failed:', err);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

migrate();
