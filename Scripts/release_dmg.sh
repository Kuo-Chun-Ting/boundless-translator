#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h}"
readonly BUILD_DMG_EXECUTABLE="${BOUNDLESS_TRANSLATOR_BUILD_DMG_EXECUTABLE:-${PROJECT_ROOT}/Scripts/Tools/build_dmg.sh}"
readonly NOTARIZE_EXECUTABLE="${BOUNDLESS_TRANSLATOR_NOTARIZE_EXECUTABLE:-${PROJECT_ROOT}/Scripts/Tools/notarize_dmg.sh}"
readonly MV_EXECUTABLE="${BOUNDLESS_TRANSLATOR_MV_EXECUTABLE:-mv}"
readonly INFO_PLIST="${BOUNDLESS_TRANSLATOR_INFO_PLIST:-${PROJECT_ROOT}/Resources/Info.plist}"
readonly BUILD_ROOT="${BOUNDLESS_TRANSLATOR_RELEASE_BUILD_ROOT:-${PROJECT_ROOT}/Build}"

if [[ "$#" -ne 1 ]] || [[ "$1" != --test && ! "$1" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]]; then
    print -u2 "Usage: release_dmg.sh <version>|--test"
    print -u2 "Example: Scripts/release_dmg.sh 0.2.0"
    exit 1
fi

if [[ "$1" == --test ]]; then
    mkdir -p "${BUILD_ROOT}"
    readonly TEMP_ROOT="$(mktemp -d "${BUILD_ROOT}/.boundless-translator-test.XXXXXX")"
    trap 'rm -rf "${TEMP_ROOT}"' EXIT
    readonly TEST_DMG_PATH="${BUILD_ROOT}/Boundless Translator-test.dmg"
    readonly STAGED_INFO_PLIST="${TEMP_ROOT}/Info.plist"
    cp "${INFO_PLIST}" "${STAGED_INFO_PLIST}"
    BOUNDLESS_TRANSLATOR_BUILD_INFO_PLIST="${STAGED_INFO_PLIST}" \
        "${BUILD_DMG_EXECUTABLE}" "${TEMP_ROOT}/Boundless Translator-test.dmg"
    "${MV_EXECUTABLE}" -f "${TEMP_ROOT}/Boundless Translator-test.dmg" "${TEST_DMG_PATH}"
    print "Test DMG ready (no subscription, not notarized): ${TEST_DMG_PATH}"
    exit 0
fi

readonly VERSION="$1"
mkdir -p "${BUILD_ROOT}"
readonly RELEASE_LOCK="${BUILD_ROOT}/.release-lock"
if ! mkdir "${RELEASE_LOCK}" 2>/dev/null; then
    print -u2 'Another DMG release is in progress.'
    exit 1
fi
release_lock_acquired=true
temp_root=''
rollback_info_plist=''
publish_info_plist=''
source_published=false
release_succeeded=false
rollback_failed=false

function clean_up {
    if [[ "${source_published}" == true && "${release_succeeded}" != true && -f "${rollback_info_plist}" ]]; then
        if ! "${MV_EXECUTABLE}" -f "${rollback_info_plist}" "${INFO_PLIST}"; then
            rollback_failed=true
            print -u2 "Source metadata rollback failed. Recovery copy remains at: ${rollback_info_plist}"
        fi
    fi
    if [[ "${release_lock_acquired}" == true ]]; then
        rmdir "${RELEASE_LOCK}" 2>/dev/null || true
    fi
    [[ -z "${temp_root}" ]] || rm -rf "${temp_root}"
    if [[ "${rollback_failed}" != true && -n "${rollback_info_plist}" && -e "${rollback_info_plist}" ]]; then
        rm -f "${rollback_info_plist}"
    fi
    [[ -z "${publish_info_plist}" || ! -e "${publish_info_plist}" ]] || rm -f "${publish_info_plist}"
}
trap clean_up EXIT

temp_root="$(mktemp -d "${BUILD_ROOT}/.boundless-translator-release.XXXXXX")"
readonly TEMP_ROOT="${temp_root}"
readonly ORIGINAL_INFO_PLIST="${TEMP_ROOT}/OriginalInfo.plist"
readonly STAGED_INFO_PLIST="${TEMP_ROOT}/Info.plist"
cp "${INFO_PLIST}" "${ORIGINAL_INFO_PLIST}"
cp "${INFO_PLIST}" "${STAGED_INFO_PLIST}"

readonly CURRENT_BUILD="$(plutil -extract CFBundleVersion raw "${STAGED_INFO_PLIST}")"
if [[ ! "${CURRENT_BUILD}" =~ '^[0-9]+$' ]]; then
    print -u2 "CFBundleVersion must be an integer: ${CURRENT_BUILD}"
    exit 1
fi

readonly NEXT_BUILD="$((CURRENT_BUILD + 1))"
readonly RELEASE_DMG_PATH="${BUILD_ROOT}/Boundless Translator-${VERSION}.dmg"
readonly TEMP_DMG_PATH="${TEMP_ROOT}/Boundless Translator-${VERSION}.dmg"

plutil -replace CFBundleShortVersionString -string "${VERSION}" "${STAGED_INFO_PLIST}"
plutil -replace CFBundleVersion -string "${NEXT_BUILD}" "${STAGED_INFO_PLIST}"

BOUNDLESS_TRANSLATOR_BUILD_INFO_PLIST="${STAGED_INFO_PLIST}" \
    "${BUILD_DMG_EXECUTABLE}" "${TEMP_DMG_PATH}"
"${NOTARIZE_EXECUTABLE}" "${TEMP_DMG_PATH}"
rollback_info_plist="$(mktemp "${INFO_PLIST:h}/.boundless-translator-info-rollback.XXXXXX")"
cp "${ORIGINAL_INFO_PLIST}" "${rollback_info_plist}"
publish_info_plist="$(mktemp "${INFO_PLIST:h}/.boundless-translator-info-publish.XXXXXX")"
cp "${STAGED_INFO_PLIST}" "${publish_info_plist}"
source_published=true
"${MV_EXECUTABLE}" -f "${publish_info_plist}" "${INFO_PLIST}"
"${MV_EXECUTABLE}" -f "${TEMP_DMG_PATH}" "${RELEASE_DMG_PATH}"
release_succeeded=true

print "Release ready: ${RELEASE_DMG_PATH}"
