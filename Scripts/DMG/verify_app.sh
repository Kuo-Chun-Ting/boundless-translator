#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"
readonly BUNDLE_IDENTIFIER="${BOUNDLESS_TRANSLATOR_BUNDLE_IDENTIFIER:-com.lillard.BoundlessTranslator}"
readonly EXPECTED_TEAM_ID="${BOUNDLESS_TRANSLATOR_TEAM_ID:-3S9ZKKJ6PW}"
readonly EXPECTED_MINIMUM_OS_VERSION="15.0"
readonly EXPECTED_PRIVACY_MANIFEST="${PROJECT_ROOT}/Resources/PrivacyInfo.xcprivacy"
readonly EXPECTED_LOCALIZATIONS_ROOT="${PROJECT_ROOT}/Sources/BoundlessTranslator/Resources"
readonly APP_LAUNCH_WAIT_SECONDS="${BOUNDLESS_TRANSLATOR_APP_LAUNCH_WAIT_SECONDS:-2}"

function fail {
    print -u2 "$1"
    exit 1
}

function require_path {
    local path="$1"
    local description="$2"
    [[ -e "${path}" ]] || fail "${description} is missing: ${path}"
}

function verify_signature {
    local app_path="$1"
    local signing_requirement
    signing_requirement="identifier \"${BUNDLE_IDENTIFIER}\" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] exists and certificate leaf[field.1.2.840.113635.100.6.1.13] exists and certificate leaf[subject.OU] = \"${EXPECTED_TEAM_ID}\""

    codesign --verify --deep --strict --verbose=2 -R="${signing_requirement}" "${app_path}"

    local signature_details
    signature_details="$(codesign --display --verbose=4 "${app_path}" 2>&1)"
    [[ "${signature_details}" == *"flags=0x10000(runtime)"* ]] ||
        fail "App signature does not enable Hardened Runtime."
    [[ "${signature_details}" == *"Timestamp="* ]] ||
        fail "App signature does not include a secure timestamp."

    local entitlements
    entitlements="$(codesign --display --entitlements - --xml "${app_path}" 2>/dev/null)"
    [[ "$(print -r -- "${entitlements}" | /usr/bin/xmllint --xpath \
        'boolean(/plist/dict/key[.="com.apple.security.app-sandbox"]/following-sibling::*[1][self::true])' -)" == true ]] ||
        fail "App signature does not enable App Sandbox."
    [[ "$(print -r -- "${entitlements}" | /usr/bin/xmllint --xpath \
        'boolean(/plist/dict/key[.="com.apple.security.network.client"]/following-sibling::*[1][self::true])' -)" == true ]] ||
        fail "App signature does not allow outgoing network access."
}

function verify_bundle_contents {
    local app_path="$1"
    local resources_path="${app_path}/Contents/Resources"
    local info_plist="${app_path}/Contents/Info.plist"
    local privacy_manifest="${resources_path}/PrivacyInfo.xcprivacy"

    require_path "${info_plist}" "App Info.plist"
    require_path "${privacy_manifest}" "Privacy manifest"
    require_path "${resources_path}/en.lproj" "English localization"
    require_path "${resources_path}/zh-Hant.lproj" "Traditional Chinese localization"

    plutil -lint "${info_plist}" >/dev/null
    plutil -lint "${privacy_manifest}" >/dev/null
    cmp "${EXPECTED_PRIVACY_MANIFEST}" "${privacy_manifest}"

    local expected_localizations
    local actual_localizations
    expected_localizations="$(find "${EXPECTED_LOCALIZATIONS_ROOT}" -mindepth 1 -maxdepth 1 -type d -name '*.lproj' -exec basename {} \; | LC_ALL=C sort)"
    actual_localizations="$(find "${resources_path}" -mindepth 1 -maxdepth 1 -type d -name '*.lproj' -exec basename {} \; | LC_ALL=C sort)"
    [[ "${actual_localizations}" == "${expected_localizations}" ]] ||
        fail "App localizations do not match the source localizations."
    [[ "$(plutil -extract LSMinimumSystemVersion raw "${info_plist}")" == "${EXPECTED_MINIMUM_OS_VERSION}" ]] ||
        fail "App Info.plist has the wrong minimum macOS version."
}

function verify_executable {
    local executable="$1"
    require_path "${executable}" "App executable"
    [[ -x "${executable}" ]] || fail "App executable is not executable: ${executable}"

    [[ "$(vtool -show-build "${executable}")" == *"minos ${EXPECTED_MINIMUM_OS_VERSION}"* ]] ||
        fail "App executable has the wrong minimum macOS version."

    local dependencies
    dependencies="$(otool -L "${executable}")"
    [[ "${dependencies}" == *"/System/Library/Frameworks/Translation.framework/"* ]] ||
        fail "App executable is missing Translation.framework."
    [[ "${dependencies}" == *"/System/Library/Frameworks/VisionKit.framework/"* ]] ||
        fail "App executable is missing VisionKit.framework."
    [[ "${dependencies}" != *"@rpath"* && "${dependencies}" != *"@loader_path"* && "${dependencies}" != *"@executable_path"* ]] ||
        fail "App executable contains unresolved relative library paths."
}

function verify_launch {
    setopt local_options no_bg_nice
    local executable="$1"
    local output_path
    output_path="$(mktemp /private/tmp/boundless-translator-launch.XXXXXX)"

    "${executable}" >"${output_path}" 2>&1 &
    local app_pid=$!
    sleep "${APP_LAUNCH_WAIT_SECONDS}"
    if ! kill -0 "${app_pid}" >/dev/null 2>&1; then
        cat "${output_path}" >&2
        rm -f "${output_path}"
        fail "App exited immediately after launch."
    fi
    kill "${app_pid}" >/dev/null 2>&1 || true
    wait "${app_pid}" >/dev/null 2>&1 || true
    rm -f "${output_path}"
}

[[ "$#" -eq 1 ]] || fail "Usage: verify_app.sh <app-path>"
readonly APP_PATH="$1"

[[ -d "${APP_PATH}" ]] || fail "App does not exist: ${APP_PATH}"
verify_signature "${APP_PATH}"
verify_bundle_contents "${APP_PATH}"
readonly EXECUTABLE_NAME="$(plutil -extract CFBundleExecutable raw "${APP_PATH}/Contents/Info.plist")"
readonly EXECUTABLE="${APP_PATH}/Contents/MacOS/${EXECUTABLE_NAME}"
verify_executable "${EXECUTABLE}"
verify_launch "${EXECUTABLE}"
