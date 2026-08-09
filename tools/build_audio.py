#!/usr/bin/env python3
"""Generate the original, compact music and sound set used by the game.

The synthesizer is deterministic and uses only Python's standard library.
FFmpeg converts the looping music to small Ogg Vorbis files; short effects stay
as WAV so attacks and UI feedback start immediately on mobile browsers.
"""

from array import array
import math
from pathlib import Path
import random
import shutil
import struct
import subprocess
import tempfile
import wave


ROOT = Path(__file__).resolve().parents[1]
MUSIC_DIR = ROOT / "assets/audio/music"
SFX_DIR = ROOT / "assets/audio/sfx"
SAMPLE_RATE = 22_050


def midi(note: int) -> float:
    return 440.0 * 2.0 ** ((note - 69) / 12.0)


def envelope(position: float, duration: float, attack: float, release: float) -> float:
    return min(1.0, position / max(attack, 0.001), (duration - position) / max(release, 0.001))


def add_note(buf: array, start: float, duration: float, note: int, volume: float, voice: str) -> None:
    begin = max(0, int(start * SAMPLE_RATE))
    end = min(len(buf), int((start + duration) * SAMPLE_RATE))
    frequency = midi(note)
    for index in range(begin, end):
        t = (index - begin) / SAMPLE_RATE
        phase = math.tau * frequency * t
        if voice == "pluck":
            env = math.exp(-4.2 * t / max(duration, 0.05)) * envelope(t, duration, 0.008, 0.08)
            value = math.sin(phase) + 0.42 * math.sin(phase * 2.0) + 0.18 * math.sin(phase * 3.0)
        elif voice == "bell":
            env = math.exp(-3.1 * t / max(duration, 0.05)) * envelope(t, duration, 0.004, 0.12)
            value = math.sin(phase) + 0.34 * math.sin(phase * 2.01) + 0.22 * math.sin(phase * 3.98)
        elif voice == "flute":
            env = envelope(t, duration, 0.09, 0.18)
            vibrato = 1.0 + math.sin(math.tau * 5.1 * t) * 0.003
            value = math.sin(phase * vibrato) + 0.16 * math.sin(phase * 2.0)
        elif voice == "bass":
            env = envelope(t, duration, 0.025, 0.14)
            value = math.sin(phase) + 0.28 * math.sin(phase * 0.5)
        else:  # warm pad
            env = envelope(t, duration, 0.45, 0.65)
            value = math.sin(phase) + 0.30 * math.sin(phase * 0.5) + 0.12 * math.sin(phase * 2.0)
        buf[index] += value * env * volume


def add_kick(buf: array, start: float, volume: float = 0.25) -> None:
    begin = int(start * SAMPLE_RATE)
    length = int(0.22 * SAMPLE_RATE)
    for offset in range(length):
        index = begin + offset
        if index >= len(buf):
            break
        t = offset / SAMPLE_RATE
        frequency = 92.0 - 58.0 * min(1.0, t / 0.18)
        buf[index] += math.sin(math.tau * frequency * t) * math.exp(-18.0 * t) * volume


def add_hat(buf: array, start: float, rng: random.Random, volume: float = 0.055) -> None:
    begin = int(start * SAMPLE_RATE)
    length = int(0.075 * SAMPLE_RATE)
    previous = 0.0
    for offset in range(length):
        index = begin + offset
        if index >= len(buf):
            break
        noise = rng.uniform(-1.0, 1.0)
        bright = noise - previous * 0.82
        previous = noise
        buf[index] += bright * math.exp(-48.0 * offset / SAMPLE_RATE) * volume


def finish_audio(buf: array, fade_seconds: float = 0.12) -> array:
    peak = max(0.001, max(abs(value) for value in buf))
    gain = 0.88 / peak
    fade = min(len(buf) // 2, int(fade_seconds * SAMPLE_RATE))
    pcm = array("h")
    for index, value in enumerate(buf):
        edge = 1.0
        if index < fade:
            edge = index / max(1, fade)
        elif index >= len(buf) - fade:
            edge = (len(buf) - 1 - index) / max(1, fade)
        pcm.append(int(max(-1.0, min(1.0, value * gain * edge)) * 32767))
    return pcm


def write_wav(path: Path, pcm: array) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as target:
        target.setnchannels(1)
        target.setsampwidth(2)
        target.setframerate(SAMPLE_RATE)
        target.writeframes(pcm.tobytes())


def build_music(name: str, bpm: int, chords: list[list[int]], melody: list[int], style: str) -> None:
    beat = 60.0 / bpm
    bars = len(chords)
    duration = bars * 4 * beat
    buf = array("f", [0.0]) * int(duration * SAMPLE_RATE)
    rng = random.Random(f"sihai-{name}")
    melody_voice = {"harbor": "pluck", "wilds": "flute", "dungeon": "bell", "corsair": "bell", "battle": "pluck"}[style]

    for bar, chord in enumerate(chords):
        bar_start = bar * 4 * beat
        pad_volume = 0.065 if style in {"battle", "corsair"} else 0.085
        for chord_note in chord:
            add_note(buf, bar_start, 4 * beat, chord_note, pad_volume, "pad")
        for beat_index in range(4):
            bass_note = chord[0] - 12
            add_note(buf, bar_start + beat_index * beat, beat * 0.82, bass_note, 0.105, "bass")
            if style in {"battle", "corsair"}:
                add_kick(buf, bar_start + beat_index * beat, 0.22 if style == "battle" else 0.16)
            elif style == "harbor" and beat_index in {0, 2}:
                add_kick(buf, bar_start + beat_index * beat, 0.07)
            if style in {"battle", "corsair"}:
                add_hat(buf, bar_start + (beat_index + 0.5) * beat, rng, 0.07)

    step = beat * (0.5 if style in {"battle", "corsair"} else 1.0)
    for index in range(int(duration / step)):
        note = melody[index % len(melody)]
        if note >= 0:
            length = step * (0.72 if style in {"battle", "corsair"} else 0.86)
            volume = 0.12 if style == "dungeon" else 0.15
            add_note(buf, index * step, length, note, volume, melody_voice)

    # A nearly inaudible slow tide prevents the quieter exploration tracks from
    # feeling digitally empty without requiring a large recorded ambience file.
    if style in {"harbor", "wilds"}:
        for index in range(len(buf)):
            t = index / SAMPLE_RATE
            tide = math.sin(math.tau * 0.11 * t) * math.sin(math.tau * 0.037 * t)
            buf[index] += tide * 0.012

    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        raise RuntimeError("FFmpeg is required to encode compact music loops")
    MUSIC_DIR.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="sihai-audio-") as temp_dir:
        wav_path = Path(temp_dir) / f"{name}.wav"
        write_wav(wav_path, finish_audio(buf, 0.10))
        subprocess.run([
            ffmpeg, "-y", "-loglevel", "error", "-i", str(wav_path),
            "-c:a", "vorbis", "-strict", "-2", "-q:a", "2", "-ar", str(SAMPLE_RATE), "-ac", "2",
            str(MUSIC_DIR / f"{name}.ogg"),
        ], check=True)


