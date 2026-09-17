#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"
readonly BACKGROUND_PATH="${PROJECT_ROOT}/Resources/DMGBackground.png"
readonly VERIFY_EXECUTABLE="${BOUNDLESS_TRANSLATOR_VERIFY_EXECUTABLE:-${PROJECT_ROOT}/Scripts/Tools/verify_app.sh}"
readonly EXPECTED_TEAM_ID="3S9ZKKJ6PW"
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
readonly MOUNT_POINT="${TEMP_ROOT}/Mounted"
active_mount_point=""

function clean_up {
    if [[ -n "${active_mount_point}" ]]; then
        hdiutil detach "${active_mount_point}" >/dev/null 2>&1 || true
    fi
    rm -rf "${TEMP_ROOT}"
}
trap clean_up EXIT

function fail {
    print -u2 "$1"
    exit 1
}

function verify_dmg {
    local dmg_path="$1"

    hdiutil verify "${dmg_path}" >/dev/null
    codesign --verify --strict --verbose=2 "${dmg_path}"

    local signature_details
    signature_details="$(codesign --display --verbose=4 "${dmg_path}" 2>&1)"
    [[ "${signature_details}" == *"TeamIdentifier=${EXPECTED_TEAM_ID}"* ]] ||
        fail "DMG signature has the wrong Team ID."
    [[ "${signature_details}" == *"Timestamp="* ]] ||
        fail "DMG signature does not include a secure timestamp."

    mkdir -p "${MOUNT_POINT}"
    hdiutil attach -readonly -nobrowse -mountpoint "${MOUNT_POINT}" "${dmg_path}" >/dev/null
    active_mount_point="${MOUNT_POINT}"

    [[ -d "${MOUNT_POINT}/Boundless Translator.app" ]] ||
        fail "DMG does not contain Boundless Translator.app."
    [[ -L "${MOUNT_POINT}/Applications" && "$(readlink "${MOUNT_POINT}/Applications")" == /Applications ]] ||
        fail "DMG does not contain the Applications shortcut."
    [[ -f "${MOUNT_POINT}/.DS_Store" ]] ||
        fail "DMG does not contain its Finder layout."
    [[ -f "${MOUNT_POINT}/.background/DMGBackground.png" ]] ||
        fail "DMG does not contain its background image."
    "${VERIFY_EXECUTABLE}" "${MOUNT_POINT}/Boundless Translator.app"

    hdiutil detach "${MOUNT_POINT}" >/dev/null
    active_mount_point=""
}

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

verify_dmg "${TEMP_DMG}"
mv -f "${TEMP_DMG}" "${DMG_PATH}"

print "Packaged ${DMG_PATH}"
