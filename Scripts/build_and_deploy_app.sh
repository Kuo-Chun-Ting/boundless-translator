#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h}"

"${PROJECT_ROOT}/Scripts/build_app.sh"
"${PROJECT_ROOT}/Scripts/deploy_app.sh"
