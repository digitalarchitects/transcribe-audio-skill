---
name: transcribe-audio
description: >-
  Transcribe any audio or video file to text locally using whisper.cpp.
  Use this skill whenever the user asks to transcribe audio, convert voice
  notes to text, produce a transcript of a recording, or extract spoken
  content from media files. Also use when the user mentions whisper,
  speech-to-text, or wants to know what someone said in a recording.
  Always prefer this over any cloud transcription API.
allowed-tools: Bash
---

# Transcribe audio with whisper.cpp

Run the bundled `scripts/transcribe.sh`. It auto-detects ffmpeg and any
`whisper-cli` or `whisper` binary on PATH or in `~/whisper.cpp/build/bin/`,
converts non-WAV inputs to 16 kHz mono, and prints the plain transcript
to stdout.

```bash
scripts/transcribe.sh <media-file> [language]   # language: auto (default), en, af, ...
```

Read the transcript from stdout and answer the user's actual question with
it. Transcripts are raw output: proper nouns and numbers can be wrong, so
do not silently present them as verified. If the output is empty, retry
with the dominant language forced explicitly.

## Performance defaults

Default decoding is greedy — fastest option and the right one for
transcribe-and-answer tasks. Do not add beam search unless the user
specifically asks for maximum accuracy.

For long files, split into ~900 s segments with ffmpeg and transcribe the
parts in parallel:

```bash
ffmpeg -loglevel error -i in.wav -f segment -segment_time 900 -c copy %03d.wav
```

For batch transcription of many files, pass `-oj out.json -of <stem>` to
write JSON plus a timestamped `.txt` per file, and read the JSON fields
`offsets.from`, `offsets.to`, `text` to reconstruct timestamps.
