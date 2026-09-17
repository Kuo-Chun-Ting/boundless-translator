#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h}"
readonly BUILD_APP_EXECUTABLE="${BOUNDLESS_TRANSLATOR_BUILD_APP_EXECUTABLE:-${PROJECT_ROOT}/Scripts/DMG/build_app.sh}"
readonly PACKAGE_DMG_EXECUTABLE="${BOUNDLESS_TRANSLATOR_PACKAGE_DMG_EXECUTABLE:-${PROJECT_ROOT}/Scripts/DMG/package_dmg.sh}"
readonly VERIFY_DMG_EXECUTABLE="${BOUNDLESS_TRANSLATOR_VERIFY_DMG_EXECUTABLE:-${PROJECT_ROOT}/Scripts/DMG/verify_dmg.sh}"
readonly NOTARIZE_EXECUTABLE="${BOUNDLESS_TRANSLATOR_NOTARIZE_EXECUTABLE:-${PROJECT_ROOT}/Scripts/DMG/notarize_dmg.sh}"
readonly MV_EXECUTABLE="${BOUNDLESS_TRANSLATOR_MV_EXECUTABLE:-mv}"
readonly BUILD_ROOT="${BOUNDLESS_TRANSLATOR_RELEASE_BUILD_ROOT:-${PROJECT_ROOT}/Build}"

if [[ "$#" -ne 0 ]]; then
    print -u2 'Usage: release_dmg.sh'
    exit 1
fi

mkdir -p "${BUILD_ROOT}"
readonly TEMP_ROOT="$(mktemp -d "${BUILD_ROOT}/.boundless-translator-test.XXXXXX")"
readonly APP_PATH="${TEMP_ROOT}/Boundless Translator.app"
readonly STAGED_DMG_PATH="${TEMP_ROOT}/Boundless Translator-test.dmg"
readonly FINAL_DMG_PATH="${BUILD_ROOT}/Boundless Translator-test.dmg"
trap 'rm -rf "${TEMP_ROOT}"' EXIT

BOUNDLESS_TRANSLATOR_BUILD_ROOT="${TEMP_ROOT}" "${BUILD_APP_EXECUTABLE}"
"${PACKAGE_DMG_EXECUTABLE}" "${APP_PATH}" "${STAGED_DMG_PATH}"
"${VERIFY_DMG_EXECUTABLE}" "${STAGED_DMG_PATH}"
"${NOTARIZE_EXECUTABLE}" "${STAGED_DMG_PATH}"
"${MV_EXECUTABLE}" -f "${STAGED_DMG_PATH}" "${FINAL_DMG_PATH}"
print "Test DMG ready (no subscription): ${FINAL_DMG_PATH}"
