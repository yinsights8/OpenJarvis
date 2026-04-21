"""
This listen_cmd.py listens to the audio from the user and 
"""

import io

import click
import httpx
import numpy as np
import sounddevice as sd
import soundfile as sf

SAMPLE_RATE = 16000
CHANNELS = 1
CHUNK_SECONDS = 3


@click.command("listen")
@click.option(
    "--host",
    default="http://localhost:8000",
    show_default=True,
    help="OpenJarvis server URL",
)
@click.option("--language", default=None, help="Language hint (e.g. 'en')")
@click.option(
    "--chunk",
    default=CHUNK_SECONDS,
    show_default=True,
    help="Seconds of audio per transcription chunk",
)
def listen(host: str, language: str | None, chunk: int) -> None:
    """Record from microphone and transcribe speech in real time."""
    click.secho("Listening... (Ctrl+C to stop)", fg="cyan")
    frames_per_chunk = int(SAMPLE_RATE * chunk)

    try:
        with sd.InputStream(
            samplerate=SAMPLE_RATE, channels=CHANNELS, dtype="float32"
        ) as stream:
            while True:
                audio, _ = stream.read(frames_per_chunk)
                wav_bytes = _to_wav_bytes(audio)
                text = _transcribe(host, wav_bytes, language)
                if text.strip():
                    click.echo(text)
    except KeyboardInterrupt:
        pass


def _to_wav_bytes(audio: np.ndarray) -> bytes:
    """Convert the audio ot the ndarray"""
    buf = io.BytesIO()
    sf.write(buf, audio, SAMPLE_RATE, format="WAV", subtype="PCM_16")
    buf.seek(0)
    return buf.read()


def _transcribe(host: str, wav_bytes: bytes, language: str | None) -> str:
    files = {"file": ("chunk.wav", wav_bytes, "audio/wav")}
    data = {"language": language} if language else {}
    try:
        resp = httpx.post(
            f"{host}/v1/speech/transcribe",
            files=files,
            data=data,
            timeout=10,
        )
        resp.raise_for_status()
        return resp.json().get("text", "")
    except httpx.HTTPError as e:
        click.secho(f"[warn] transcribe error: {e}", fg="yellow")
        return ""
