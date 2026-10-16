#!/bin/zsh
set -euo pipefail

readonly SCRIPT_ROOT="${0:A:h}"

"${SCRIPT_ROOT}/reset_app_data_dmg.sh"
"${SCRIPT_ROOT}/reset_permissions_dmg.sh"
"${SCRIPT_ROOT}/reset_lookup_dictionary.sh"
