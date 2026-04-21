# OpenJarvis — Daily Usage Guide

> **Setup is one-time only.** Once installed, you do NOT need to re-run `uv sync`, `maturin develop`, or `jarvis init` every session. Only run those again after pulling new code changes.

---

## One-Command Start (Recommended)

Start everything — Ollama, backend, and UI — with a single command from the project root:

```bash
# Web UI (opens http://localhost:5173 in browser)
./start.sh

# Tauri desktop app
./start.sh --app
```

Press **Ctrl+C** to cleanly shut down the backend and Ollama together.

Logs:
- `/tmp/jarvis_serve.log` — Python backend output
- `/tmp/ollama.log` — Ollama output

---

## How to Run Jarvis from Anywhere

Add the `jarvis` command to Git Bash so it works from any directory.

**One-time setup** — run this once:
```bash
source ~/.bashrc
```

After that, open any Git Bash terminal and type:
```bash
jarvis            # starts Ollama + backend + Web UI at localhost:5173
jarvis --app      # starts Ollama + backend + Tauri desktop app
```

The `jarvis` command also works as the full CLI:
```bash
jarvis ask "what's the weather?"
jarvis chat
jarvis digest
```

> New terminals load `~/.bashrc` automatically — no need to source it again.

---

## Every Day: Minimum Required

**1. Verify Ollama is running** (usually auto-starts on Windows boot):
```bash
ollama list
```
If no output or error → start it: open the Ollama app from the system tray, or run `ollama serve`.

**2. Use jarvis:**
```bash
cd E:/workspace/Personal_AI/OpenJarvis

uv run jarvis ask "what's the weather?"    # one-shot question
uv run jarvis chat                          # interactive chat
uv run jarvis digest                        # morning digest with TTS audio
```

That's it — nothing else needed for CLI use.

---

## Activate Venv (Optional Shortcut)

To type `jarvis` instead of `uv run jarvis`, activate the venv once per terminal:

```bash
# Git Bash / bash:
source .venv/Scripts/activate

# PowerShell:
.venv\Scripts\Activate.ps1

# Then use directly:
jarvis ask "hello"
jarvis chat
jarvis digest
```

---

## For REST API / STT / Server Features

Start the backend server (keep this terminal open):
```bash
cd E:/workspace/Personal_AI/OpenJarvis
unset CONDA_PREFIX
uv run jarvis serve
# Server starts at http://127.0.0.1:8000
```

Test STT is working:
```bash
curl http://127.0.0.1:8000/v1/speech/health
# Expected: {"available": true, "backend": "faster-whisper"}
```

Transcribe a WAV file:
```bash
curl -X POST http://127.0.0.1:8000/v1/speech/transcribe \
  -F "file=@your_audio.wav"
```

---

## For the Web UI

Requires `jarvis serve` running first (see above), then in a new terminal:

```bash
cd E:/workspace/Personal_AI/OpenJarvis/frontend
npm run dev
# Open http://localhost:5173 in your browser
```

---

## For the Desktop App (Tauri)

Requires `jarvis serve` running first, then:

```bash
cd E:/workspace/Personal_AI/OpenJarvis/frontend
npm run tauri dev
# Opens a native Windows desktop app window
```

> Tauri compiles Rust on first run — takes a few minutes. Subsequent starts are faster.

---

## When to Re-run Setup Commands

| Situation | Command needed |
|-----------|---------------|
| After `git pull` (new code) | `uv sync --extra dev --extra speech --extra server` + `maturin develop` |
| Rust extension missing after sync | `uv run maturin develop -m rust/crates/openjarvis-python/Cargo.toml` |
| Changing inference engine or model | Edit `~/.openjarvis/config.toml` only — no reinstall needed |
| Adding a new extra (e.g. `learning`) | `uv sync --extra dev --extra speech --extra server --extra learning` |
| Frontend dependencies changed | `cd frontend && npm install` |

---

## Quick Reference

```
Ollama running?          ollama list
Ask a question           uv run jarvis ask "..."
Chat interactively       uv run jarvis chat
Morning digest (TTS)     uv run jarvis digest
Start API server         uv run jarvis serve
Web UI                   cd frontend && npm run dev  →  localhost:5173
Desktop app              cd frontend && npm run tauri dev
```
