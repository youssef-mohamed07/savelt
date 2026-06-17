/**
 * Supabase Postgres connection pool (transaction-mode pooler).
 * Use DIRECT_URL only for migrations / DDL.
 */
import pg from 'pg';
import { config } from './index.js';

const { Pool } = pg;

let pool = null;

export function getPool() {
  if (!pool) {
    if (!config.databaseUrl) {
      throw new Error('[DB] DATABASE_URL is missing');
    }
    pool = new Pool({
      connectionString: config.databaseUrl,
      ssl: { rejectUnauthorized: false },
      max: 10,
    });
    pool.on('error', (err) => {
      console.error('[DB] Postgres pool error:', err.message);
    });
  }
  return pool;
}

export async function connectPostgres() {
  const client = await getPool().connect();
  try {
    const { rows } = await client.query('SELECT current_database() AS db, NOW() AS ts');
    console.log(`[DB] ✅ Connected to Postgres (Supabase): ${rows[0].db}`);
    return true;
  } finally {
    client.release();
  }
}

export async function disconnectPostgres() {
  if (pool) {
    await pool.end();
    pool = null;
  }
}
