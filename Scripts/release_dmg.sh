#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h}"
readonly BUILD_DMG_EXECUTABLE="${BOUNDLESS_TRANSLATOR_BUILD_DMG_EXECUTABLE:-${PROJECT_ROOT}/Scripts/Tools/build_dmg.sh}"
readonly NOTARIZE_EXECUTABLE="${BOUNDLESS_TRANSLATOR_NOTARIZE_EXECUTABLE:-${PROJECT_ROOT}/Scripts/Tools/notarize_dmg.sh}"
readonly INFO_PLIST="${BOUNDLESS_TRANSLATOR_INFO_PLIST:-${PROJECT_ROOT}/Resources/Info.plist}"
readonly BUILD_ROOT="${BOUNDLESS_TRANSLATOR_RELEASE_BUILD_ROOT:-${PROJECT_ROOT}/Build}"

if [[ "$#" -ne 1 || ! "$1" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]]; then
    print -u2 "Usage: release_dmg.sh <version>"
    print -u2 "Example: Scripts/release_dmg.sh 0.2.0"
    exit 1
fi

readonly VERSION="$1"
readonly CURRENT_BUILD="$(plutil -extract CFBundleVersion raw "${INFO_PLIST}")"

if [[ ! "${CURRENT_BUILD}" =~ '^[0-9]+$' ]]; then
    print -u2 "CFBundleVersion must be an integer: ${CURRENT_BUILD}"
    exit 1
fi

readonly NEXT_BUILD="$((CURRENT_BUILD + 1))"
readonly RELEASE_DMG_PATH="${BUILD_ROOT}/Boundless Translator-${VERSION}.dmg"
readonly ORIGINAL_INFO_PLIST="$(mktemp /private/tmp/boundless-translator-info-plist.XXXXXX)"
cp "${INFO_PLIST}" "${ORIGINAL_INFO_PLIST}"
mkdir -p "${BUILD_ROOT}"
readonly TEMP_ROOT="$(mktemp -d "${BUILD_ROOT}/.boundless-translator-release.XXXXXX")"
readonly TEMP_DMG_PATH="${TEMP_ROOT}/Boundless Translator-${VERSION}.dmg"
release_succeeded=false

function clean_up {
    if [[ "${release_succeeded}" != true ]]; then
        cp "${ORIGINAL_INFO_PLIST}" "${INFO_PLIST}"
    fi
    rm -rf "${TEMP_ROOT}"
    rm -f "${ORIGINAL_INFO_PLIST}"
}
trap clean_up EXIT

plutil -replace CFBundleShortVersionString -string "${VERSION}" "${INFO_PLIST}"
plutil -replace CFBundleVersion -string "${NEXT_BUILD}" "${INFO_PLIST}"

"${BUILD_DMG_EXECUTABLE}" "${TEMP_DMG_PATH}"
"${NOTARIZE_EXECUTABLE}" "${TEMP_DMG_PATH}"
mv -f "${TEMP_DMG_PATH}" "${RELEASE_DMG_PATH}"
release_succeeded=true

print "Release ready: ${RELEASE_DMG_PATH}"
