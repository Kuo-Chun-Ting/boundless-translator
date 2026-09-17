#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h}"
readonly XCODE_PROJECT="${PROJECT_ROOT}/BoundlessTranslator.xcodeproj"
readonly XCODEBUILD_EXECUTABLE="${BOUNDLESS_TRANSLATOR_XCODEBUILD_EXECUTABLE:-xcodebuild}"
readonly PKGUTIL_EXECUTABLE="${BOUNDLESS_TRANSLATOR_PKGUTIL_EXECUTABLE:-pkgutil}"
readonly CODESIGN_EXECUTABLE="${BOUNDLESS_TRANSLATOR_CODESIGN_EXECUTABLE:-codesign}"
readonly LIPO_EXECUTABLE="${BOUNDLESS_TRANSLATOR_LIPO_EXECUTABLE:-lipo}"
readonly OTOOL_EXECUTABLE="${BOUNDLESS_TRANSLATOR_OTOOL_EXECUTABLE:-otool}"
readonly MV_EXECUTABLE="${BOUNDLESS_TRANSLATOR_MV_EXECUTABLE:-mv}"
readonly RELEASE_ROOT="${BOUNDLESS_TRANSLATOR_APP_STORE_RELEASE_ROOT:-${PROJECT_ROOT}/Build/AppStore}"
readonly EXPECTED_PRIVACY_MANIFEST="${PROJECT_ROOT}/Resources/PrivacyInfo.xcprivacy"
readonly EXPECTED_LOCALIZATIONS_ROOT="${PROJECT_ROOT}/Sources/BoundlessTranslator/Resources"
readonly EXPECTED_BUNDLE_IDENTIFIER="com.lillard.BoundlessTranslator"
readonly EXPECTED_MINIMUM_OS_VERSION="15.0"

function fail {
    print -u2 "$1"
    exit 1
}

function require_value {
    local variable_name="$1"
    [[ -n "${(P)variable_name:-}" ]] || fail "${variable_name} is required."
}

function require_path {
    local path="$1"
    local description="$2"
    [[ -e "${path}" ]] || fail "${description} is missing: ${path}"
}

function require_plist_value {
    local plist_path="$1"
    local key="$2"
    local expected_value="$3"
    local actual_value
    actual_value="$(plutil -extract "${key}" raw "${plist_path}")"
    [[ "${actual_value}" == "${expected_value}" ]] ||
        fail "Archived App has the wrong ${key}: ${actual_value}"
}

function archive_app {
    "${XCODEBUILD_EXECUTABLE}" archive \
        -project "${XCODE_PROJECT}" \
        -scheme BoundlessTranslator-AppStore \
        -configuration AppStoreRelease \
        -destination 'generic/platform=macOS' \
        -derivedDataPath "${TEMP_ROOT}/DerivedData" \
        -archivePath "${STAGED_ARCHIVE_PATH}" \
        "MARKETING_VERSION=${VERSION}" \
        "CURRENT_PROJECT_VERSION=${BUILD_NUMBER}" \
        'CODE_SIGN_STYLE=Automatic' \
        "DEVELOPMENT_TEAM=${BOUNDLESS_TRANSLATOR_APP_STORE_TEAM_ID}" \
        "BOUNDLESS_TRANSLATOR_APP_STORE_TEAM_ID=${BOUNDLESS_TRANSLATOR_APP_STORE_TEAM_ID}" \
        "BOUNDLESS_TRANSLATOR_SUBSCRIPTION_PRODUCT_ID=${BOUNDLESS_TRANSLATOR_SUBSCRIPTION_PRODUCT_ID}" \
        "BOUNDLESS_TRANSLATOR_PRIVACY_POLICY_URL=${BOUNDLESS_TRANSLATOR_PRIVACY_POLICY_URL}" \
        "BOUNDLESS_TRANSLATOR_APP_STORE_COPYRIGHT=${BOUNDLESS_TRANSLATOR_APP_STORE_COPYRIGHT}" \
        -allowProvisioningUpdates
}

function create_export_options {
    plutil -create xml1 "${EXPORT_OPTIONS}"
    plutil -insert method -string app-store-connect "${EXPORT_OPTIONS}"
    plutil -insert destination -string export "${EXPORT_OPTIONS}"
    plutil -insert signingStyle -string automatic "${EXPORT_OPTIONS}"
    plutil -insert teamID -string "${BOUNDLESS_TRANSLATOR_APP_STORE_TEAM_ID}" "${EXPORT_OPTIONS}"
    plutil -insert manageAppVersionAndBuildNumber -bool false "${EXPORT_OPTIONS}"
}

