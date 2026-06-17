#!/usr/bin/env bash
# Unified launcher — one command starts backend + AI (voice + OCR) + optional Flutter app.
# Usage: ./start.sh [--no-app] [--device <id>]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$ROOT/logs"
mkdir -p "$LOG_DIR"

RUN_APP=true
FLUTTER_DEVICE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-app) RUN_APP=false; shift ;;
    --device) FLUTTER_DEVICE="${2:-}"; shift 2 ;;
    -h|--help)
      echo "Usage: ./start.sh [--no-app] [--device <flutter-device-id>]"
      echo ""
      echo "  Starts unified server (Node :3001 + AI :8000 voice/OCR) and Flutter app"
      echo "  Log: logs/server.log"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

log() { echo "[start] $*"; }

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1"
    exit 1
  fi
}

wait_for_url() {
  local url="$1" name="$2" max="${3:-60}"
  for ((i = 1; i <= max; i++)); do
    if curl -sf "$url" >/dev/null 2>&1; then
      log "✅ $name ready ($url)"
      return 0
    fi
    sleep 1
  done
  echo "❌ $name did not start in ${max}s — check logs/server.log"
  return 1
}

free_port() {
  local port="$1"
  local pids
  pids=$(lsof -ti tcp:"$port" 2>/dev/null || true)
  if [[ -n "$pids" ]]; then
    log "Freeing port $port..."
    kill $pids 2>/dev/null || true
    sleep 1
  fi
}

need_cmd node
need_cmd npm
need_cmd python3
need_cmd curl
if $RUN_APP; then need_cmd flutter; fi

log "Project root: $ROOT"

# ── Unified server (Node backend + spawns voice/OCR AI on :8000) ─────────────
free_port 3001
free_port 3002
free_port 8000

if [[ ! -d "$ROOT/backend_temp/node_modules" ]]; then
  log "Installing backend dependencies..."
  (cd "$ROOT/backend_temp" && npm install)
fi

log "Starting unified server..."
( cd "$ROOT/backend_temp" && node src/server.js ) >"$LOG_DIR/server.log" 2>&1 &
SERVER_PID=$!

cleanup() {
  echo ""
  log "Stopping server..."
  kill "$SERVER_PID" 2>/dev/null || true
  wait "$SERVER_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

wait_for_url "http://127.0.0.1:3001/api" "Backend"
wait_for_url "http://127.0.0.1:8000/health" "AI (voice + OCR)"

log ""
log "All services running:"
log "  API      → http://localhost:3001"
log "  Voice    → http://localhost:8000/analyze | /voice"
log "  OCR      → http://localhost:8000/ocr/scan"
log "  WebSocket→ ws://localhost:3002"
log ""

if ! $RUN_APP; then
  log "Services only (--no-app). Press Ctrl+C to stop."
  wait "$SERVER_PID"
  exit 0
fi

log "Launching Flutter app..."
cd "$ROOT"
if [[ -n "$FLUTTER_DEVICE" ]]; then
  flutter run lib/main.dart -d "$FLUTTER_DEVICE"
else
  flutter run lib/main.dart
fi
