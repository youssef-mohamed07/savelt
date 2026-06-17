#!/usr/bin/env bash
# Unified launcher — backend + AI + Flutter in parallel.
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
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

log() { echo "[start] $*"; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1"; exit 1; }
}

free_port() {
  local port="$1"
  local pids
  pids=$(lsof -ti tcp:"$port" 2>/dev/null || true)
  [[ -z "$pids" ]] && return 0
  log "Freeing port $port..."
  kill $pids 2>/dev/null || true
  sleep 0.3
  pids=$(lsof -ti tcp:"$port" 2>/dev/null || true)
  [[ -n "$pids" ]] && kill -9 $pids 2>/dev/null || true
}

# Fast poll — interval 0.25s, default ~45s max
wait_for_url() {
  local url="$1" name="$2" max_sec="${3:-45}"
  local i max_iter=$((max_sec * 4))
  for ((i = 1; i <= max_iter; i++)); do
    if curl -sf --connect-timeout 1 --max-time 2 "$url" >/dev/null 2>&1; then
      log "✅ $name ready"
      return 0
    fi
    sleep 0.25
  done
  echo "❌ $name not ready after ${max_sec}s — see logs/server.log"
  return 1
}

need_cmd node
need_cmd npm
need_cmd curl
if $RUN_APP; then need_cmd flutter; fi

log "Project root: $ROOT"

free_port 3001
free_port 3002
free_port 8000

if [[ ! -d "$ROOT/backend_temp/node_modules" ]]; then
  log "Installing backend dependencies..."
  (cd "$ROOT/backend_temp" && npm install)
fi

log "Starting all services..."
( cd "$ROOT/backend_temp" && node src/server.js ) >"$LOG_DIR/server.log" 2>&1 &
SERVER_PID=$!

cleanup() {
  echo ""
  log "Stopping..."
  kill "$SERVER_PID" 2>/dev/null || true
  wait "$SERVER_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Backend + AI health checks in parallel
BACKEND_OK=0
AI_OK=0

wait_for_url "http://127.0.0.1:3001/health" "Backend (API :3001)" 30 &
W1=$!
wait_for_url "http://127.0.0.1:8000/health" "AI (voice+OCR :8000)" 60 &
W2=$!

wait $W1 && BACKEND_OK=1 || true
wait $W2 && AI_OK=1 || true

if [[ $BACKEND_OK -eq 0 ]]; then
  tail -20 "$LOG_DIR/server.log" 2>/dev/null || true
  exit 1
fi

[[ $AI_OK -eq 0 ]] && log "⚠️  AI not ready — voice/OCR may fail until :8000 is up"

log ""
log "Services:"
log "  API       → http://localhost:3001"
log "  AI        → http://localhost:8000"
log "  WebSocket → ws://localhost:3002"
log ""

if ! $RUN_APP; then
  log "Running (--no-app). Ctrl+C to stop."
  wait "$SERVER_PID"
  exit 0
fi

log "Launching Flutter..."
cd "$ROOT"
if [[ -n "$FLUTTER_DEVICE" ]]; then
  flutter run lib/main.dart -d "$FLUTTER_DEVICE"
else
  flutter run lib/main.dart
fi
