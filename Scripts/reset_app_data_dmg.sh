#!/bin/zsh

set -euo pipefail

exec "${0:A:h}/Reset/reset_app_data.sh" dmg