def tone_sfx(name: str, duration: float, notes: list[tuple[float, int, float, str]], noise: float = 0.0) -> None:
    buf = array("f", [0.0]) * int(duration * SAMPLE_RATE)
    rng = random.Random(f"sihai-sfx-{name}")
    for start, note, length, voice in notes:
        add_note(buf, start, length, note, 0.34, voice)
    if noise > 0.0:
        previous = 0.0
        for index in range(len(buf)):
            t = index / SAMPLE_RATE
            raw = rng.uniform(-1.0, 1.0)
            bright = raw - previous * 0.72
            previous = raw
            buf[index] += bright * math.exp(-5.0 * t / max(duration, 0.05)) * noise
    write_wav(SFX_DIR / f"{name}.wav", finish_audio(buf, 0.008))


def main() -> None:
    tracks = [
        ("harbor", 75, [[50, 57, 62], [53, 57, 60], [48, 55, 60], [55, 59, 62]] * 2, [62, 64, 65, 69, 67, 65, 64, -1], "harbor"),
        ("wilds", 68, [[45, 52, 57], [48, 52, 55], [43, 50, 55], [45, 52, 57]] * 2, [69, -1, 72, 74, 76, 74, 72, 67], "wilds"),
        ("dungeon", 56, [[38, 45, 50], [41, 45, 48], [36, 43, 48], [38, 45, 50]] * 2, [62, -1, -1, 65, -1, 63, -1, -1], "dungeon"),
        ("corsair", 82, [[40, 47, 52], [41, 48, 53], [38, 45, 50], [40, 47, 52]] * 2, [64, 65, 67, 65, 64, 62, 61, -1], "corsair"),
        ("battle", 112, [[38, 45, 50], [38, 46, 50], [41, 48, 53], [36, 43, 48]] * 2, [62, 62, 65, 64, 62, 69, 67, 65], "battle"),
    ]
    for track in tracks:
        build_music(*track)

    tone_sfx("ui", 0.10, [(0.0, 76, 0.08, "pluck")])
    tone_sfx("interact", 0.34, [(0.0, 69, 0.18, "bell"), (0.12, 76, 0.20, "bell")])
    tone_sfx("step", 0.09, [(0.0, 38, 0.07, "bass")], 0.035)
    tone_sfx("battle_start", 0.58, [(0.0, 45, 0.45, "bass"), (0.20, 57, 0.32, "bell")], 0.08)
    tone_sfx("attack", 0.28, [(0.06, 62, 0.16, "pluck")], 0.16)
    tone_sfx("hit", 0.22, [(0.0, 34, 0.18, "bass")], 0.13)
    tone_sfx("skill", 0.78, [(0.0, 62, 0.22, "bell"), (0.16, 67, 0.25, "bell"), (0.34, 74, 0.38, "bell")], 0.05)
    tone_sfx("victory", 1.12, [(0.0, 62, 0.34, "bell"), (0.20, 66, 0.34, "bell"), (0.40, 69, 0.60, "bell")])
    tone_sfx("defeat", 1.05, [(0.0, 57, 0.34, "bell"), (0.24, 53, 0.34, "bell"), (0.48, 50, 0.52, "bass")])
    tone_sfx("reward", 0.92, [(0.0, 74, 0.28, "bell"), (0.14, 78, 0.32, "bell"), (0.30, 81, 0.52, "bell")])
    tone_sfx("heal", 0.66, [(0.0, 69, 0.28, "flute"), (0.18, 74, 0.42, "bell")])
    tone_sfx("sail", 1.35, [(0.0, 45, 1.15, "flute"), (0.22, 52, 0.92, "flute")], 0.045)
    print(f"Generated {len(tracks)} music loops and 12 sound effects")


if __name__ == "__main__":
    main()
