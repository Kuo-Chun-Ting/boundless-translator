#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"
source "${PROJECT_ROOT}/Scripts/DMG/signing.conf"

readonly XCODE_PROJECT="${PROJECT_ROOT}/BoundlessTranslator.xcodeproj"
readonly XCODEBUILD_EXECUTABLE="${BOUNDLESS_TRANSLATOR_XCODEBUILD_EXECUTABLE:-xcodebuild}"
readonly BUILD_ROOT="${BOUNDLESS_TRANSLATOR_BUILD_ROOT:-${PROJECT_ROOT}/Build}"
readonly PRODUCT_NAME="${BOUNDLESS_TRANSLATOR_PRODUCT_NAME:-Boundless Translator}"
readonly BUNDLE_IDENTIFIER="${BOUNDLESS_TRANSLATOR_BUNDLE_IDENTIFIER:-com.lillard.BoundlessTranslator}"
readonly APP_PATH="${BUILD_ROOT}/${PRODUCT_NAME}.app"

function fail {
    print -u2 "$1"
    exit 1
}

[[ "$#" -eq 0 ]] || fail 'Usage: build_app.sh'

mkdir -p "${BUILD_ROOT}"
readonly TEMP_ROOT="$(mktemp -d "${BUILD_ROOT}/.boundless-translator-build.XXXXXX")"
readonly DERIVED_DATA_PATH="${TEMP_ROOT}/DerivedData"
readonly BUILT_APP_PATH="${DERIVED_DATA_PATH}/Build/Products/DirectRelease/${PRODUCT_NAME}.app"
trap 'rm -rf "${TEMP_ROOT}"' EXIT

"${XCODEBUILD_EXECUTABLE}" \
    build \
    -project "${XCODE_PROJECT}" \
    -scheme BoundlessTranslator-Direct \
    -configuration DirectRelease \
    -destination 'platform=macOS,arch=arm64' \
    -derivedDataPath "${DERIVED_DATA_PATH}" \
    'CODE_SIGN_STYLE=Manual' \
    "CODE_SIGN_IDENTITY=${BOUNDLESS_TRANSLATOR_DEVELOPER_ID_IDENTITY:-${DEFAULT_SIGNING_IDENTITY}}" \
    "BOUNDLESS_TRANSLATOR_PRODUCT_NAME=${PRODUCT_NAME}" \
    "BOUNDLESS_TRANSLATOR_BUNDLE_IDENTIFIER=${BUNDLE_IDENTIFIER}"

[[ -d "${BUILT_APP_PATH}" ]] || fail "Xcode build is missing the App: ${BUILT_APP_PATH}"
rm -rf "${APP_PATH}"
mv "${BUILT_APP_PATH}" "${APP_PATH}"
print "Built ${APP_PATH}"
