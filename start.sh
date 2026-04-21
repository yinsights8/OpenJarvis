#!/usr/bin/env bash
# Start OpenJarvis: Ollama + backend + UI in one command.
# Usage:
#   ./start.sh          # Web UI (http://localhost:5173)
#   ./start.sh --app    # Tauri desktop app

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODE="web"
[[ "$1" == "--app" ]] && MODE="app"

# Cleanup all background processes on exit
cleanup() {
  echo ""
  echo "Shutting down..."
  [[ -n "$JARVIS_PID" ]] && kill "$JARVIS_PID" 2>/dev/null
  [[ -n "$OLLAMA_PID" ]] && kill "$OLLAMA_PID" 2>/dev/null
  exit 0
}
trap cleanup SIGINT SIGTERM

# ── 1. Ollama ────────────────────────────────────────────────────────────────
if curl -s http://127.0.0.1:11434 > /dev/null 2>&1; then
  echo "[1/3] Ollama already running."
else
  echo "[1/3] Starting Ollama..."
  ollama serve > /tmp/ollama.log 2>&1 &
  OLLAMA_PID=$!
  # Wait up to 10s for Ollama to be ready
  for i in $(seq 1 10); do
    curl -s http://127.0.0.1:11434 > /dev/null 2>&1 && break
    sleep 1
  done
  echo "      Ollama ready."
fi

# ── 2. Python backend ─────────────────────────────────────────────────────────
echo "[2/3] Starting jarvis backend..."
cd "$SCRIPT_DIR"
unset CONDA_PREFIX
uv run jarvis serve > /tmp/jarvis_serve.log 2>&1 &
JARVIS_PID=$!

# Wait up to 20s for backend to be ready
echo "      Waiting for backend at http://127.0.0.1:8000..."
READY=0
for i in $(seq 1 60); do
  if curl -s http://127.0.0.1:8000/v1/speech/health > /dev/null 2>&1; then
    READY=1
    break
  fi
  sleep 1
done

if [[ $READY -eq 0 ]]; then
  echo "ERROR: Backend did not start in time. Check /tmp/jarvis_serve.log"
  cleanup
fi
echo "      Backend ready."

# ── 3. Frontend ───────────────────────────────────────────────────────────────
cd "$SCRIPT_DIR/frontend"
if [[ "$MODE" == "app" ]]; then
  echo "[3/3] Starting Tauri desktop app (first run compiles Rust — takes a few minutes)..."
  npm run tauri dev
else
  echo "[3/3] Starting Web UI at http://localhost:5173 ..."
  npm run dev
fi
