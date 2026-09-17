#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly RELEASER="${PROJECT_ROOT}/Scripts/release_app_store.sh"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-app-store-release-tests.XXXXXX)"
readonly RELEASE_ROOT="${TEMP_ROOT}/Build/AppStore"
readonly CALL_LOG="${TEMP_ROOT}/calls.log"
readonly XCODEBUILD_STUB="${TEMP_ROOT}/xcodebuild"
readonly PKGUTIL_STUB="${TEMP_ROOT}/pkgutil"
readonly CODESIGN_STUB="${TEMP_ROOT}/codesign"
readonly LIPO_STUB="${TEMP_ROOT}/lipo"
readonly OTOOL_STUB="${TEMP_ROOT}/otool"
readonly MV_STUB="${TEMP_ROOT}/mv"
trap 'rm -rf "${TEMP_ROOT}"' EXIT

cat > "${XCODEBUILD_STUB}" <<'STUB'
#!/bin/zsh
set -eu

operation="$1"
print -r -- "${operation} $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
if [[ "${TEST_SIGNAL_STEP:-}" == "${operation}" ]]; then
    kill -TERM "${PPID}"
    exit 143
fi
[[ "${TEST_FAIL_STEP:-}" != "${operation}" ]]

archive_path=''
options_path=''
export_path=''
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -archivePath) archive_path="$2"; shift 2 ;;
        -exportOptionsPlist) options_path="$2"; shift 2 ;;
        -exportPath) export_path="$2"; shift 2 ;;
        *) shift ;;
    esac
done