function export_package {
    "${XCODEBUILD_EXECUTABLE}" -exportArchive \
        -archivePath "${STAGED_ARCHIVE_PATH}" \
        -exportOptionsPlist "${EXPORT_OPTIONS}" \
        -exportPath "${EXPORT_ROOT}" \
        -allowProvisioningUpdates
}

function verify_archive_signature {
    local app_path="$1"

    "${CODESIGN_EXECUTABLE}" --verify --deep --strict --verbose=2 "${app_path}"
    local signature_details
    signature_details="$("${CODESIGN_EXECUTABLE}" --display --verbose=4 "${app_path}" 2>&1)"
    [[ "${signature_details}" == *"TeamIdentifier=${BOUNDLESS_TRANSLATOR_APP_STORE_TEAM_ID}"* ]] ||
        fail "Archived App signature has the wrong Team ID."

    local entitlements
    entitlements="$("${CODESIGN_EXECUTABLE}" --display --entitlements - --xml "${app_path}" 2>/dev/null)"
    [[ "$(print -r -- "${entitlements}" | /usr/bin/xmllint --xpath \
        'boolean(/plist/dict/key[.="com.apple.security.app-sandbox"]/following-sibling::*[1][self::true])' -)" == true ]] ||
        fail "Archived App does not enable App Sandbox."
    [[ "$(print -r -- "${entitlements}" | /usr/bin/xmllint --xpath \
        'boolean(/plist/dict/key[.="com.apple.security.network.client"]/following-sibling::*[1][self::true])' -)" == true ]] ||
        fail "Archived App does not allow outgoing network access."
}

function verify_archive_contents {
    local app_path="$1"
    local info_plist="${app_path}/Contents/Info.plist"
    local resources_path="${app_path}/Contents/Resources"
    local executable="${app_path}/Contents/MacOS/BoundlessTranslator"
    local privacy_manifest="${resources_path}/PrivacyInfo.xcprivacy"

    require_path "${executable}" "Archived App executable"
    require_path "${resources_path}/AppIcon.icns" "Archived App icon"
    require_path "${privacy_manifest}" "Archived App privacy manifest"
    require_path "${resources_path}/en.lproj" "Archived App English localization"
    require_path "${resources_path}/zh-Hant.lproj" "Archived App Traditional Chinese localization"
    plutil -lint "${info_plist}" >/dev/null
    plutil -lint "${privacy_manifest}" >/dev/null
    cmp "${EXPECTED_PRIVACY_MANIFEST}" "${privacy_manifest}"

    require_plist_value "${info_plist}" CFBundleIdentifier "${EXPECTED_BUNDLE_IDENTIFIER}"
    require_plist_value "${info_plist}" CFBundleShortVersionString "${VERSION}"
    require_plist_value "${info_plist}" CFBundleVersion "${BUILD_NUMBER}"
    require_plist_value "${info_plist}" BoundlessSubscriptionProductID "${BOUNDLESS_TRANSLATOR_SUBSCRIPTION_PRODUCT_ID}"
    require_plist_value "${info_plist}" BoundlessPrivacyPolicyURL "${BOUNDLESS_TRANSLATOR_PRIVACY_POLICY_URL}"
    require_plist_value "${info_plist}" NSHumanReadableCopyright "${BOUNDLESS_TRANSLATOR_APP_STORE_COPYRIGHT}"
    require_plist_value "${info_plist}" LSApplicationCategoryType public.app-category.productivity
    require_plist_value "${info_plist}" ITSAppUsesNonExemptEncryption false
    require_plist_value "${info_plist}" LSMinimumSystemVersion "${EXPECTED_MINIMUM_OS_VERSION}"

    local expected_localizations
    local actual_localizations
    expected_localizations="$(find "${EXPECTED_LOCALIZATIONS_ROOT}" -mindepth 1 -maxdepth 1 -type d -name '*.lproj' -exec basename {} \; | LC_ALL=C sort)"
    actual_localizations="$(find "${resources_path}" -mindepth 1 -maxdepth 1 -type d -name '*.lproj' -exec basename {} \; | LC_ALL=C sort)"
    [[ "${actual_localizations}" == "${expected_localizations}" ]] ||
        fail "Archived App localizations do not match the source localizations."
    [[ "$("${LIPO_EXECUTABLE}" -archs "${executable}")" == arm64 ]] ||
        fail "Archived App is not arm64-only."

    local dependencies
    dependencies="$("${OTOOL_EXECUTABLE}" -L "${executable}")"
    [[ "${dependencies}" == *"/System/Library/Frameworks/Translation.framework/"* ]] ||
        fail "Archived App is missing Translation.framework."
    [[ "${dependencies}" == *"/System/Library/Frameworks/VisionKit.framework/"* ]] ||
        fail "Archived App is missing VisionKit.framework."
}

