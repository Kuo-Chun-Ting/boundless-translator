#!/bin/sh
# Convert the CC0 Kenney card sound (licence in sfx-source/kenney/)
# to 48 kHz stereo, with its peak near -13 dB, below the click.
#   ./prepare-card-sfx.sh   writes public/sfx/kenney/card-shoo.wav
set -eu

cd "$(dirname "$0")"
mkdir -p public/sfx/kenney

# card-slide-4 swishes for 3 frames before the card lands; PreviewShoo starts
# it 3 frames early (cardLead) so the landing falls on the card.
ffmpeg -v error -y -i sfx-source/kenney/card-slide-4.ogg -af "aresample=48000,volume=-11dB" \
  -ar 48000 -ac 2 -c:a pcm_s16le public/sfx/kenney/card-shoo.wav
echo "wrote public/sfx/kenney/card-shoo.wav"
