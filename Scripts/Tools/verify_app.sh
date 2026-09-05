#!/bin/zsh

set -euo pipefail

if [[ "$#" -ne 1 ]]; then
    print -u2 "Usage: verify_app.sh <app-path>"
    exit 1
fi

readonly APP_PATH="$1"
readonly BUNDLE_IDENTIFIER="com.lillard.BoundlessTranslator"
readonly EXPECTED_TEAM_ID="3S9ZKKJ6PW"

readonly SIGNING_REQUIREMENT="identifier \"${BUNDLE_IDENTIFIER}\" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] exists and certificate leaf[field.1.2.840.113635.100.6.1.13] exists and certificate leaf[subject.OU] = \"${EXPECTED_TEAM_ID}\""

codesign \
    --verify \
    --deep \
    --strict \
    --verbose=2 \
    -R="${SIGNING_REQUIREMENT}" \
    "${APP_PATH}"

readonly SIGNATURE_DETAILS="$(codesign --display --verbose=4 "${APP_PATH}" 2>&1)"

if [[ "${SIGNATURE_DETAILS}" != *"flags=0x10000(runtime)"* ]]; then
    print -u2 "App signature does not enable Hardened Runtime."
    exit 1
fi

if [[ "${SIGNATURE_DETAILS}" != *"Timestamp="* ]]; then
    print -u2 "App signature does not include a secure timestamp."
    exit 1
fi

plutil -lint "${APP_PATH}/Contents/Info.plist"