function verify_archived_app {
    local app_path="$1"
    [[ "$(xattr -r "${app_path}")" != *com.apple.quarantine* ]] ||
        fail "Archived App contains quarantine attributes."
    verify_archive_signature "${app_path}"
    verify_archive_contents "${app_path}"
}

if [[ "$#" -ne 2 ]]; then
    fail 'Usage: release_app_store.sh <version> <build-number>'
fi

readonly VERSION="$1"
readonly BUILD_NUMBER="$2"
[[ "${VERSION}" =~ '^[0-9]+\.[0-9]+(\.[0-9]+)?$' ]] || fail 'Version must use major.minor or major.minor.patch.'
[[ "${BUILD_NUMBER}" =~ '^[1-9][0-9]*$' ]] || fail 'Build number must be a positive integer.'
require_value BOUNDLESS_TRANSLATOR_APP_STORE_TEAM_ID
require_value BOUNDLESS_TRANSLATOR_SUBSCRIPTION_PRODUCT_ID
require_value BOUNDLESS_TRANSLATOR_PRIVACY_POLICY_URL
require_value BOUNDLESS_TRANSLATOR_APP_STORE_COPYRIGHT
[[ "${BOUNDLESS_TRANSLATOR_SUBSCRIPTION_PRODUCT_ID}" != *[[:space:]]* ]] || fail 'Subscription product ID must not contain whitespace.'
[[ "${BOUNDLESS_TRANSLATOR_PRIVACY_POLICY_URL}" =~ '^https://[^[:space:]/?#]+([/?#][^[:space:]]*)?$' ]] || fail 'Privacy policy URL must use HTTPS and include a host.'

readonly ARCHIVE_PATH="${RELEASE_ROOT}/BoundlessTranslator-${VERSION}-${BUILD_NUMBER}.xcarchive"
readonly PACKAGE_PATH="${RELEASE_ROOT}/BoundlessTranslator-${VERSION}-${BUILD_NUMBER}.pkg"
mkdir -p "${RELEASE_ROOT}"
[[ ! -e "${ARCHIVE_PATH}" && ! -e "${PACKAGE_PATH}" ]] || fail "App Store build ${VERSION} (${BUILD_NUMBER}) already exists."
readonly PUBLISH_LOCK="${RELEASE_ROOT}/.publish-lock"
mkdir "${PUBLISH_LOCK}" 2>/dev/null || fail 'Another App Store release is already running.'
trap 'rmdir "${PUBLISH_LOCK}" 2>/dev/null || true' EXIT
[[ ! -e "${ARCHIVE_PATH}" && ! -e "${PACKAGE_PATH}" ]] || fail "App Store build ${VERSION} (${BUILD_NUMBER}) already exists."

readonly TEMP_ROOT="$(mktemp -d "${RELEASE_ROOT}/.boundless-translator-app-store-release.XXXXXX")"
readonly STAGED_ARCHIVE_PATH="${TEMP_ROOT}/BoundlessTranslator.xcarchive"
readonly EXPORT_ROOT="${TEMP_ROOT}/Export"
readonly EXPORT_OPTIONS="${TEMP_ROOT}/ExportOptions.plist"
function clean_up {
    rm -rf "${TEMP_ROOT}"
    rmdir "${PUBLISH_LOCK}" 2>/dev/null || true
}
function stop_release {
    local exit_code="$1"
    clean_up
    trap - EXIT INT TERM
    exit "${exit_code}"
}
trap clean_up EXIT
trap 'stop_release 130' INT
trap 'stop_release 143' TERM

archive_app
readonly ARCHIVED_APP_PATH="${STAGED_ARCHIVE_PATH}/Products/Applications/Boundless Translator.app"
[[ -d "${ARCHIVED_APP_PATH}" ]] || fail "Xcode archive is missing the App: ${ARCHIVED_APP_PATH}"
verify_archived_app "${ARCHIVED_APP_PATH}"

create_export_options
export_package
exported_packages=("${EXPORT_ROOT}"/*.pkg(N))
[[ "${#exported_packages}" == 1 ]] || fail "Expected one exported PKG, found ${#exported_packages}."
readonly STAGED_PACKAGE_PATH="${exported_packages[1]}"
"${PKGUTIL_EXECUTABLE}" --check-signature "${STAGED_PACKAGE_PATH}"

"${MV_EXECUTABLE}" "${STAGED_ARCHIVE_PATH}" "${ARCHIVE_PATH}"
if ! "${MV_EXECUTABLE}" "${STAGED_PACKAGE_PATH}" "${PACKAGE_PATH}"; then
    rm -rf "${ARCHIVE_PATH}"
    fail "Could not publish the App Store package."
fi
print "App Store archive ready: ${ARCHIVE_PATH}"
print "App Store package ready: ${PACKAGE_PATH}"
