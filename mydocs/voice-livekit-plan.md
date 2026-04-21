# Plan: Voice Interaction Modes for OpenJarvis + LiveKit Integration

## What Already Exists

| Component | Status |
|---|---|
| STT backends | faster-whisper (local), OpenAI Whisper, Deepgram |
| TTS backends | Kokoro (local), Cartesia, OpenAI TTS |
| REST endpoints | POST /v1/speech/transcribe, POST /v1/speech/tts, GET /v1/speech/health |
| Web UI mic button | Working — record → transcribe → chat → auto-play TTS |
| WebSocket /v1/chat/stream | Text streaming only — no audio |
| LiveKit | Does not exist anywhere in the codebase |

---

## 5 Ways to Use Voice with OpenJarvis

### Way 1 — Web UI Mic Button (Already Working)
Record → transcribe → chat → auto-play TTS. Not real-time, requires button clicks.

### Way 2 — CLI `jarvis listen` (Small effort)
sounddevice chunks → POST /v1/speech/transcribe → print text in terminal.

### Way 3 — REST API Batch (Already Working)
Three HTTP calls: transcribe audio → chat → synthesize response. Good for scripts/mobile.

### Way 4 — WebSocket Streaming STT (Medium effort)
`WS /v1/speech/stream` — stream raw PCM chunks, get back partial transcription events.

### Way 5 — LiveKit Voice Agent (Main Goal — Full Duplex)
Speak naturally → voice response back. True hands-free conversation. See full detail below.

---

## Can I Use OpenJarvis Agents with Voice?

**Yes — this is the key integration point.**

The LiveKit agent's LLM step is replaced with a call to the full OpenJarvis agent system.
Instead of just sending user text to the inference engine, it runs a ReAct agent with all 200+ tools:

```
User speaks
    ↓ STT (faster-whisper)
    ↓ text
OpenJarvis ReAct Agent
    ├── search the web
    ├── check Google Calendar
    ├── read files / GitHub
    ├── run code
    ├── query memory / RAG
    └── ... all 200+ tools
    ↓ final text response
    ↓ TTS (Kokoro)
User hears the response
```

You can say "what's on my calendar today?" and the voice agent will:
1. Transcribe your speech
2. Run the ReAct agent → calls gcalendar tool → fetches your events
3. Synthesize "You have 3 meetings today: standup at 9am..." and speak it back

---

## Way 5 — LiveKit: Exact Code Changes

### 1. `pyproject.toml`
Add new `livekit` extra (no changes to existing extras):
```toml
livekit = [
  "livekit-agents>=0.8",
  "livekit-plugins-silero",       # VAD
  "livekit-plugins-deepgram",     # cloud STT option
  "livekit-plugins-cartesia",     # cloud TTS option
]
```

### 2. `src/openjarvis/channels/livekit_agent.py` (new file)
Core agent class that wires LiveKit to OpenJarvis:

```python
from livekit.agents import VoicePipelineAgent, JobContext
from livekit.plugins import silero, deepgram, cartesia

class OpenJarvisLiveKitAgent:
    """Voice agent: LiveKit audio → OpenJarvis agents → LiveKit audio."""

    async def entrypoint(self, ctx: JobContext):
        await ctx.connect()

        # Load existing OpenJarvis engine from config
        config = load_config()
        engine = create_engine(config)          # existing engine (Ollama/Claude/etc.)
        agent_runner = ReactAgent(engine, ...)  # existing ReAct agent with tools

        # Wire the pipeline
        pipeline = VoicePipelineAgent(
            vad=silero.VAD.load(),              # detect end of speech
            stt=self._get_stt(config),          # faster-whisper or Deepgram
            llm=OpenJarvisLLMAdapter(agent_runner),  # ← OpenJarvis agents HERE
            tts=self._get_tts(config),          # Kokoro or Cartesia
        )
        pipeline.start(ctx.room)

    def _get_stt(self, config):
        # Uses faster-whisper locally, or Deepgram if api key present
        ...

    def _get_tts(self, config):
        # Uses Kokoro locally, or Cartesia if api key present
        ...


class OpenJarvisLLMAdapter:
    """Adapts the OpenJarvis agent/engine to the LiveKit LLM interface."""

    def __init__(self, agent_runner):
        self.agent = agent_runner

    async def chat(self, messages) -> AsyncIterable[str]:
        # LiveKit calls this with the transcribed text
        # We run the full OpenJarvis ReAct agent and stream tokens back
        user_text = messages[-1].content
        async for chunk in self.agent.stream(user_text):
            yield chunk
```

### 3. `src/openjarvis/cli/__init__.py`
Add `jarvis livekit` command (3 lines):
```python
from openjarvis.channels.livekit_agent import livekit_cmd
cli.add_command(livekit_cmd)
```

### 4. `~/.openjarvis/config.toml` (user adds this section)
```toml
[livekit]
url = "wss://your-project.livekit.cloud"
api_key = "your-api-key"
api_secret = "your-api-secret"
room = "jarvis-voice"
agent = "react"     # which OpenJarvis agent to use: react, orchestrator, etc.
```

---

## How to Run It (After Implementation)

**Terminal 1:**
```bash
jarvis livekit       # agent joins the LiveKit room and waits
```

**Browser (or phone):**
- Open a LiveKit web client pointed at the same room
- Or use the Livekit Playground at https://agents-playground.livekit.io
- Speak → OpenJarvis responds with voice

---

## Comparison Table

| Method | Latency | Real-time | Hands-free | Uses Agents | Effort |
|---|---|---|---|---|---|
| Way 1 — Web UI mic | ~2-4s | No | No | Yes (manual) | Done |
| Way 2 — `jarvis listen` CLI | ~3s/chunk | Chunked | No | No | Small |
| Way 3 — REST API | ~3-5s | No | No | No | Done |
| Way 4 — WS Streaming STT | <1s | Yes | No | No | Medium |
| Way 5 — LiveKit Agent | <500ms | Yes | Yes | **Yes (automatic)** | Large |

---

## Recommended Build Order

1. **Way 2 — `jarvis listen` CLI** — quick win, no server changes needed
2. **Way 5 — LiveKit Agent** — full duplex voice + agents, the main goal

---

## Prerequisites Before Building Way 5

1. Free LiveKit account at https://livekit.io → get URL, API key, API secret
2. Add `[livekit]` section to `~/.openjarvis/config.toml`
3. `uv sync --extra livekit` after pyproject.toml is updated
