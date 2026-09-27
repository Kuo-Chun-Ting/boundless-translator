#!/bin/zsh
set -e
cd "${0:A:h:h:h}"

echo "=== Distribute started ==="
xcodebuild -exportArchive \
  -archivePath Build/AppStore/BoundlessTranslator.xcarchive \
  -exportPath Build/AppStore/Upload \
  -exportOptionsPlist Scripts/AppStore/UploadOptions.plist \
  -allowProvisioningUpdates

echo "=== Distribute succeeded ==="
