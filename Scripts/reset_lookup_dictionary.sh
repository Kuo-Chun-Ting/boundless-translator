#!/bin/zsh
set -euo pipefail

readonly PREFERENCES_PATH="${HOME}/Library/Containers/com.apple.LookupViewService/Data/Library/Preferences/com.apple.lookup.plist"

# Stop the service before changing preferences so it cannot restore its cached acknowledgement.
killall LookupViewService 2>/dev/null || true
plutil -convert xml1 -o - "${PREFERENCES_PATH}" | sed -n \
    -e 's/^[[:space:]]*<key>\(FTE\/Lookup\)<\/key>$/\1/p' \
    -e 's/^[[:space:]]*<key>\(FTE\/Lookup:[^<]*\)<\/key>$/\1/p' | \
while IFS= read -r prompt_key; do
    defaults delete "${PREFERENCES_PATH}" "${prompt_key}"
done
print 'First-use records cleared. Quit and reopen Boundless Translator, then look up a word.'
