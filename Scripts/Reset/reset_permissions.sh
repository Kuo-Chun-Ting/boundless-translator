#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"
case "$1" in
    dmg)
        bundle_identifier='com.lillard.BoundlessTranslator.dmgtest'
        app_path='/Applications/Boundless Translator DMG Test.app'
        ;;
    app-store)
        bundle_identifier='com.lillard.BoundlessTranslator'
        app_path='/Applications/Boundless Translator.app'
        ;;
    e2e)
        bundle_identifier='com.lillard.BoundlessTranslator.e2e'
        app_path="${PROJECT_ROOT}/Build/E2E/App/Boundless Translator E2E.app"
        ;;
esac
readonly BUNDLE_IDENTIFIER="${bundle_identifier}"
readonly APP_PATH="${BOUNDLESS_TRANSLATOR_APP_PATH:-${app_path}}"
readonly PKILL_EXECUTABLE="${BOUNDLESS_TRANSLATOR_PKILL_EXECUTABLE:-/usr/bin/pkill}"
readonly TCCUTIL_EXECUTABLE="${BOUNDLESS_TRANSLATOR_TCCUTIL_EXECUTABLE:-/usr/bin/tccutil}"
readonly INFO_PLIST="${APP_PATH}/Contents/Info.plist"
readonly EXECUTABLE_NAME="$(plutil -extract CFBundleExecutable raw "${INFO_PLIST}")"
readonly EXECUTABLE_PATH="${APP_PATH}/Contents/MacOS/${EXECUTABLE_NAME}"

"${PKILL_EXECUTABLE}" -f "^${EXECUTABLE_PATH}([[:space:]]|$)" 2>/dev/null || true
"${TCCUTIL_EXECUTABLE}" reset Accessibility "${BUNDLE_IDENTIFIER}"
"${TCCUTIL_EXECUTABLE}" reset ScreenCapture "${BUNDLE_IDENTIFIER}"

print "Reset Accessibility and Screen Recording permissions for ${BUNDLE_IDENTIFIER}."
