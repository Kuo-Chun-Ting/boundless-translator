#!/bin/zsh

set -euo pipefail

case "$1" in
    dmg) bundle_identifier='com.lillard.BoundlessTranslator.dmgtest' ;;
    app-store) bundle_identifier='com.lillard.BoundlessTranslator' ;;
    e2e) bundle_identifier='com.lillard.BoundlessTranslator.e2e' ;;
esac
readonly DATA_PATH="${HOME}/Library/Containers/${bundle_identifier}/Data"

osascript - "${bundle_identifier}" <<'APPLESCRIPT'
on run arguments
    set bundleIdentifier to item 1 of arguments
    if application id bundleIdentifier is running then
        tell application id bundleIdentifier to quit
    end if
end run
APPLESCRIPT

defaults delete "${DATA_PATH}/Library/Preferences/${bundle_identifier}.plist" 2>/dev/null || true
rm -rf "${DATA_PATH}"
print "App data cleared for ${bundle_identifier}. Reopen that App to test a fresh launch."
