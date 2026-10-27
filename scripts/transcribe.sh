#!/usr/bin/env bash
# transcribe.sh <media-file> [language]
# Prints a plain transcript of any audio/video file to stdout.
set -euo pipefail

media=${1:?usage: transcribe.sh <media-file> [language]}
lang=${2:-auto}

[ -f "$media" ] || { echo "no such file: $media" >&2; exit 1; }

# Locate a whisper binary: PATH first, then the common build location.
whisper=$(command -v whisper-cli || command -v whisper || true)
[ -n "$whisper" ] || whisper="$HOME/whisper.cpp/build/bin/whisper-cli"
[ -x "$whisper" ] || { echo "whisper-cli not found; install whisper.cpp" >&2; exit 127; }

# Model: explicit override, then common local names, then download.
model=${WHISPER_MODEL:-}
if [ -z "$model" ]; then
  for cand in \
    "$HOME/models/ggml-base.en.bin" \
    "$HOME/models/ggml-small.en.bin" \
    "$HOME/models/ggml-medium.en.bin" \
    "$HOME/whisper.cpp/models/ggml-base.en.bin"; do
    [ -f "$cand" ] && model=$cand && break
  done
fi
if [ -z "$model" ]; then
  mkdir -p "$HOME/models"
  model="$HOME/models/ggml-base.en.bin"
  curl -L --fail -o "$model" \
    https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin
fi

audio=$media
if [[ ! "$media" =~ \.wav$ ]]; then
  ffmpeg=$(command -v ffmpeg || true)
  [ -n "$ffmpeg" ] || { echo "ffmpeg not found and input is not WAV" >&2; exit 127; }
  audio=$(mktemp --suffix=.wav)
  trap 'rm -f "$audio"' EXIT
  ffmpeg -loglevel error -y -i "$media" -ar 16000 -ac 1 "$audio"
fi

"$whisper" -m "$model" -l "$lang" -t 8 -no-timestamps -pp -f "$audio" 2>/dev/null \
  | grep -v '^>> '
