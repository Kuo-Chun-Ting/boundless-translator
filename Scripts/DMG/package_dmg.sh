#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"
readonly BACKGROUND_PATH="${PROJECT_ROOT}/Resources/DMGBackground.png"
source "${PROJECT_ROOT}/Scripts/DMG/signing.conf"
readonly SIGNING_IDENTITY="${BOUNDLESS_TRANSLATOR_SIGNING_IDENTITY:-${DEFAULT_SIGNING_IDENTITY}}"

readonly CREATE_DMG_EXECUTABLE="${BOUNDLESS_TRANSLATOR_CREATE_DMG_EXECUTABLE:-create-dmg}"

readonly APP_PATH="$1"
readonly DMG_PATH="$2"
readonly APP_NAME="${APP_PATH:t}"
readonly VOLUME_NAME="${APP_NAME%.app}"

readonly OUTPUT_DIRECTORY="${DMG_PATH:h}"
mkdir -p "${OUTPUT_DIRECTORY}"

readonly TEMP_ROOT="$(mktemp -d "${OUTPUT_DIRECTORY}/.boundless-translator-dmg.XXXXXX")"
readonly STAGING_ROOT="${TEMP_ROOT}/Volume"
readonly STAGED_APP="${STAGING_ROOT}/${APP_NAME}"
readonly TEMP_DMG="${TEMP_ROOT}/${VOLUME_NAME}.dmg"
trap 'rm -rf "${TEMP_ROOT}"' EXIT

mkdir -p "${STAGING_ROOT}"
ditto "${APP_PATH}" "${STAGED_APP}"

"${CREATE_DMG_EXECUTABLE}" \
    --volname "${VOLUME_NAME}" \
    --background "${BACKGROUND_PATH}" \
    --window-pos 200 120 \
    --window-size 640 360 \
    --text-size 13 \
    --icon-size 112 \
    --icon "${APP_NAME}" 170 180 \
    --hide-extension "${APP_NAME}" \
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

mv -f "${TEMP_DMG}" "${DMG_PATH}"

print "Packaged ${DMG_PATH}"
