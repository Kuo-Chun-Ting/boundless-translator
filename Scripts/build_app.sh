#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h}"
readonly BUILD_ROOT="${PROJECT_ROOT}/Build"
readonly APP_PATH="${BUILD_ROOT}/Whisper Translate.app"
readonly DEVELOPER_PATH="/Applications/Xcode.app/Contents/Developer"
readonly SIGNING_IDENTITY="${WHISPER_TRANSLATE_SIGNING_IDENTITY:-Whisper Translate Local Development}"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/whisper-translate-build.XXXXXX)"
readonly SCRATCH_PATH="${TEMP_ROOT}/spm"
readonly STAGED_APP_PATH="${TEMP_ROOT}/Whisper Translate.app"
readonly CONTENTS_PATH="${STAGED_APP_PATH}/Contents"
readonly MACOS_PATH="${CONTENTS_PATH}/MacOS"
readonly PREVIOUS_APP_PATH="${TEMP_ROOT}/Previous Whisper Translate.app"
readonly PUBLISH_LOCK="${BUILD_ROOT}/.publish-lock"
publish_lock_acquired=false

function clean_up {
    if [[ "${publish_lock_acquired}" == true ]]; then
        rmdir "${PUBLISH_LOCK}" 2>/dev/null || true
    fi
    rm -rf "${TEMP_ROOT}"
}
trap clean_up EXIT

mkdir -p "${MACOS_PATH}"

CLANG_MODULE_CACHE_PATH="${TEMP_ROOT}/clang-cache" \
SWIFTPM_MODULECACHE_OVERRIDE="${TEMP_ROOT}/module-cache" \
DEVELOPER_DIR="${DEVELOPER_PATH}" \
swift build \
    --configuration release \
    --disable-sandbox \
    --package-path "${PROJECT_ROOT}" \
    --scratch-path "${SCRATCH_PATH}" \
    --cache-path "${TEMP_ROOT}/cache" \
    --config-path "${TEMP_ROOT}/config" \
    --security-path "${TEMP_ROOT}/security"

cp "${SCRATCH_PATH}/release/WhisperTranslate" "${MACOS_PATH}/WhisperTranslate"
cp "${PROJECT_ROOT}/Resources/Info.plist" "${CONTENTS_PATH}/Info.plist"

plutil -lint "${CONTENTS_PATH}/Info.plist"
codesign \
    --force \
    --options runtime \
    --sign "${SIGNING_IDENTITY}" \
    "${STAGED_APP_PATH}"

mkdir -p "${BUILD_ROOT}"
if ! mkdir "${PUBLISH_LOCK}" 2>/dev/null; then
    print -u2 "Another build is publishing Whisper Translate."
    exit 1
fi
publish_lock_acquired=true

if [[ -e "${APP_PATH}" ]]; then
    mv "${APP_PATH}" "${PREVIOUS_APP_PATH}"
fi

if ! mv "${STAGED_APP_PATH}" "${APP_PATH}"; then
    if [[ -e "${PREVIOUS_APP_PATH}" ]]; then
        mv "${PREVIOUS_APP_PATH}" "${APP_PATH}"
    fi
    exit 1
fi

rm -rf "${PREVIOUS_APP_PATH}"

print "Built ${APP_PATH}"
