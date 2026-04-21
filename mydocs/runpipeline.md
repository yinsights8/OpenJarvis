# OpenJarvis Setup & TTS/STT Configuration Guide

**Complete executable walkthrough** — tested on Windows 11 with Python 3.12, Node.js 20+, and NVIDIA GTX 1050 Ti (4GB VRAM).

A step-by-step guide for setting up OpenJarvis from scratch, including installing and configuring Text-to-Speech (TTS) and Speech-to-Text (STT) capabilities.

---

## Prerequisites

- **Python**: 3.10 or higher (tested with 3.12)
- **Node.js**: 20 or higher
- **uv**: Python package manager ([install via https://docs.astral.sh/uv/](https://docs.astral.sh/uv/))
- **Ollama**: Local LLM runtime ([install via https://ollama.com](https://ollama.com))
- **ffmpeg**: For audio playback (Windows: `winget install ffmpeg`)
- **Windows-specific**: PowerShell or bash terminal
- **Hardware**: 4GB+ VRAM recommended for LLM inference

---

## Quick Start (5 minutes)

If you already have Python 3.10+, uv, and Ollama installed:

```bash
cd /path/to/openjarvis
uv sync --extra dev --extra speech --extra server
uv run maturin develop -m rust/crates/openjarvis-python/Cargo.toml
uv run jarvis init --force
uv run jarvis ask "hello"
```

---

## Full Installation Guide (Step-by-Step)

### Step 1: Prerequisites Check

Verify you have the required tools:

```bash
# Check Python version (need 3.10+)
python --version

# Check Node.js version (need 20+)
node --version

# Check uv is installed
uv --version

# Check Ollama is installed and running
ollama --version
```

**Expected output:**
```
Python 3.12.7
v20.11.0
uv 0.5.0
ollama version is 0.1.0
```

If any are missing:
- Python: https://python.org/downloads
- Node.js: https://nodejs.org
- uv: `pip install uv` or https://docs.astral.sh/uv/
- Ollama: https://ollama.com

---

### Step 2: Clone & Navigate to Project

```bash
# Clone the repository (if not already done)
git clone https://github.com/yourusername/openjarvis.git
cd openjarvis

# Verify project structure
ls -la
```

**You should see:**
```
pyproject.toml
CLAUDE.md
src/
rust/
frontend/
tests/
```

---

### Step 3: Create Virtual Environment & Install Dependencies

```bash
# Clean previous venv if it exists
rm -rf .venv

# Sync all dependencies with extras
uv sync --extra dev --extra speech --extra server

# Expected output: "Resolved 418 packages in Xms" + "Installed X packages"
```

**What gets installed:**
- Core OpenJarvis library
- Dev tools (pytest, ruff, pre-commit)
- Speech: faster-whisper, ctranslate2, onnxruntime
- Server: FastAPI, Uvicorn, Starlette

---

### Step 4: Build Rust Extension

The project includes Rust extensions (via PyO3) that must be compiled:

```bash
# Build the Rust crate and install as editable Python package
uv run maturin develop -m rust/crates/openjarvis-python/Cargo.toml

# Expected output: "Finished `dev` profile" + "🛠 Installed openjarvis-rust-0.1.0"
```

**Important:** After any `uv sync`, always rebuild:
```bash
uv run maturin develop -m rust/crates/openjarvis-python/Cargo.toml
```

---

### Step 5: Install Git Hooks

```bash
uv run pre-commit install

# Verify: you should see ".git/hooks/pre-commit" created
```

---

### Step 6: Initialize OpenJarvis Config

Run the interactive setup (must be in foreground terminal):

```bash
uv run jarvis init --force
```

**What happens:**
1. Detects your hardware (CPU cores, RAM, GPU)
2. Lists available inference engines
3. Creates `~/.openjarvis/config.toml`

**Expected prompts:**
```
Detecting hardware...
  Platform : windows
  CPU      : Intel64 Family 6 Model 158 Stepping 10, GenuineIntel (8 cores)
  RAM      : X.X GB
  GPU      : NVIDIA GeForce GTX 1050 Ti (4.0 GB VRAM, x1)

Available engines:
  ollama  (recommended)
  vllm
  sglang
  llamacpp
  mlx
  lmstudio
  exo
  nexa

Select inference engine: [ollama]
```

**Type:** `ollama` (or your preferred engine, then press Enter)

---

### Step 7: Verify Installation with Doctor

```bash
# Windows: Set UTF-8 to avoid encoding errors
PYTHONUTF8=1 uv run jarvis doctor

# Or on PowerShell:
$env:PYTHONUTF8=1; uv run jarvis doctor
```

This checks:
- Config file location
- Speech backend availability
- Engine connectivity
- Memory backends

---

### Step 8: Configure LLM Model

Edit `~/.openjarvis/config.toml`:

```bash
# On Windows (Git Bash):
nano ~/.openjarvis/config.toml

# On PowerShell:
notepad $env:USERPROFILE\.openjarvis\config.toml
```

Find the `[intelligence]` section and set your model:

```toml
[intelligence]
default_model = "gemma4:e4b"
```

**Model recommendations (for GTX 1050 Ti, 4GB VRAM):**

| Model | Size | Speed | Quality |
|-------|------|-------|---------|
| `qwen3.5:2b` | ~1.5GB | ⚡⚡⚡ | Good |
| `llama3.2:3b` | ~2GB | ⚡⚡ | Very Good |
| `phi3:mini` | ~2.3GB | ⚡⚡ | Excellent |
| `gemma3:4b` | ~3.3GB | ⚡ | Excellent |

Pull the model via Ollama:

```bash
ollama pull gemma4:e4b

# Expected: "pulling manifest" + "pulling layer" + "success"
```

---

### Step 9: Configure TTS/STT

Edit `~/.openjarvis/config.toml` and add these sections:

```toml
[speech]
backend = "faster-whisper"
model = "base"
device = "auto"
compute_type = "float16"

[digest]
tts_backend = "kokoro"
voice_id = "af_heart"
voice_speed = 1.0
```

**Available Kokoro voices:**
- `af_heart` (female, warm)
- `af_bella` (female, bright)
- `am_adam` (male, deep)
- `am_michael` (male, friendly)

**⚠️ CRITICAL:** The `voice_id` must NOT be empty. An empty value causes HuggingFace 404 errors.

---

### Step 10: soundfile Dependency (Automatic)

Kokoro TTS requires `soundfile` to write WAV files. **soundfile is now automatically included** in the `speech` extra:

```bash
# soundfile is installed automatically when you run uv sync --extra speech
# Verify:
.venv/Scripts/python -c "import soundfile; print('soundfile OK')"
```

**Output:** `soundfile OK`

**Note:** If using an older version without this fix, manually install:
```bash
uv pip install soundfile --python .venv/Scripts/python.exe
```

---

### Step 11: Install ffmpeg for Audio Playback

```bash
# Windows:
winget install ffmpeg

# After installation: restart your terminal so PATH updates
```

**Verify:**
```bash
ffplay -version

# Output: "ffplay version X.X-essentials_build-..."
```

---

## Step 12: Test Everything Works

### Test 1: One-shot Question

```bash
uv run jarvis ask "What is the capital of France?"
```

**Expected output:**
```
The capital of France is Paris. It is the most populous city of the country...
```

If this works, the LLM backend is operational.

---

### Test 2: Interactive Chat

```bash
uv run jarvis chat --agent react
```

Type a question and press Enter. Type `exit` to quit.

---

### Test 3: TTS (Text-to-Speech)

Generate and play the morning digest with audio:

```bash
# Generate fresh digest
uv run jarvis digest --fresh

# Play stored digest with audio (should hear spoken audio)
uv run jarvis digest
```

**Expected:**
- You should hear Kokoro's voice reading the digest
- If no audio: check ffplay is installed and your terminal was restarted after ffmpeg install

---

### Test 4: Start API Server

```bash
# Terminal 1: Start the server
uv run jarvis serve

# Expected: "Starting OpenJarvis API server" + "Uvicorn running on http://127.0.0.1:8000"
```

In another terminal, test endpoints:

```bash
# Terminal 2: Test STT health
curl http://127.0.0.1:8000/v1/speech/health

# Expected: {"backend_id": "faster-whisper", "available": true}
```

---

## Daily Operations: What Needs to Run

This section covers what must be running before you use OpenJarvis each day.

---

### Minimum Required (to use `jarvis ask` / `jarvis chat`)

Only **one thing** must be running before any LLM interaction:

#### Ollama (Inference Engine)

```bash
# Start Ollama (if not already running as a system service)
ollama serve

# Verify it's running:
ollama list
```

Expected output:
```
NAME               ID              SIZE    MODIFIED
gemma4:e4b         ...             3.3 GB  ...
```

Ollama auto-starts on most Windows installations after reboot. If `jarvis ask` hangs or returns "No inference engine available", Ollama is not running.

**Alternative engines** (if not using Ollama):

| Engine | Start command | Port |
|--------|--------------|------|
| LM Studio | Launch the app | 1234 |
| llama.cpp | `./server -m model.gguf` | 8080 |
| vLLM | `python -m vllm.entrypoints.api_server` | 8000 |
| Cloud (no local engine) | Set `OPENAI_API_KEY` or `ANTHROPIC_API_KEY` in env | — |

---

### For API / REST Access (optional)

Start the FastAPI server if you want to use REST endpoints, web UI, or external clients:

```bash
# Terminal: keep this running
uv run jarvis serve

# Starts at: http://127.0.0.1:8000
```

**Not required** for `jarvis ask`, `jarvis chat`, or `jarvis digest` — those run in-process.

---

### For Morning Digest with TTS

The digest works out of the box with no extra services, but is much more useful when connected to real data sources:

#### Currently Working (no extra setup):
- Kokoro TTS audio — local, runs automatically
- World news summary — uses DuckDuckGo search, no API key needed
- HackerNews feed — no API key needed

#### Requires Credentials (set in `~/.openjarvis/connectors/`):

| Feature | Service | Setup command |
|---------|---------|--------------|
| Email summary | Gmail | `uv run jarvis connect gmail` |
| Calendar events | Google Calendar | `uv run jarvis connect gcalendar` |
| Health data | Oura Ring | `uv run jarvis connect oura` |
| Weather | OpenWeatherMap | `uv run jarvis connect weather` |
| Task list | Google Tasks | `uv run jarvis connect google_tasks` |
| Slack messages | Slack | `uv run jarvis connect slack` |

Connectors not configured are silently skipped — the digest still works without them.

---

### For Chat Channels (Slack, Telegram, Discord, etc.)

Chat integrations run as part of `jarvis serve`. Set API keys in environment before starting:

```bash
# Example: Telegram bot
export TELEGRAM_BOT_TOKEN="your-token-here"
uv run jarvis serve

# Example: Slack bot
export SLACK_BOT_TOKEN="xoxb-..."
export SLACK_APP_TOKEN="xapp-..."
uv run jarvis serve
```

Available channels:

| Channel | Env var(s) needed |
|---------|------------------|
| Telegram | `TELEGRAM_BOT_TOKEN` |
| Slack | `SLACK_BOT_TOKEN`, `SLACK_APP_TOKEN` |
| Discord | `DISCORD_BOT_TOKEN` |
| WhatsApp (Cloud) | `WHATSAPP_ACCESS_TOKEN`, `WHATSAPP_PHONE_NUMBER_ID` |
| Teams | `TEAMS_APP_ID`, `TEAMS_APP_PASSWORD` |

---

### Environment Variables Reference

Store these in your shell profile (`~/.bashrc`, `~/.zshrc`, or Windows environment variables):

```bash
# ---- Cloud LLM providers (optional — local engine works without these) ----
OPENAI_API_KEY=sk-...          # OpenAI GPT models + Whisper STT + TTS
ANTHROPIC_API_KEY=sk-ant-...   # Claude models
GEMINI_API_KEY=...             # Google Gemini models

# ---- TTS backends (optional — Kokoro works locally without these) ----
CARTESIA_API_KEY=...           # Cartesia TTS (cloud, high quality)

# ---- Speech (optional) ----
DEEPGRAM_API_KEY=...           # Deepgram STT (cloud, faster than local Whisper)

# ---- Server auth (required only if serving on non-localhost) ----
OPENJARVIS_API_KEY=...         # API key for REST server auth

# ---- Config override (optional) ----
OPENJARVIS_CONFIG=/path/to/config.toml   # Use a non-default config file
OLLAMA_HOST=http://remote-server:11434   # Remote Ollama instance
```

---

### Daily Startup Checklist

Minimal (ask/chat only):
```
[ ] Ollama is running: ollama serve
[ ] Model is pulled: ollama list (check your model is there)
[ ] uv run jarvis ask "hello"   (test query)
```

With TTS digest:
```
[ ] Ollama is running
[ ] uv run jarvis digest --fresh   (generate)
[ ] uv run jarvis digest           (plays audio)
```

With full server + channels:
```
[ ] Ollama is running
[ ] Channel tokens set in environment
[ ] uv run jarvis serve            (starts API + channels + scheduler)
```

---

### Memory Backend (Automatic)

OpenJarvis uses **SQLite by default** — no external database needed. All data lives in:

```
~/.openjarvis/
  memory.db       # Conversation memory (SQLite + FTS5)
  agents.db       # Agent sessions
  digest.db       # Stored morning digests
  knowledge.db    # Knowledge base
  traces.db       # Execution traces (for learning loop)
```

These are auto-created on first run. No Redis, Postgres, or vector database required unless you explicitly switch to FAISS/ColBERT backends.

---

## Verification Checklist

After installation, verify each item:

- [ ] `uv run jarvis ask "hello"` responds correctly
- [ ] `uv run jarvis digest` plays audio (or at least generates text)
- [ ] `uv run jarvis serve` starts without errors
- [ ] `curl http://127.0.0.1:8000/v1/speech/health` returns 200

If all pass, you're ready to use OpenJarvis!

---

## Known Issues & Troubleshooting

### Issue: Missing `RECORD` file warning

```
warning: Failed to uninstall package at .venv\Lib\site-packages\...-xxx.dist-info due to missing RECORD file
```

**Fix:** Wipe and rebuild the venv:
```bash
rm -rf .venv
uv sync --extra dev --extra speech --extra server
uv run maturin develop -m rust/crates/openjarvis-python/Cargo.toml
```

### Issue: `openjarvis-rust` removed after `uv sync`

If `uv sync` removes the Rust extension, rebuild it:
```bash
uv run maturin develop -m rust/crates/openjarvis-python/Cargo.toml
```

### Issue: `jarvis init` hangs or aborts

`jarvis init` is interactive and cannot run in the background. Always run it in your active terminal.

### Issue: `jarvis doctor` shows Unicode error on Windows

```
UnicodeEncodeError: 'charmap' codec can't encode character '✓'
```

**Fix:** Set UTF-8 encoding:
```bash
PYTHONUTF8=1 uv run jarvis doctor
```

### Issue: `uv pip install soundfile` doesn't install to project venv

If you run `uv pip install soundfile` without the `--python` flag, it installs to Anaconda, not the project venv.

**Always use:**
```bash
uv pip install soundfile --python .venv/Scripts/python.exe
```

### Issue: TTS audio not playing

**Causes:**
1. `ffplay` not installed — run `winget install ffmpeg` and restart terminal
2. Empty `voice_id` in config causes Kokoro to fail — set `voice_id = "af_heart"`
3. `soundfile` not in project venv — reinstall with `--python` flag
4. Using `--fresh` flag on digest — this skips TTS. Use `uv run jarvis digest` (without `--fresh`) to play stored digests with audio

### Issue: `--fresh` flag doesn't generate audio

The `jarvis digest --fresh` command generates a fresh digest but **skips the TTS step**. Audio only plays from pre-stored digests.

**To get audio:**
```bash
# Option 1: Play stored digest (has audio)
uv run jarvis digest

# Option 2: Generate fresh digest, then play the stored version
uv run jarvis digest --fresh  # generates text
uv run jarvis digest          # plays stored digest with audio
```

### Issue: `uv sync` keeps removing extras

After running `uv sync`, speech/server extras disappear.

**Fix:** Always specify all extras together:
```bash
uv sync --extra dev --extra speech --extra server
uv run maturin develop -m rust/crates/openjarvis-python/Cargo.toml
```

Never do just `uv sync` alone — it resets to base dependencies.

### Issue: Port 8000 already in use

If `uv run jarvis serve` says port 8000 is occupied:

```bash
# Kill the process using port 8000 (Windows):
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Or start on a different port (edit config.toml):
[server]
port = 8001
```

---

## Testing TTS & STT

### Test STT (Speech-to-Text)

Start the server:
```bash
uv run jarvis serve
```

In another terminal, transcribe an audio file:
```bash
curl -X POST http://127.0.0.1:8000/v1/speech/transcribe \
  -F "file=@your_audio.wav"
```

Check speech backend health:
```bash
curl http://127.0.0.1:8000/v1/speech/health
```

### Test TTS (Text-to-Speech)

Generate and play the morning digest with audio:
```bash
# Generate fresh digest (text only with --fresh)
uv run jarvis digest --fresh

# Play stored digest with TTS audio
uv run jarvis digest
```

You should hear Kokoro synthesize the digest text aloud (if audio devices are working).

---

## All Available CLI Commands

```bash
# Core commands
uv run jarvis init [--force]              # Initialize or reconfigure
uv run jarvis doctor                       # Check system health
uv run jarvis ask "query"                  # One-shot question
uv run jarvis chat [--agent AGENT_NAME]   # Interactive conversation

# Agents
uv run jarvis chat --agent react           # ReAct agent (reasoning + tools)
uv run jarvis chat --agent simple          # Simple agent (direct responses)
uv run jarvis chat --agent deep_research   # Deep research agent
uv run jarvis digest [--fresh]             # Morning digest with TTS

# Server & API
uv run jarvis serve                        # Start REST API server (localhost:8000)

# Skills & Tools
uv run jarvis skill list                   # List installed skills
uv run jarvis skill install SOURCE:SKILL   # Install a skill

# Development
uv run pytest tests/ -v                    # Run full test suite
uv run pytest tests/ -m live -v            # Run tests requiring inference
uv run pytest tests/ --cov=openjarvis      # With coverage report
uv run ruff check src/ tests/              # Linting
uv run ruff format src/ tests/             # Code formatting
uv run pre-commit run --all-files          # All pre-commit checks
```

---

## Project Structure

```
openjarvis/
├── src/openjarvis/
│   ├── sdk.py                  # High-level SDK entry point
│   ├── intelligence/           # Model catalog & routing
│   ├── engine/                 # Inference backends (Ollama, vLLM, etc.)
│   ├── agents/                 # Agent implementations (morning_digest, etc.)
│   ├── tools/                  # 200+ tools (TTS, STT, browser, etc.)
│   ├── speech/                 # TTS/STT backends
│   ├── channels/               # Chat integrations (Slack, Discord, etc.)
│   └── cli/                    # CLI commands
├── rust/crates/               # PyO3 Rust extensions
├── frontend/                  # React + Tauri desktop app
└── pyproject.toml             # Project dependencies
```

---

## Configuration Reference

Full config template (`~/.openjarvis/config.toml`):

```toml
# OpenJarvis configuration

[engine]
default = "ollama"

[engine.ollama]
# host = "http://localhost:11434"  # set to remote URL if engine runs elsewhere

[intelligence]
default_model = "gemma4:e4b"

[agent]
default_agent = "simple"

[tools]
enabled = ["code_interpreter", "web_search", "file_read", "shell_exec"]

[speech]
backend = "faster-whisper"
model = "base"
device = "auto"
compute_type = "float16"

[digest]
enabled = false
schedule = "0 6 * * *"           # 6 AM daily
timezone = "America/Los_Angeles"
persona = "jarvis"
honorific = "sir"
tts_backend = "kokoro"
voice_id = "af_heart"
voice_speed = 1.0
```

---

## Architecture Overview

OpenJarvis is a **local-first AI agent framework** organized as a Python/Rust/TypeScript monorepo:

### Python Backend (`src/openjarvis/`)

**Core Modules:**
- `sdk.py` — High-level `Jarvis` SDK (main entry point)
- `system.py` — `JarvisSystem` wires full system from config
- `core/` — Config, event bus, registries, shared types
- `intelligence/` — Model catalog and routing (Ollama, vLLM, MLX, etc.)
- `agents/` — Agent implementations (ReAct, morning_digest, deep_research, etc.)
- `tools/` — 200+ tools (browser, code execution, TTS, STT, git, files, etc.)
- `speech/` — TTS/STT backends (Kokoro, Faster-Whisper, OpenAI, Deepgram, Cartesia)
- `channels/` — Chat integrations (Slack, Discord, Telegram, Gmail, etc.)
- `memory/` — Storage backends (FAISS, BM25, ColBERT, SQLite)
- `learning/` — Optimization using local trace data (GEPA)
- `cli/` — 25+ Click commands
- `server/` — FastAPI REST server

**Design Patterns:**
- **Registry pattern** — All extensible components self-register (engines, tools, agents, etc.)
- **Event bus** — Pub/sub for lifecycle events
- **Config-driven** — Compose system from TOML/YAML config
- **Trace-first** — All calls auto-instrumented for learning loop

### Rust Extensions (`rust/crates/`)

Performance-critical internals via PyO3:
- Core, engine, agents, tools, learning, telemetry, sessions, etc.
- Built with maturin (requires rebuild after changes)

### Frontend (`frontend/`)

React 19 + Vite 6 + Tauri 2
- Zustand for state management
- shadcn/ui + Tailwind for UI
- Local IPC bridge to Python backend

---

## Extending OpenJarvis

### Add a New Tool

```python
# src/openjarvis/tools/my_tool.py
from openjarvis.core.registry import ToolRegistry
from openjarvis.tools._stubs import BaseTool, ToolSpec

@ToolRegistry.register("my_tool")
class MyTool(BaseTool):
    tool_id = "my_tool"
    
    @property
    def spec(self) -> ToolSpec:
        return ToolSpec(
            name="my_tool",
            description="What this tool does",
            parameters={
                "type": "object",
                "properties": {
                    "input": {"type": "string", "description": "Input description"}
                },
                "required": ["input"],
            },
        )
    
    def execute(self, **params):
        result = do_something(params["input"])
        return ToolResult(success=True, content=result)
```

Tools are auto-discovered and available to all agents via the registry pattern.

### Add a New Agent

```python
# src/openjarvis/agents/my_agent.py
from openjarvis.agents._stubs import AgentRegistry, ToolUsingAgent

@AgentRegistry.register("my_agent")
class MyAgent(ToolUsingAgent):
    agent_id = "my_agent"
    
    def _build_system_prompt(self) -> str:
        return "You are a helpful assistant that..."
```

Register agents and they're available to all clients via `uv run jarvis chat --agent my_agent`.

### Add a New Inference Engine

```python
# src/openjarvis/engine/my_engine.py
from openjarvis.core.registry import EngineRegistry
from openjarvis.engine._stubs import BaseEngine

@EngineRegistry.register("my_engine")
class MyEngine(BaseEngine):
    engine_id = "my_engine"
    
    def __call__(self, messages, **kwargs):
        # Implement inference logic
        return response
```

Engines are routed based on config. Full docs in `CLAUDE.md`.

---

## Recommended Next Steps

1. ✅ **Complete Setup:** Follow Steps 1-12 above
2. **Run Your First Query:** `uv run jarvis ask "Tell me about yourself"`
3. **Test Agents:** `uv run jarvis chat --agent react` (with tools/reasoning)
4. **Explore Digest:** `uv run jarvis digest --fresh` then `uv run jarvis digest` (with TTS)
5. **Start the Server:** `uv run jarvis serve` and test REST endpoints
6. **Build Custom Tools:** Add your own tools via the registry pattern
7. **Read CLAUDE.md:** Full architecture and development guide in this repo

---

## Useful Links

- **GitHub**: [openjarvis](https://github.com/your-org/openjarvis)
- **Docs**: [OpenJarvis Documentation](https://docs.openjarvis.ai)
- **Ollama Models**: [ollama.com/library](https://ollama.com/library)
- **Kokoro Voices**: [hexgrad/Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M)
- **Faster-Whisper**: [openai/whisper](https://github.com/openai/whisper)

---

**Last Updated:** 2026-04-21  
**Tested On:** Windows 11, Python 3.12, NVIDIA GTX 1050 Ti (4GB VRAM)
