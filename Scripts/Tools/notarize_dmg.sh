#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"
readonly NOTARY_PROFILE="${BOUNDLESS_TRANSLATOR_NOTARY_PROFILE:-BoundlessTranslatorNotary}"
readonly XCRUN_EXECUTABLE="${BOUNDLESS_TRANSLATOR_XCRUN_EXECUTABLE:-$(command -v xcrun)}"
readonly SPCTL_EXECUTABLE="${BOUNDLESS_TRANSLATOR_SPCTL_EXECUTABLE:-$(command -v spctl)}"

if [[ "$#" -ne 1 ]]; then
    print -u2 "Usage: notarize_dmg.sh <dmg-path>"
    exit 1
fi
readonly DMG_PATH="$1"

if [[ ! -f "${DMG_PATH}" ]]; then
    print -u2 "DMG does not exist: ${DMG_PATH}"
    exit 1
fi

"${XCRUN_EXECUTABLE}" notarytool submit \
    "${DMG_PATH}" \
    --keychain-profile "${NOTARY_PROFILE}" \
    --wait

"${XCRUN_EXECUTABLE}" stapler staple "${DMG_PATH}"
"${XCRUN_EXECUTABLE}" stapler validate "${DMG_PATH}"
"${SPCTL_EXECUTABLE}" \
    --assess \
    --type open \
    --context context:primary-signature \
    --verbose=4 \
    "${DMG_PATH}"

print "Notarized and stapled ${DMG_PATH}"
