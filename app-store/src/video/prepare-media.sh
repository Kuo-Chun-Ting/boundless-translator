#!/bin/sh
# Transcode the screen recordings into constant-30-fps, silent H.264 proxies
# so Remotion seeks frame-accurately. The originals are read-only here.
set -eu

cd "$(dirname "$0")"
mkdir -p public/media

proxy() {
  src=$1
  out="public/media/$2.mp4"
  if [ -f "$out" ] && [ "$out" -nt "$src" ]; then
    echo "skip $out"
    return
  fi
  ffmpeg -v error -y -i "$src" \
    -an -vf "fps=30" -c:v libx264 -preset medium -crf 14 -g 15 \
    -pix_fmt yuv420p -movflags +faststart "$out"
  echo "wrote $out"
}

recording=../../assets/recording
proxy "$recording/selected-text-translation.mov" preview-selected
proxy "$recording/screenshot-translation.mov" menu-screenshot
