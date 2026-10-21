#!/bin/sh
# Usage: ./render-previews.sh filename.mp4 [shoo|woo] [--encode-only]
set -eu
cd "$(dirname "$0")"
name=${1:?usage: render-previews.sh filename.mp4 [shoo|woo] [--encode-only]}
sound=${2:-shoo}
mode=${3:-}
case "$name" in
  */*|.*) echo 'Use an MP4 filename without a directory.' >&2; exit 1 ;;
  *.mp4) ;;
  *) echo 'Output filename must end with .mp4.' >&2; exit 1 ;;
esac
case "$sound" in
  shoo) id=PreviewShoo ;;
  woo) id=PreviewWoo ;;
  *) echo 'Sound must be shoo or woo.' >&2; exit 1 ;;
esac
case "$mode" in
  ''|--encode-only) ;;
  *) echo 'Unknown option.' >&2; exit 1 ;;
esac
dest=../../video
output="$dest/$name"
if [ -e "$output" ]; then
  echo "Refusing to overwrite: $output" >&2
  exit 1
fi
mkdir -p out "$dest"
master="out/${name%.mp4}-master.mov"
if [ "$mode" != '--encode-only' ]; then
  npx remotion render "$id" "$master" --codec=h264 --crf=10 \
    --audio-codec=pcm-16 --concurrency=2
fi
ffmpeg -v error -n -i "$master" \
  -c:v libx264 -preset slow -profile:v high -level:v 4.0 -pix_fmt yuv420p \
  -r 30 -b:v 11M -minrate 11M -maxrate 11M -bufsize 22M -x264-params nal-hrd=cbr \
  -c:a aac -b:a 256k -ar 48000 -ac 2 \
  -movflags +faststart "$output"
echo "wrote $output"
