#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h}"
exec zsh "${PROJECT_ROOT}/Scripts/verify.sh" features
