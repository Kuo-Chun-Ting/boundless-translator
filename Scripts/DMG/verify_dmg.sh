#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"
readonly EXPECTED_TEAM_ID="3S9ZKKJ6PW"
readonly VERIFY_APP_EXECUTABLE="${BOUNDLESS_TRANSLATOR_VERIFY_APP_EXECUTABLE:-${PROJECT_ROOT}/Scripts/DMG/verify_app.sh}"

function fail {
    print -u2 "$1"
    exit 1
}

[[ "$#" -eq 1 ]] || fail 'Usage: verify_dmg.sh <dmg-path>'
readonly DMG_PATH="$1"
[[ -f "${DMG_PATH}" ]] || fail "DMG does not exist: ${DMG_PATH}"

readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-verify-dmg.XXXXXX)"
readonly MOUNT_POINT="${TEMP_ROOT}/Mounted"
active_mount_point=""

function clean_up {
    if [[ -n "${active_mount_point}" ]]; then
        hdiutil detach "${active_mount_point}" >/dev/null 2>&1 || true
    fi
    rm -rf "${TEMP_ROOT}"
}
trap clean_up EXIT

hdiutil verify "${DMG_PATH}" >/dev/null
codesign --verify --strict --verbose=2 "${DMG_PATH}"

readonly SIGNATURE_DETAILS="$(codesign --display --verbose=4 "${DMG_PATH}" 2>&1)"
[[ "${SIGNATURE_DETAILS}" == *"TeamIdentifier=${EXPECTED_TEAM_ID}"* ]] ||
    fail 'DMG signature has the wrong Team ID.'
[[ "${SIGNATURE_DETAILS}" == *"Timestamp="* ]] ||
    fail 'DMG signature does not include a secure timestamp.'

mkdir -p "${MOUNT_POINT}"
hdiutil attach -readonly -nobrowse -mountpoint "${MOUNT_POINT}" "${DMG_PATH}" >/dev/null
active_mount_point="${MOUNT_POINT}"

[[ -d "${MOUNT_POINT}/Boundless Translator.app" ]] ||
    fail 'DMG does not contain Boundless Translator.app.'
[[ -L "${MOUNT_POINT}/Applications" && "$(readlink "${MOUNT_POINT}/Applications")" == /Applications ]] ||
    fail 'DMG does not contain the Applications shortcut.'
[[ -f "${MOUNT_POINT}/.DS_Store" ]] ||
    fail 'DMG does not contain its Finder layout.'
[[ -f "${MOUNT_POINT}/.background/DMGBackground.png" ]] ||
    fail 'DMG does not contain its background image.'
"${VERIFY_APP_EXECUTABLE}" "${MOUNT_POINT}/Boundless Translator.app"

hdiutil detach "${MOUNT_POINT}" >/dev/null
active_mount_point=""
print "Verified ${DMG_PATH}"
