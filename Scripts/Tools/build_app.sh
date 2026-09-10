#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"
if [[ "$#" -ne 0 ]]; then
    print -u2 'Usage: build_app.sh'
    exit 1
fi
readonly BUILD_ROOT="${BOUNDLESS_TRANSLATOR_BUILD_ROOT:-${PROJECT_ROOT}/Build}"
readonly APP_PATH="${BUILD_ROOT}/Boundless Translator.app"
readonly SOURCE_INFO_PLIST="${BOUNDLESS_TRANSLATOR_BUILD_INFO_PLIST:-${PROJECT_ROOT}/Resources/Info.plist}"
readonly DEVELOPER_PATH="/Applications/Xcode.app/Contents/Developer"
source "${PROJECT_ROOT}/Scripts/Tools/code_signing.conf"
readonly SIGNING_IDENTITY="${BOUNDLESS_TRANSLATOR_SIGNING_IDENTITY:-${DEFAULT_SIGNING_IDENTITY}}"
readonly MV_EXECUTABLE="${BOUNDLESS_TRANSLATOR_MV_EXECUTABLE:-mv}"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-build.XXXXXX)"
readonly SCRATCH_PATH="${TEMP_ROOT}/spm"
readonly STAGED_APP_PATH="${TEMP_ROOT}/Boundless Translator.app"
readonly CONTENTS_PATH="${STAGED_APP_PATH}/Contents"
readonly MACOS_PATH="${CONTENTS_PATH}/MacOS"
readonly RESOURCES_PATH="${CONTENTS_PATH}/Resources"
readonly PREVIOUS_APP_PATH="${TEMP_ROOT}/Previous Boundless Translator.app"
readonly PUBLISH_LOCK="${BUILD_ROOT}/.publish-lock"
publish_lock_acquired=false
rollback_failed=false

function clean_up {
    if [[ "${publish_lock_acquired}" == true ]]; then
        rmdir "${PUBLISH_LOCK}" 2>/dev/null || true
    fi
    if [[ "${rollback_failed}" == true ]]; then
        print -u2 "Publish rollback incomplete. Recovery artifacts preserved at: ${TEMP_ROOT}"
        return
    fi
    rm -rf "${TEMP_ROOT}"
}
trap clean_up EXIT

mkdir -p "${MACOS_PATH}" "${RESOURCES_PATH}"

swift_arguments=(
    build
    --configuration release
    --disable-sandbox
    --package-path "${PROJECT_ROOT}"
    --scratch-path "${SCRATCH_PATH}"
    --cache-path "${TEMP_ROOT}/cache"
    --config-path "${TEMP_ROOT}/config"
    --security-path "${TEMP_ROOT}/security"
)

CLANG_MODULE_CACHE_PATH="${TEMP_ROOT}/clang-cache" \
SWIFTPM_MODULECACHE_OVERRIDE="${TEMP_ROOT}/module-cache" \
DEVELOPER_DIR="${DEVELOPER_PATH}" \
swift "${swift_arguments[@]}"

cp "${SCRATCH_PATH}/release/BoundlessTranslator" "${MACOS_PATH}/BoundlessTranslator"
cp -R \
    "${SCRATCH_PATH}/release/BoundlessTranslator_BoundlessTranslator.bundle/"*.lproj \
    "${RESOURCES_PATH}/"
cp "${SOURCE_INFO_PLIST}" "${CONTENTS_PATH}/Info.plist"
cp "${PROJECT_ROOT}/Resources/AppIcon.icns" "${RESOURCES_PATH}/AppIcon.icns"
cp "${PROJECT_ROOT}/Resources/PrivacyInfo.xcprivacy" "${RESOURCES_PATH}/PrivacyInfo.xcprivacy"
plutil -lint "${RESOURCES_PATH}/PrivacyInfo.xcprivacy"

signing_arguments=(--entitlements "${PROJECT_ROOT}/Resources/Sandbox.entitlements")

plutil -lint "${CONTENTS_PATH}/Info.plist"
codesign \
    --force \
    --options runtime \
    --timestamp \
    --sign "${SIGNING_IDENTITY}" \
    "${signing_arguments[@]}" \
    "${STAGED_APP_PATH}"
codesign --verify --strict --verbose=2 "${STAGED_APP_PATH}"

mkdir -p "${BUILD_ROOT}"
if ! mkdir "${PUBLISH_LOCK}" 2>/dev/null; then
    print -u2 "Another build is publishing Boundless Translator."
    exit 1
fi
publish_lock_acquired=true

if [[ -e "${APP_PATH}" ]]; then
    "${MV_EXECUTABLE}" "${APP_PATH}" "${PREVIOUS_APP_PATH}"
fi

if ! "${MV_EXECUTABLE}" "${STAGED_APP_PATH}" "${APP_PATH}"; then
    if [[ -e "${PREVIOUS_APP_PATH}" ]]; then
        if ! "${MV_EXECUTABLE}" "${PREVIOUS_APP_PATH}" "${APP_PATH}"; then
            rollback_failed=true
        fi
    fi
    exit 1
fi

rm -rf "${PREVIOUS_APP_PATH}"

print "Built ${APP_PATH}"
