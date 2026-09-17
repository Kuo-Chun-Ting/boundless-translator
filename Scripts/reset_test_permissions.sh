#!/bin/zsh

set -euo pipefail

readonly BUNDLE_IDENTIFIER="${BOUNDLESS_TRANSLATOR_BUNDLE_IDENTIFIER:-com.lillard.BoundlessTranslator}"
readonly EXECUTABLE_NAME="${BOUNDLESS_TRANSLATOR_EXECUTABLE_NAME:-BoundlessTranslator}"
readonly PKILL_EXECUTABLE="${BOUNDLESS_TRANSLATOR_PKILL_EXECUTABLE:-/usr/bin/pkill}"
readonly TCCUTIL_EXECUTABLE="${BOUNDLESS_TRANSLATOR_TCCUTIL_EXECUTABLE:-/usr/bin/tccutil}"

function fail {
    print -u2 -- "$1"
    exit 1
}

[[ -x "${PKILL_EXECUTABLE}" ]] || fail "pkill is not executable: ${PKILL_EXECUTABLE}"
[[ -x "${TCCUTIL_EXECUTABLE}" ]] || fail "tccutil is not executable: ${TCCUTIL_EXECUTABLE}"
[[ -n "${BUNDLE_IDENTIFIER}" ]] || fail "Boundless Translator bundle identifier is empty."
[[ -n "${EXECUTABLE_NAME}" ]] || fail "Boundless Translator executable name is empty."

"${PKILL_EXECUTABLE}" -f "/${EXECUTABLE_NAME}([[:space:]]|$)" 2>/dev/null || true
"${TCCUTIL_EXECUTABLE}" reset Accessibility "${BUNDLE_IDENTIFIER}"
"${TCCUTIL_EXECUTABLE}" reset ScreenCapture "${BUNDLE_IDENTIFIER}"

print "Reset Accessibility and Screen Recording permissions for ${BUNDLE_IDENTIFIER}."
