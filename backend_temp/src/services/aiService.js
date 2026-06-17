/**
 * Unified AI service (voice + OCR) — spawns voice_server Python process.
 */
import { spawn } from 'child_process';
import path from 'path';
import fs from 'fs';
import crypto from 'crypto';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PROJECT_ROOT = path.resolve(__dirname, '../../..');
const AI_DIR = path.join(PROJECT_ROOT, 'voice_server');
const VENV_PYTHON = path.join(AI_DIR, '.venv', 'bin', 'python');
const REQUIREMENTS = path.join(AI_DIR, 'requirements.txt');
const DEPS_MARKER = path.join(AI_DIR, '.venv', '.deps-hash');

let aiProcess = null;

function log(msg) {
  console.log(`[AI] ${msg}`);
}

function requirementsHash() {
  if (!fs.existsSync(REQUIREMENTS)) return '';
  return crypto.createHash('sha256').update(fs.readFileSync(REQUIREMENTS)).digest('hex');
}

async function waitForHealth(url, maxMs = 45000, intervalMs = 250) {
  const deadline = Date.now() + maxMs;
  while (Date.now() < deadline) {
    try {
      const res = await fetch(url, { signal: AbortSignal.timeout(1500) });
      if (res.ok) return true;
    } catch {
      // still starting
    }
    await new Promise((r) => setTimeout(r, intervalMs));
  }
  return false;
}

async function runProcess(cmd, args, cwd) {
  await new Promise((resolve, reject) => {
    const child = spawn(cmd, args, { cwd, stdio: 'inherit' });
    child.on('close', (code) => (code === 0 ? resolve() : reject(new Error(`${cmd} exit ${code}`))));
  });
}

async function ensureAiDependencies() {
  if (!fs.existsSync(VENV_PYTHON)) {
    log('Creating Python venv…');
    await runProcess('python3', ['-m', 'venv', path.join(AI_DIR, '.venv')], AI_DIR);
  }

  const hash = requirementsHash();
  const marker = fs.existsSync(DEPS_MARKER) ? fs.readFileSync(DEPS_MARKER, 'utf8').trim() : '';
  if (hash && marker === hash) {
    return;
  }

  log('Installing AI dependencies (first run or requirements changed)…');
  await runProcess(VENV_PYTHON, ['-m', 'pip', 'install', '-q', '-r', REQUIREMENTS], AI_DIR);
  if (hash) fs.writeFileSync(DEPS_MARKER, hash);
}

export async function startAiService() {
  if (process.env.SKIP_AI === 'true') {
    log('Skipped (SKIP_AI=true)');
    return null;
  }

  if (!fs.existsSync(AI_DIR)) {
    log(`voice_server not found at ${AI_DIR} — skipping AI`);
    return null;
  }

  const python = fs.existsSync(VENV_PYTHON) ? VENV_PYTHON : 'python3';

  try {
    await ensureAiDependencies();
  } catch (err) {
    log(`⚠️  AI dependency install failed: ${err.message}`);
    return null;
  }

  const ocrEnvPath = path.join(PROJECT_ROOT, 'ocr_service', '.env');
  const env = {
    ...process.env,
    PORT: process.env.AI_PORT || '8000',
    HOST: process.env.AI_HOST || '0.0.0.0',
  };
  if (fs.existsSync(ocrEnvPath)) {
    const lines = fs.readFileSync(ocrEnvPath, 'utf8').split('\n');
    for (const line of lines) {
      const m = line.match(/^OPENAI_API_KEY=(.+)$/);
      if (m?.[1]?.trim()) env.OPENAI_API_KEY = m[1].trim();
    }
  }

  if (aiProcess && !aiProcess.killed) {
    return aiProcess;
  }

  log('Starting unified AI (voice + OCR) on :8000…');
  aiProcess = spawn(python, ['main.py'], {
    cwd: AI_DIR,
    env,
    stdio: ['ignore', 'pipe', 'pipe'],
  });

  aiProcess.stdout.on('data', (d) => process.stdout.write(`[AI] ${d}`));
  aiProcess.stderr.on('data', (d) => process.stderr.write(`[AI] ${d}`));
  aiProcess.on('exit', (code) => {
    if (code !== null && code !== 0) log(`Process exited with code ${code}`);
    aiProcess = null;
  });

  const ready = await waitForHealth('http://127.0.0.1:8000/health');
  if (ready) {
    log('✅ Unified AI ready (voice + OCR at http://127.0.0.1:8000)');
  } else {
    log('⚠️  AI health check timed out — check voice_server/.env');
  }

  return aiProcess;
}

export function stopAiService() {
  if (aiProcess && !aiProcess.killed) {
    log('Stopping AI service…');
    aiProcess.kill('SIGTERM');
    aiProcess = null;
  }
}
