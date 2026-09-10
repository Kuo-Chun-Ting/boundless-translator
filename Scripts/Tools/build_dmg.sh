#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"
readonly BUILD_EXECUTABLE="${BOUNDLESS_TRANSLATOR_BUILD_EXECUTABLE:-${PROJECT_ROOT}/Scripts/Tools/build_app.sh}"
readonly VERIFY_EXECUTABLE="${BOUNDLESS_TRANSLATOR_VERIFY_EXECUTABLE:-${PROJECT_ROOT}/Scripts/Tools/verify_app.sh}"
readonly PACKAGE_EXECUTABLE="${BOUNDLESS_TRANSLATOR_PACKAGE_EXECUTABLE:-${PROJECT_ROOT}/Scripts/Tools/package_dmg.sh}"

if [[ "$#" -ne 1 ]]; then
    print -u2 "Usage: build_dmg.sh <output-path>"
    exit 1
fi
readonly DMG_PATH="$1"
mkdir -p "${DMG_PATH:h}"
readonly TEMP_ROOT="$(mktemp -d "${DMG_PATH:h}/.boundless-translator-dmg.XXXXXX")"
readonly APP_PATH="${TEMP_ROOT}/Boundless Translator.app"
trap 'rm -rf "${TEMP_ROOT}"' EXIT

BOUNDLESS_TRANSLATOR_BUILD_ROOT="${TEMP_ROOT}" "${BUILD_EXECUTABLE}"
"${VERIFY_EXECUTABLE}" "${APP_PATH}"
"${PACKAGE_EXECUTABLE}" "${APP_PATH}" "${DMG_PATH}"

print "Built ${DMG_PATH}"
