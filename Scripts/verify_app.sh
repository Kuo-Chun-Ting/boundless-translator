#!/bin/zsh

set -euo pipefail

if [[ "$#" -ne 1 ]]; then
    print -u2 "Usage: verify_app.sh <app-path>"
    exit 1
fi

readonly APP_PATH="$1"
readonly BUNDLE_IDENTIFIER="com.lillard.BoundlessTranslator"
readonly EXPECTED_SIGNER_SHA1="2A650F82E97048C85359EC506D920C5BF684CAEE"

readonly SIGNING_REQUIREMENT="identifier \"${BUNDLE_IDENTIFIER}\" and certificate leaf = H\"${EXPECTED_SIGNER_SHA1}\""

codesign \
    --verify \
    --deep \
    --strict \
    --verbose=2 \
    -R="${SIGNING_REQUIREMENT}" \
    "${APP_PATH}"

plutil -lint "${APP_PATH}/Contents/Info.plist"