case "${operation}" in
    archive)
        app_path="${archive_path}/Products/Applications/Boundless Translator.app"
        resources_path="${app_path}/Contents/Resources"
        mkdir -p "${app_path}/Contents/MacOS"
        for localization_path in "${BOUNDLESS_TRANSLATOR_TEST_LOCALIZATIONS_ROOT}"/*.lproj; do
            mkdir -p "${resources_path}/${localization_path:t}"
        done
        print app > "${app_path}/Contents/MacOS/BoundlessTranslator"
        chmod +x "${app_path}/Contents/MacOS/BoundlessTranslator"
        touch "${resources_path}/AppIcon.icns"
        cp "${BOUNDLESS_TRANSLATOR_TEST_PRIVACY_MANIFEST}" "${resources_path}/PrivacyInfo.xcprivacy"
        info_path="${app_path}/Contents/Info.plist"
        plutil -create xml1 "${info_path}"
        plutil -insert CFBundleIdentifier -string com.lillard.BoundlessTranslator "${info_path}"
        plutil -insert CFBundleShortVersionString -string 1.2.3 "${info_path}"
        plutil -insert CFBundleVersion -string 42 "${info_path}"
        plutil -insert LSMinimumSystemVersion -string 15.0 "${info_path}"
        plutil -insert LSApplicationCategoryType -string public.app-category.productivity "${info_path}"
        plutil -insert ITSAppUsesNonExemptEncryption -bool false "${info_path}"
        plutil -insert BoundlessSubscriptionProductID -string "${TEST_ARCHIVE_PRODUCT_ID:-${BOUNDLESS_TRANSLATOR_SUBSCRIPTION_PRODUCT_ID}}" "${info_path}"
        plutil -insert BoundlessPrivacyPolicyURL -string "${BOUNDLESS_TRANSLATOR_PRIVACY_POLICY_URL}" "${info_path}"
        plutil -insert NSHumanReadableCopyright -string "${BOUNDLESS_TRANSLATOR_APP_STORE_COPYRIGHT}" "${info_path}"
        ;;
    -exportArchive)
        [[ -d "${archive_path}" ]]
        [[ "$(plutil -extract method raw "${options_path}")" == app-store-connect ]]
        [[ "$(plutil -extract destination raw "${options_path}")" == export ]]
        [[ "$(plutil -extract manageAppVersionAndBuildNumber raw "${options_path}")" == false ]]
        mkdir -p "${export_path}"
        print package > "${export_path}/Boundless Translator.pkg"
        ;;
    *)
        exit 1
        ;;
esac
STUB

cat > "${PKGUTIL_STUB}" <<'STUB'
#!/bin/zsh
set -eu
print -r -- "pkgutil $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
[[ "${TEST_FAIL_STEP:-}" != verify ]]
STUB

cat > "${CODESIGN_STUB}" <<'STUB'
#!/bin/zsh
set -eu
print -r -- "codesign $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
if [[ "$*" == *--entitlements* ]]; then
    sandbox_value='<true/>'
    [[ "${TEST_ARCHIVE_SANDBOX_ENABLED:-true}" == true ]] || sandbox_value='<false/>'
    print "<plist version=\"1.0\"><dict><key>com.apple.security.app-sandbox</key>${sandbox_value}<key>com.apple.security.network.client</key><true/></dict></plist>"
elif [[ "$*" == *--display* ]]; then
    print 'TeamIdentifier=ABCDE12345'
fi
STUB

cat > "${LIPO_STUB}" <<'STUB'
#!/bin/zsh
set -eu
print "${TEST_ARCHIVE_ARCHITECTURES:-arm64}"
STUB

cat > "${OTOOL_STUB}" <<'STUB'
#!/bin/zsh
set -eu
print "$2:"
print '/System/Library/Frameworks/Translation.framework/Versions/A/Translation'
print '/System/Library/Frameworks/VisionKit.framework/Versions/A/VisionKit'
STUB

cat > "${MV_STUB}" <<'STUB'
#!/bin/zsh
set -eu
if [[ "${TEST_FAIL_PACKAGE_PUBLISH:-false}" == true && "$2" == *.pkg ]]; then
    exit 1
fi
exec /bin/mv "$@"
STUB
chmod +x "${XCODEBUILD_STUB}" "${PKGUTIL_STUB}" "${CODESIGN_STUB}" "${LIPO_STUB}" "${OTOOL_STUB}" "${MV_STUB}"

function run_releaser {
    BOUNDLESS_TRANSLATOR_XCODEBUILD_EXECUTABLE="${XCODEBUILD_STUB}" \
    BOUNDLESS_TRANSLATOR_PKGUTIL_EXECUTABLE="${PKGUTIL_STUB}" \
    BOUNDLESS_TRANSLATOR_CODESIGN_EXECUTABLE="${CODESIGN_STUB}" \
    BOUNDLESS_TRANSLATOR_LIPO_EXECUTABLE="${LIPO_STUB}" \
    BOUNDLESS_TRANSLATOR_OTOOL_EXECUTABLE="${OTOOL_STUB}" \
    BOUNDLESS_TRANSLATOR_MV_EXECUTABLE="${MV_STUB}" \
    BOUNDLESS_TRANSLATOR_APP_STORE_RELEASE_ROOT="${RELEASE_ROOT}" \
    BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
    BOUNDLESS_TRANSLATOR_TEST_PRIVACY_MANIFEST="${PROJECT_ROOT}/Resources/PrivacyInfo.xcprivacy" \
    BOUNDLESS_TRANSLATOR_TEST_LOCALIZATIONS_ROOT="${PROJECT_ROOT}/Sources/BoundlessTranslator/Resources" \
    BOUNDLESS_TRANSLATOR_APP_STORE_TEAM_ID=ABCDE12345 \
    BOUNDLESS_TRANSLATOR_SUBSCRIPTION_PRODUCT_ID=com.lillard.boundless.annual \
    BOUNDLESS_TRANSLATOR_PRIVACY_POLICY_URL=https://example.com/privacy \
    BOUNDLESS_TRANSLATOR_APP_STORE_COPYRIGHT='© 2026 Example Company' \
        zsh "${RELEASER}" "$@"
}

function test_release_app_store_when_configuration_is_valid_then_publishes_archive_and_package {
    # Arrange
    : > "${CALL_LOG}"

    # Act
    run_releaser 1.2.3 42

    # Assert
    local archive_path="${RELEASE_ROOT}/BoundlessTranslator-1.2.3-42.xcarchive"
    local package_path="${RELEASE_ROOT}/BoundlessTranslator-1.2.3-42.pkg"
    [[ -d "${archive_path}" ]]
    [[ "$(<"${package_path}")" == package ]]
    [[ ! -e "${RELEASE_ROOT}/Boundless Translator.app" ]]
    [[ "$(sed -n '1p' "${CALL_LOG}")" == archive\ *'-scheme BoundlessTranslator-AppStore'* ]]
    [[ "$(sed -n '1p' "${CALL_LOG}")" == *'MARKETING_VERSION=1.2.3'* ]]
    [[ "$(sed -n '1p' "${CALL_LOG}")" == *'CURRENT_PROJECT_VERSION=42'* ]]
    [[ "$(sed -n '1p' "${CALL_LOG}")" == *'CODE_SIGN_STYLE=Automatic'* ]]
    [[ "$(sed -n '1p' "${CALL_LOG}")" == *'-allowProvisioningUpdates'* ]]
    [[ "$(sed -n '1p' "${CALL_LOG}")" != *'-authenticationKeyPath'* ]]
    [[ "$(<"${CALL_LOG}")" == *$'codesign --verify --deep --strict --verbose=2 '* ]]
    [[ "$(<"${CALL_LOG}")" == *$'-exportArchive -exportArchive '* ]]
    [[ "$(<"${CALL_LOG}")" != *'-authenticationKeyID'* ]]
    [[ "$(<"${CALL_LOG}")" == *$'pkgutil --check-signature '*'/Boundless Translator.pkg' ]]
}

function test_release_app_store_when_same_build_exists_then_stops_before_xcode {
    # Arrange
    mkdir -p "${RELEASE_ROOT}/BoundlessTranslator-1.2.3-43.xcarchive"
    print existing > "${RELEASE_ROOT}/BoundlessTranslator-1.2.3-43.pkg"
    : > "${CALL_LOG}"

    # Act & Assert
    if run_releaser 1.2.3 43 >/dev/null 2>&1; then
        print -u2 'Expected an existing App Store build to stop the release.'
        return 1
    fi
    [[ ! -s "${CALL_LOG}" ]]
}

function test_release_app_store_when_another_release_is_running_then_stops_before_xcode {
    # Arrange
    mkdir -p "${RELEASE_ROOT}/.publish-lock"
    : > "${CALL_LOG}"

    # Act & Assert
    if run_releaser 1.2.3 47 >/dev/null 2>&1; then
        print -u2 'Expected a concurrent App Store release to stop.'
        return 1
    fi
    [[ ! -s "${CALL_LOG}" ]]
    rmdir "${RELEASE_ROOT}/.publish-lock"
}

function test_release_app_store_when_export_fails_then_does_not_publish_artifacts {
    # Arrange
    : > "${CALL_LOG}"

    # Act & Assert
    if TEST_FAIL_STEP=-exportArchive run_releaser 1.2.3 44 >/dev/null 2>&1; then
        print -u2 'Expected export failure to stop the release.'
        return 1
    fi
    [[ ! -e "${RELEASE_ROOT}/BoundlessTranslator-1.2.3-44.xcarchive" ]]
    [[ ! -e "${RELEASE_ROOT}/BoundlessTranslator-1.2.3-44.pkg" ]]
}

function test_release_app_store_when_interrupted_then_removes_temporary_files_and_lock {
    # Arrange
    : > "${CALL_LOG}"

    # Act & Assert
    if TEST_SIGNAL_STEP=archive run_releaser 1.2.3 49 >/dev/null 2>&1; then
        print -u2 'Expected an interrupted App Store release to stop.'
        return 1
    fi
    [[ ! -e "${RELEASE_ROOT}/.publish-lock" ]]
    [[ -z "$(find "${RELEASE_ROOT}" -maxdepth 1 -name '.boundless-translator-app-store-release.*' -print -quit)" ]]
    [[ ! -e "${RELEASE_ROOT}/BoundlessTranslator-1.2.3-49.xcarchive" ]]
    [[ ! -e "${RELEASE_ROOT}/BoundlessTranslator-1.2.3-49.pkg" ]]
}

function test_release_app_store_when_package_publish_fails_then_removes_partial_archive {
    # Arrange
    : > "${CALL_LOG}"

    # Act & Assert
    if TEST_FAIL_PACKAGE_PUBLISH=true run_releaser 1.2.3 48 >/dev/null 2>&1; then
        print -u2 'Expected package publish failure to stop the release.'
        return 1
    fi
    [[ ! -e "${RELEASE_ROOT}/BoundlessTranslator-1.2.3-48.xcarchive" ]]
    [[ ! -e "${RELEASE_ROOT}/BoundlessTranslator-1.2.3-48.pkg" ]]
}

function test_release_app_store_when_archive_has_wrong_product_id_then_stops_before_export {
    # Arrange
    : > "${CALL_LOG}"

    # Act & Assert
    if TEST_ARCHIVE_PRODUCT_ID=com.example.wrong run_releaser 1.2.3 45 >/dev/null 2>&1; then
        print -u2 'Expected incorrect subscription metadata to stop the release.'
        return 1
    fi
    [[ ! -e "${RELEASE_ROOT}/BoundlessTranslator-1.2.3-45.xcarchive" ]]
    [[ ! -e "${RELEASE_ROOT}/BoundlessTranslator-1.2.3-45.pkg" ]]
    [[ "$(<"${CALL_LOG}")" != *-exportArchive* ]]
}

function test_release_app_store_when_archive_lacks_sandbox_then_stops_before_export {
    # Arrange
    : > "${CALL_LOG}"

    # Act & Assert
    if TEST_ARCHIVE_SANDBOX_ENABLED=false run_releaser 1.2.3 46 >/dev/null 2>&1; then
        print -u2 'Expected an archive without App Sandbox to stop the release.'
        return 1
    fi
    [[ ! -e "${RELEASE_ROOT}/BoundlessTranslator-1.2.3-46.xcarchive" ]]
    [[ ! -e "${RELEASE_ROOT}/BoundlessTranslator-1.2.3-46.pkg" ]]
    [[ "$(<"${CALL_LOG}")" != *-exportArchive* ]]
}

function test_release_app_store_when_build_number_is_invalid_then_stops_before_xcode {
    # Arrange
    : > "${CALL_LOG}"

    # Act & Assert
    if run_releaser 1.2.3 0 >/dev/null 2>&1; then
        print -u2 'Expected an invalid build number to fail.'
        return 1
    fi
    [[ ! -s "${CALL_LOG}" ]]
}

test_release_app_store_when_configuration_is_valid_then_publishes_archive_and_package
test_release_app_store_when_same_build_exists_then_stops_before_xcode
test_release_app_store_when_another_release_is_running_then_stops_before_xcode
test_release_app_store_when_export_fails_then_does_not_publish_artifacts
test_release_app_store_when_interrupted_then_removes_temporary_files_and_lock
test_release_app_store_when_package_publish_fails_then_removes_partial_archive
test_release_app_store_when_archive_has_wrong_product_id_then_stops_before_export
test_release_app_store_when_archive_lacks_sandbox_then_stops_before_export
test_release_app_store_when_build_number_is_invalid_then_stops_before_xcode
print 'App Store release tests passed.'
