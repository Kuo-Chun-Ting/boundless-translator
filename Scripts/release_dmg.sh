#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h}"
readonly BUILD_DMG_EXECUTABLE="${BOUNDLESS_TRANSLATOR_BUILD_DMG_EXECUTABLE:-${PROJECT_ROOT}/Scripts/Tools/build_dmg.sh}"
readonly NOTARIZE_EXECUTABLE="${BOUNDLESS_TRANSLATOR_NOTARIZE_EXECUTABLE:-${PROJECT_ROOT}/Scripts/Tools/notarize_dmg.sh}"
readonly MV_EXECUTABLE="${BOUNDLESS_TRANSLATOR_MV_EXECUTABLE:-mv}"
readonly INFO_PLIST="${BOUNDLESS_TRANSLATOR_INFO_PLIST:-${PROJECT_ROOT}/Resources/Info.plist}"
readonly BUILD_ROOT="${BOUNDLESS_TRANSLATOR_RELEASE_BUILD_ROOT:-${PROJECT_ROOT}/Build}"

if [[ "$#" -ne 1 || "$1" != --test ]]; then
    print -u2 'Usage: release_dmg.sh --test'
    exit 1
fi

mkdir -p "${BUILD_ROOT}"
readonly TEMP_ROOT="$(mktemp -d "${BUILD_ROOT}/.boundless-translator-test.XXXXXX")"
trap 'rm -rf "${TEMP_ROOT}"' EXIT
readonly TEST_DMG_PATH="${BUILD_ROOT}/Boundless Translator-test.dmg"
readonly STAGED_INFO_PLIST="${TEMP_ROOT}/Info.plist"
cp "${INFO_PLIST}" "${STAGED_INFO_PLIST}"
BOUNDLESS_TRANSLATOR_BUILD_INFO_PLIST="${STAGED_INFO_PLIST}" \
    "${BUILD_DMG_EXECUTABLE}" "${TEMP_ROOT}/Boundless Translator-test.dmg"
"${NOTARIZE_EXECUTABLE}" "${TEMP_ROOT}/Boundless Translator-test.dmg"
"${MV_EXECUTABLE}" -f "${TEMP_ROOT}/Boundless Translator-test.dmg" "${TEST_DMG_PATH}"
print "Test DMG ready (no subscription, notarized): ${TEST_DMG_PATH}"
