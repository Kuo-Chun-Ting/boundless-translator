#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"
readonly BACKGROUND_PATH="${PROJECT_ROOT}/Resources/DMGBackground.png"
source "${PROJECT_ROOT}/Scripts/Tools/code_signing.conf"
readonly SIGNING_IDENTITY="${BOUNDLESS_TRANSLATOR_SIGNING_IDENTITY:-${DEFAULT_SIGNING_IDENTITY}}"

if [[ -n "${BOUNDLESS_TRANSLATOR_CREATE_DMG_EXECUTABLE:-}" ]]; then
    CREATE_DMG_EXECUTABLE="${BOUNDLESS_TRANSLATOR_CREATE_DMG_EXECUTABLE}"
else
    CREATE_DMG_EXECUTABLE="$(command -v create-dmg || true)"
fi
readonly CREATE_DMG_EXECUTABLE

if [[ "$#" -ne 2 ]]; then
    print -u2 "Usage: package_dmg.sh <app-path> <dmg-path>"
    exit 1
fi
readonly APP_PATH="$1"
readonly DMG_PATH="$2"

if [[ ! -d "${APP_PATH}" ]]; then
    print -u2 "Source App does not exist: ${APP_PATH}"
    exit 1
fi

if [[ ! -x "${CREATE_DMG_EXECUTABLE}" ]]; then
    print -u2 "create-dmg is not installed. Run: brew install create-dmg"
    exit 1
fi

if [[ ! -f "${BACKGROUND_PATH}" ]]; then
    print -u2 "DMG background does not exist: ${BACKGROUND_PATH}"
    exit 1
fi

readonly OUTPUT_DIRECTORY="${DMG_PATH:h}"
mkdir -p "${OUTPUT_DIRECTORY}"

readonly TEMP_ROOT="$(mktemp -d "${OUTPUT_DIRECTORY}/.boundless-translator-dmg.XXXXXX")"
readonly STAGING_ROOT="${TEMP_ROOT}/Volume"
readonly STAGED_APP="${STAGING_ROOT}/Boundless Translator.app"
readonly TEMP_DMG="${TEMP_ROOT}/Boundless Translator.dmg"

function clean_up {
    rm -rf "${TEMP_ROOT}"
}
trap clean_up EXIT

mkdir -p "${STAGING_ROOT}"
ditto "${APP_PATH}" "${STAGED_APP}"

"${CREATE_DMG_EXECUTABLE}" \
    --volname "Boundless Translator" \
    --background "${BACKGROUND_PATH}" \
    --window-pos 200 120 \
    --window-size 640 360 \
    --text-size 13 \
    --icon-size 112 \
    --icon "Boundless Translator.app" 170 180 \
    --hide-extension "Boundless Translator.app" \
    --app-drop-link 470 180 \
    --filesystem "HFS+" \
    --format "UDZO" \
    --no-internet-enable \
    --overwrite \
    "${TEMP_DMG}" \
    "${STAGING_ROOT}"

codesign \
    --force \
    --timestamp \
    --sign "${SIGNING_IDENTITY}" \
    "${TEMP_DMG}"

hdiutil verify "${TEMP_DMG}" >/dev/null
codesign --verify --strict --verbose=2 "${TEMP_DMG}"
mv -f "${TEMP_DMG}" "${DMG_PATH}"

print "Packaged ${DMG_PATH}"
