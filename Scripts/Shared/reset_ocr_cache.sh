#!/bin/zsh
set -euo pipefail

case "${1:-}" in
    dmg) bundle_identifier='com.lillard.BoundlessTranslator.dmgtest' ;;
    app-store) bundle_identifier='com.lillard.BoundlessTranslator' ;;
    e2e) bundle_identifier='com.lillard.BoundlessTranslator.e2e' ;;
    *) print -u2 'Usage: reset_ocr_cache.sh <dmg|app-store|e2e>'; exit 2 ;;
esac
readonly CACHE_PATH="${HOME}/Library/Containers/${bundle_identifier}/Data/Library/Caches/${bundle_identifier}/com.apple.e5rt.e5bundlecache"

osascript - "${bundle_identifier}" <<'APPLESCRIPT'
on run arguments
    set bundleIdentifier to item 1 of arguments
    if application id bundleIdentifier is running then
        tell application id bundleIdentifier to quit
    end if
end run
APPLESCRIPT

rm -rf "${CACHE_PATH}"
print "OCR model cache cleared for ${bundle_identifier}. The next recognition may take longer."
