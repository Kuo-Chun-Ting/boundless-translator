#!/bin/zsh
set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h}"
readonly BUILD_ROOT="${PROJECT_ROOT}/Build/AppStore"
readonly APP_PATH="${BUILD_ROOT}/Boundless Translator.app"

typeset -a build_options=(
    -project "${PROJECT_ROOT}/BoundlessTranslator.xcodeproj"
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

mkdir -p "${BUILD_ROOT}"
readonly TEMP_ROOT="$(mktemp -d "${BUILD_ROOT}/.app-build.XXXXXX")"
readonly BUILT_APP_PATH="${TEMP_ROOT}/Build/Products/AppStoreRelease/Boundless Translator.app"
trap 'rm -rf "${TEMP_ROOT}"' EXIT

xcodebuild build "${build_options[@]}" \
    -derivedDataPath "${TEMP_ROOT}" \
    -allowProvisioningUpdates

rm -rf "${APP_PATH}"
mv "${BUILT_APP_PATH}" "${APP_PATH}"
print "Built ${APP_PATH}"
