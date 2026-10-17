#!/bin/zsh
set -euo pipefail

exec "${0:A:h}/Shared/reset_ocr_cache.sh" dmg
