#!/usr/bin/env python3
"""TTS audition: render the same sample script in several free voices.

Roadmap: "Generate the same 30-second script in each, listen with headphones,
pick the one you'd actually want to listen to for 12 weeks."

Usage:
    pip install edge-tts          # free, no signup; ffmpeg must be in PATH
    python3 tool/audition_tts.py                 # default voices
    python3 tool/audition_tts.py --voices en-IN-PrabhatNeural en-GB-RyanNeural
    python3 tool/audition_tts.py --self-test     # parser checks, no network

Output: tool/auditions/<voice>.m4a (96 kbps AAC — the app's shipping format).

Not covered here (audition in the browser instead):
  * Kokoro TTS — https://huggingface.co/spaces/hexgrad/Kokoro-TTS
  * Your own voice — phone mic in a closet, Audacity cleanup.
"""

import argparse
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

DEFAULT_VOICES = [
    "en-IN-PrabhatNeural",   # Indian-English male — roadmap's named candidate
    "en-IN-NeerjaNeural",    # Indian-English female
    "en-US-ChristopherNeural",  # neutral calm male, for contrast
]

PAUSE_RE = re.compile(r"\[pause\s+(\d+(?:\.\d+)?)s\]", re.IGNORECASE)


def parse_script(text):
    """Split a script with [pause Xs] markers into segments.

    Returns a list of ("text", str) and ("pause", float) tuples, in order,
    with empty text chunks dropped.
    """
    segments = []
    pos = 0
    for m in PAUSE_RE.finditer(text):
        chunk = text[pos:m.start()].strip()
        if chunk:
            segments.append(("text", chunk))
        segments.append(("pause", float(m.group(1))))
        pos = m.end()
    tail = text[pos:].strip()
    if tail:
        segments.append(("text", tail))
    return segments


def self_test():
    s = parse_script("Hello.\n[pause 2s]\nWorld.\n[pause 1.5s]")
    assert s == [
        ("text", "Hello."),
        ("pause", 2.0),
        ("text", "World."),
        ("pause", 1.5),
    ], s
    assert parse_script("No pauses here.") == [("text", "No pauses here.")]
    assert parse_script("[pause 3s] leading") == [
        ("pause", 3.0),
        ("text", "leading"),
    ]
    assert parse_script("") == []
    print("self-test OK")


def run(cmd, **kwargs):
    proc = subprocess.run(cmd, capture_output=True, text=True, **kwargs)
    if proc.returncode != 0:
        sys.exit(f"command failed: {' '.join(cmd)}\n{proc.stderr.strip()}")
    return proc


def render_voice(voice, segments, out_dir, tmp):
    """Render one voice: TTS per text segment, silence per pause, concat → m4a."""
    wavs = []
    for i, (kind, value) in enumerate(segments):
        wav = tmp / f"{voice}_{i:02d}.wav"
        if kind == "text":
            mp3 = tmp / f"{voice}_{i:02d}.mp3"
            run([
                "edge-tts", "--voice", voice,
                "--rate=-15%",  # guided sessions read slow ("=" so argparse doesn't eat the leading dash)
                "--text", value, "--write-media", str(mp3),
            ])
            run(["ffmpeg", "-y", "-i", str(mp3),
                 "-ar", "24000", "-ac", "1", str(wav)])
        else:
            run(["ffmpeg", "-y", "-f", "lavfi",
                 "-i", "anullsrc=r=24000:cl=mono",
                 "-t", str(value), str(wav)])
        wavs.append(wav)

    concat_list = tmp / f"{voice}_list.txt"
    concat_list.write_text(
        "".join(f"file '{w.name}'\n" for w in wavs), encoding="utf-8"
    )
    # Absolute: this ffmpeg runs with cwd=tmp (concat list uses bare filenames).
    out = (out_dir / f"{voice}.m4a").resolve()
    run(["ffmpeg", "-y", "-f", "concat", "-safe", "0",
         "-i", str(concat_list), "-c:a", "aac", "-b:a", "96k", str(out)],
        cwd=tmp)
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--script", default="tool/audition_script.txt")
    ap.add_argument("--voices", nargs="+", default=DEFAULT_VOICES)
    ap.add_argument("--out", default="tool/auditions")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        self_test()
        return

    for tool_name in ("edge-tts", "ffmpeg"):
        if shutil.which(tool_name) is None:
            sys.exit(
                f"'{tool_name}' not found. Install: pip install edge-tts; "
                "ffmpeg via 'brew install ffmpeg'."
            )

    script_path = Path(args.script)
    segments = parse_script(script_path.read_text(encoding="utf-8"))
    if not any(kind == "text" for kind, _ in segments):
        sys.exit(f"no speakable text found in {script_path}")

    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory() as tmp_str:
        tmp = Path(tmp_str)
        for voice in args.voices:
            print(f"rendering {voice} …")
            out = render_voice(voice, segments, out_dir, tmp)
            print(f"  -> {out}")

    print(
        "\nDone. Listen with headphones, back to back."
        "\nAlso audition in the browser:"
        "\n  Kokoro: https://huggingface.co/spaces/hexgrad/Kokoro-TTS"
        "\nPick the voice you'd want in your ear for 12 weeks."
    )


if __name__ == "__main__":
    main()
