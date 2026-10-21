#!/bin/sh
# Real recorded key, click and shutter sounds, from sfx-source/ (CC0, see
# licenses/README.md). Each sound is trimmed so it starts at its onset and
# peaks at -1 dBFS. Output: public/sfx/ui/*.wav
set -eu

cd "$(dirname "$0")"
mkdir -p public/sfx/ui

peak() {
  ffmpeg -i "$1" -af volumedetect -f null - 2>&1 | awk '/max_volume/ {print $5}'
}

# Trim to the onset and convert to 48 kHz stereo first (upmixing a mono file
# lowers its level), then set the peak.
clean() {
  out="public/sfx/ui/$2.wav"
  tmp="public/sfx/ui/.$2.wav"
  ffmpeg -v error -y -i "sfx-source/$1" -af "silenceremove=start_periods=1:start_threshold=-45dB" \
    -ar 48000 -ac 2 -c:a pcm_s16le "$tmp"
  gain=$(awk -v p="$(peak "$tmp")" 'BEGIN {print -1 - p}')
  ffmpeg -v error -y -i "$tmp" -af "volume=${gain}dB" -c:a pcm_s16le "$out"
  rm "$tmp"
  echo "wrote $out"
}

clean pixeliota-mouse-click.wav click
clean unicae-keypress-004.wav key-1
clean unicae-keypress-006.wav key-2
clean unicae-keypress-001.wav key-3
clean ristooooo1-dslr-shutter.wav shutter-cc0

