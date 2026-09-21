#!/bin/zsh

set -euo pipefail

readonly BUNDLE_IDENTIFIER="${BOUNDLESS_TRANSLATOR_BUNDLE_IDENTIFIER:-com.lillard.BoundlessTranslator}"
readonly APP_PATH="${BOUNDLESS_TRANSLATOR_APP_PATH:-/Applications/Boundless Translator.app}"
readonly PKILL_EXECUTABLE="${BOUNDLESS_TRANSLATOR_PKILL_EXECUTABLE:-/usr/bin/pkill}"
readonly TCCUTIL_EXECUTABLE="${BOUNDLESS_TRANSLATOR_TCCUTIL_EXECUTABLE:-/usr/bin/tccutil}"
readonly INFO_PLIST="${APP_PATH}/Contents/Info.plist"
readonly EXECUTABLE_NAME="$(plutil -extract CFBundleExecutable raw "${INFO_PLIST}")"
readonly EXECUTABLE_PATH="${APP_PATH}/Contents/MacOS/${EXECUTABLE_NAME}"

"${PKILL_EXECUTABLE}" -f "^${EXECUTABLE_PATH}([[:space:]]|$)" 2>/dev/null || true
"${TCCUTIL_EXECUTABLE}" reset Accessibility "${BUNDLE_IDENTIFIER}"
"${TCCUTIL_EXECUTABLE}" reset ScreenCapture "${BUNDLE_IDENTIFIER}"

print "Reset Accessibility and Screen Recording permissions for ${BUNDLE_IDENTIFIER}."
