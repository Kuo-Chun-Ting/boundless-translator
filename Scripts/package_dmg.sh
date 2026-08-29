#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h}"
readonly DEFAULT_APP_PATH="${PROJECT_ROOT}/Build/Boundless Translator.app"
readonly DEFAULT_DMG_PATH="${PROJECT_ROOT}/Build/Boundless Translator.dmg"
readonly BACKGROUND_PATH="${PROJECT_ROOT}/Resources/DMGBackground.png"

if [[ -n "${BOUNDLESS_TRANSLATOR_CREATE_DMG_EXECUTABLE:-}" ]]; then
    CREATE_DMG_EXECUTABLE="${BOUNDLESS_TRANSLATOR_CREATE_DMG_EXECUTABLE}"
else
    CREATE_DMG_EXECUTABLE="$(command -v create-dmg || true)"
fi
readonly CREATE_DMG_EXECUTABLE

if [[ "$#" -eq 0 ]]; then
    readonly APP_PATH="${DEFAULT_APP_PATH}"
    readonly DMG_PATH="${DEFAULT_DMG_PATH}"
elif [[ "$#" -eq 2 ]]; then
    readonly APP_PATH="$1"
    readonly DMG_PATH="$2"
else
    print -u2 "Usage: package_dmg.sh [<app-path> <dmg-path>]"
    exit 1
fi

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

hdiutil verify "${TEMP_DMG}" >/dev/null
mv -f "${TEMP_DMG}" "${DMG_PATH}"

print "Packaged ${DMG_PATH}"
