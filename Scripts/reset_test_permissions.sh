#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h}"
readonly INFO_PLIST="${BOUNDLESS_TRANSLATOR_INFO_PLIST:-${PROJECT_ROOT}/Resources/Info.plist}"
readonly PKILL_EXECUTABLE="${BOUNDLESS_TRANSLATOR_PKILL_EXECUTABLE:-/usr/bin/pkill}"
readonly TCCUTIL_EXECUTABLE="${BOUNDLESS_TRANSLATOR_TCCUTIL_EXECUTABLE:-/usr/bin/tccutil}"

function fail {
    print -u2 -- "$1"
    exit 1
}

[[ -f "${INFO_PLIST}" ]] || fail "Info.plist not found: ${INFO_PLIST}"
[[ -x "${PKILL_EXECUTABLE}" ]] || fail "pkill is not executable: ${PKILL_EXECUTABLE}"
[[ -x "${TCCUTIL_EXECUTABLE}" ]] || fail "tccutil is not executable: ${TCCUTIL_EXECUTABLE}"

readonly BUNDLE_IDENTIFIER="$(plutil -extract CFBundleIdentifier raw "${INFO_PLIST}")"
readonly EXECUTABLE_NAME="$(plutil -extract CFBundleExecutable raw "${INFO_PLIST}")"

[[ -n "${BUNDLE_IDENTIFIER}" ]] || fail "CFBundleIdentifier is empty in ${INFO_PLIST}"
[[ -n "${EXECUTABLE_NAME}" ]] || fail "CFBundleExecutable is empty in ${INFO_PLIST}"

"${PKILL_EXECUTABLE}" -f "/${EXECUTABLE_NAME}([[:space:]]|$)" 2>/dev/null || true
"${TCCUTIL_EXECUTABLE}" reset Accessibility "${BUNDLE_IDENTIFIER}"
"${TCCUTIL_EXECUTABLE}" reset ScreenCapture "${BUNDLE_IDENTIFIER}"

print "Reset Accessibility and Screen Recording permissions for ${BUNDLE_IDENTIFIER}."
