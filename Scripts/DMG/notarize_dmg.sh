#!/bin/zsh

set -euo pipefail

readonly NOTARY_PROFILE="${BOUNDLESS_TRANSLATOR_NOTARY_PROFILE:-BoundlessTranslatorNotary}"
readonly XCRUN_EXECUTABLE="${BOUNDLESS_TRANSLATOR_XCRUN_EXECUTABLE:-xcrun}"
readonly SPCTL_EXECUTABLE="${BOUNDLESS_TRANSLATOR_SPCTL_EXECUTABLE:-spctl}"

readonly DMG_PATH="$1"

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
