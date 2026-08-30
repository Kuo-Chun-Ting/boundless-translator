#!/bin/zsh

set -euo pipefail

repository_root="${0:A:h:h}"
cd "$repository_root"

xcodebuild test \
    -project Tests/GUIProject/BoundlessTranslatorGUITests.xcodeproj \
    -scheme BoundlessTranslatorGUITests \
    -destination 'platform=macOS' \
    -derivedDataPath .build/gui-derived-data \
    -jobs 1 \
    CC=/usr/bin/true \
    CODE_SIGN_IDENTITY=- \
    CODE_SIGN_STYLE=Manual
