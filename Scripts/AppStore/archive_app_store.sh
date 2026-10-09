#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h:h}"

typeset -a build_options=(
  -project BoundlessTranslator.xcodeproj
  -scheme BoundlessTranslator-AppStore
  -configuration AppStoreRelease
  -destination 'generic/platform=macOS'
)
xcodebuild -showBuildSettings "${build_options[@]}" -json | python3 -c '
import json, sys
settings = next(entry["buildSettings"] for entry in json.load(sys.stdin)
                if entry["target"] == "BoundlessTranslator")
if "SUBSCRIPTION_REQUIRED" not in settings.get("SWIFT_ACTIVE_COMPILATION_CONDITIONS", "").split():
    sys.exit("App Store build must enable SUBSCRIPTION_REQUIRED.")
'

echo "=== Archive started ==="
xcodebuild archive "${build_options[@]}" \
  -archivePath Build/AppStore/BoundlessTranslator.xcarchive \
  -allowProvisioningUpdates

echo "=== Archive succeeded ==="
