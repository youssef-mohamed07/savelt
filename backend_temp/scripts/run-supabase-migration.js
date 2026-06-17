/**
 * Run DDL against Supabase using DIRECT_URL (session-mode pooler).
 * Usage: node scripts/run-supabase-migration.js
 */
import pg from 'pg';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, '../.env') });

const directUrl = process.env.DIRECT_URL;
if (!directUrl) {
  console.error('DIRECT_URL missing from .env');
  process.exit(1);
}

const sql = fs.readFileSync(path.join(__dirname, 'migrate-supabase.sql'), 'utf8');
const client = new pg.Client({
  connectionString: directUrl,
  ssl: { rejectUnauthorized: false },
});

try {
  await client.connect();
  await client.query(sql);
  const { rows } = await client.query(
    `SELECT table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY table_name`
  );
  console.log('[MIGRATE] ✅ Tables:', rows.map((r) => r.table_name).join(', '));
} catch (err) {
  console.error('[MIGRATE] ❌', err.message);
  process.exit(1);
} finally {
  await client.end();
}
