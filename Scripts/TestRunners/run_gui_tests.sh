#!/bin/zsh

set -euo pipefail

repository_root="${0:A:h:h:h}"
readonly derived_data_path="$(mktemp -d /private/tmp/boundless-translator-gui.XXXXXX)"

function clean_up {
    rm -rf "${derived_data_path}"
}
trap clean_up EXIT

cd "$repository_root"

xcodebuild test \
    -project Tests/GUIProject/BoundlessTranslatorGUITests.xcodeproj \
    -scheme BoundlessTranslatorGUITests \
    -destination 'platform=macOS' \
    -derivedDataPath "${derived_data_path}" \
    -jobs 1 \
    CC=/usr/bin/true \
    CODE_SIGN_IDENTITY=- \
    CODE_SIGN_STYLE=Manual
