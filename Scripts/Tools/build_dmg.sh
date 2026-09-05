#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"
readonly BUILD_EXECUTABLE="${BOUNDLESS_TRANSLATOR_BUILD_EXECUTABLE:-${PROJECT_ROOT}/Scripts/Tools/build_app.sh}"
readonly VERIFY_EXECUTABLE="${BOUNDLESS_TRANSLATOR_VERIFY_EXECUTABLE:-${PROJECT_ROOT}/Scripts/Tools/verify_app.sh}"
readonly PACKAGE_EXECUTABLE="${BOUNDLESS_TRANSLATOR_PACKAGE_EXECUTABLE:-${PROJECT_ROOT}/Scripts/Tools/package_dmg.sh}"
readonly APP_PATH="${BOUNDLESS_TRANSLATOR_DMG_APP_PATH:-${PROJECT_ROOT}/Build/Boundless Translator.app}"

if [[ "$#" -ne 1 ]]; then
    print -u2 "Usage: build_dmg.sh <output-path>"
    exit 1
fi
readonly DMG_PATH="$1"

"${BUILD_EXECUTABLE}"
"${VERIFY_EXECUTABLE}" "${APP_PATH}"
"${PACKAGE_EXECUTABLE}" "${APP_PATH}" "${DMG_PATH}"

print "Built ${DMG_PATH}"
