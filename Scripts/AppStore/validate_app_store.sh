#!/bin/zsh
set -e
cd "${0:A:h:h:h}"

echo "=== Validate started ==="
xcodebuild -exportArchive \
  -archivePath Build/AppStore/BoundlessTranslator.xcarchive \
  -exportPath Build/AppStore/Validation \
  -exportOptionsPlist Scripts/AppStore/ValidationOptions.plist \
  -allowProvisioningUpdates

echo "=== Validate succeeded ==="
