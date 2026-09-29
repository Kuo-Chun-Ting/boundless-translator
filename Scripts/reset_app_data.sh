#!/bin/zsh

set -euo pipefail

readonly DATA_PATH="${HOME}/Library/Containers/com.lillard.BoundlessTranslator/Data"

osascript <<'APPLESCRIPT'
if application id "com.lillard.BoundlessTranslator" is running then
    tell application id "com.lillard.BoundlessTranslator" to quit
end if
APPLESCRIPT

defaults delete "${DATA_PATH}/Library/Preferences/com.lillard.BoundlessTranslator.plist" 2>/dev/null || true
rm -rf "${DATA_PATH}"
print 'App data cleared. Open Boundless Translator to test a fresh launch.'
