#!/bin/zsh
set -e
cd "${0:A:h:h:h}"

echo "=== Archive started ==="
xcodebuild archive \
  -project BoundlessTranslator.xcodeproj \
  -scheme BoundlessTranslator-AppStore \
  -destination 'generic/platform=macOS' \
  -archivePath Build/AppStore/BoundlessTranslator.xcarchive \
  -allowProvisioningUpdates

echo "=== Archive succeeded ==="
