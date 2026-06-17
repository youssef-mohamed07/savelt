/**
 * Unified AI service (voice + OCR) — spawns voice_server Python process.
 */
import { spawn } from 'child_process';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PROJECT_ROOT = path.resolve(__dirname, '../../..');
const AI_DIR = path.join(PROJECT_ROOT, 'voice_server');
const VENV_PYTHON = path.join(AI_DIR, '.venv', 'bin', 'python');
const REQUIREMENTS = path.join(AI_DIR, 'requirements.txt');

let aiProcess = null;

function log(msg) {
  console.log(`[AI] ${msg}`);
}

async function waitForHealth(url, maxSeconds = 60) {
  for (let i = 0; i < maxSeconds; i++) {
    try {
      const res = await fetch(url);
      if (res.ok) return true;
    } catch {
      // still starting
    }
    await new Promise((r) => setTimeout(r, 1000));
  }
  return false;
}

async function ensureAiDependencies() {
  if (!fs.existsSync(VENV_PYTHON)) {
    log('Creating Python venv for unified AI service…');
    await new Promise((resolve, reject) => {
      const venv = spawn('python3', ['-m', 'venv', path.join(AI_DIR, '.venv')], {
        cwd: AI_DIR,
        stdio: 'inherit',
      });
      venv.on('close', (code) => (code === 0 ? resolve() : reject(new Error(`venv exit ${code}`))));
    });
  }

  // Always sync deps — OCR packages were added after some venvs were created.
  log('Syncing AI Python dependencies…');
  await new Promise((resolve, reject) => {
    const pip = spawn(VENV_PYTHON, ['-m', 'pip', 'install', '-q', '-r', REQUIREMENTS], {
      cwd: AI_DIR,
      stdio: 'inherit',
    });
    pip.on('close', (code) => (code === 0 ? resolve() : reject(new Error(`pip exit ${code}`))));
  });
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

  // Load OCR keys from ocr_service/.env
  const ocrEnvPath = path.join(PROJECT_ROOT, 'ocr_service', '.env');
  const voiceEnvPath = path.join(AI_DIR, '.env');
  // Never inherit Node PORT (3001) — AI must stay on 8000
  const env = {
    ...process.env,
    PORT: process.env.AI_PORT || '8000',
    HOST: process.env.AI_HOST || '0.0.0.0',
  };
  if (fs.existsSync(ocrEnvPath)) {
    const lines = fs.readFileSync(ocrEnvPath, 'utf8').split('\n');
    for (const line of lines) {
      const m = line.match(/^OPENAI_API_KEY=(.+)$/);
      if (m && m[1].trim()) env.OPENAI_API_KEY = m[1].trim();
    }
  }
  if (!fs.existsSync(voiceEnvPath)) {
    log('⚠️  voice_server/.env missing — copy voice_server/.env.example');
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
  });

  const ready = await waitForHealth('http://127.0.0.1:8000/health');
  if (ready) {
    log('✅ Unified AI ready (voice + OCR at http://127.0.0.1:8000)');
  } else {
    log('⚠️  AI health check timed out — check voice_server/.env and logs');
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
