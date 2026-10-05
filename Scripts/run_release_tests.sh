#!/bin/zsh
set -euo pipefail
readonly PROJECT_ROOT="${0:A:h:h}"
readonly PRODUCT_NAME="${BOUNDLESS_TRANSLATOR_PRODUCT_NAME:-Boundless Translator DMG Test}"
readonly BUILD_ROOT="${BOUNDLESS_TRANSLATOR_RELEASE_BUILD_ROOT:-${PROJECT_ROOT}/Build}"
readonly RELEASE_EXECUTABLE="${BOUNDLESS_TRANSLATOR_RELEASE_DMG_EXECUTABLE:-${PROJECT_ROOT}/Scripts/release_dmg.sh}"
readonly VERIFY_DMG_EXECUTABLE="${BOUNDLESS_TRANSLATOR_VERIFY_DMG_EXECUTABLE:-${PROJECT_ROOT}/Scripts/DMG/verify_dmg.sh}"
readonly VERIFY_APP_EXECUTABLE="${BOUNDLESS_TRANSLATOR_VERIFY_APP_EXECUTABLE:-${PROJECT_ROOT}/Scripts/DMG/verify_app.sh}"
if (( $# > 1 )); then
    print -u2 'Usage: Scripts/run_release_tests.sh [existing-dmg-path]'
    exit 2
fi
readonly DMG_PATH="${1:-${BUILD_ROOT}/${BOUNDLESS_TRANSLATOR_DMG_NAME:-${PRODUCT_NAME}.dmg}}"
if (( $# == 0 )); then
    # This already checks the package contents and performs notarization.
    "${RELEASE_EXECUTABLE}"
else
    "${VERIFY_DMG_EXECUTABLE}" "${DMG_PATH}"
fi
[[ -f "${DMG_PATH}" ]] || { print -u2 "Missing DMG: ${DMG_PATH}"; exit 1; }
xcrun stapler validate "${DMG_PATH}"
spctl --assess --type open --context context:primary-signature --verbose=4 "${DMG_PATH}"

readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-release-install.XXXXXX)"
readonly MOUNT_POINT="${TEMP_ROOT}/Mounted"
readonly INSTALLED_APP="${TEMP_ROOT}/Installed/${PRODUCT_NAME}.app"
mounted=0
function clean_up {
    if (( mounted )); then hdiutil detach "${MOUNT_POINT}" >/dev/null 2>&1 || true; fi
    rm -rf "${TEMP_ROOT}"
}
trap clean_up EXIT
trap 'exit 130' INT TERM
mkdir -p "${MOUNT_POINT}" "${TEMP_ROOT}/Installed"
hdiutil attach -readonly -nobrowse -mountpoint "${MOUNT_POINT}" "${DMG_PATH}" >/dev/null
mounted=1
ditto "${MOUNT_POINT}/${PRODUCT_NAME}.app" "${INSTALLED_APP}"
hdiutil detach "${MOUNT_POINT}" >/dev/null
mounted=0
"${VERIFY_APP_EXECUTABLE}" "${INSTALLED_APP}"
print "Release package and installed launch verified: ${DMG_PATH}"
