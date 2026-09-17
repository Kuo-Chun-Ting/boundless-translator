#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly BUILDER="${PROJECT_ROOT}/Scripts/Tools/build_app.sh"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-build-app-tests.XXXXXX)"
readonly BUILD_ROOT="${TEMP_ROOT}/Build"
readonly INFO_PLIST="${TEMP_ROOT}/Info.plist"
readonly CALL_LOG="${TEMP_ROOT}/calls.log"
readonly XCODEBUILD_STUB="${TEMP_ROOT}/xcodebuild"
readonly VERIFY_STUB="${TEMP_ROOT}/verify-app"
trap 'rm -rf "${TEMP_ROOT}"' EXIT

cp "${PROJECT_ROOT}/Resources/Info.plist" "${INFO_PLIST}"
plutil -replace CFBundleShortVersionString -string 1.2.3 "${INFO_PLIST}"
plutil -replace CFBundleVersion -string 42 "${INFO_PLIST}"

cat > "${XCODEBUILD_STUB}" <<'STUB'
#!/bin/zsh
set -eu
print -r -- "$*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
[[ "${TEST_XCODEBUILD_FAIL:-false}" != true ]]

derived_data_path=''
configuration=''
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -derivedDataPath) derived_data_path="$2"; shift 2 ;;
        -configuration) configuration="$2"; shift 2 ;;
        *) shift ;;
    esac
done
mkdir -p "${derived_data_path}/Build/Products/${configuration}/Boundless Translator.app/Contents/MacOS"
print app > "${derived_data_path}/Build/Products/${configuration}/Boundless Translator.app/Contents/MacOS/BoundlessTranslator"
STUB

cat > "${VERIFY_STUB}" <<'STUB'
#!/bin/zsh
set -eu
print -r -- "verify $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
[[ "${TEST_VERIFY_FAIL:-false}" != true ]]
STUB
chmod +x "${XCODEBUILD_STUB}" "${VERIFY_STUB}"

function run_builder {
    BOUNDLESS_TRANSLATOR_XCODEBUILD_EXECUTABLE="${XCODEBUILD_STUB}" \
    BOUNDLESS_TRANSLATOR_APP_VERIFY_EXECUTABLE="${VERIFY_STUB}" \
    BOUNDLESS_TRANSLATOR_BUILD_INFO_PLIST="${INFO_PLIST}" \
    BOUNDLESS_TRANSLATOR_BUILD_ROOT="${BUILD_ROOT}" \
    BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
    BOUNDLESS_TRANSLATOR_SUBSCRIPTION_PRODUCT_ID=com.lillard.boundless.annual \
    BOUNDLESS_TRANSLATOR_PRIVACY_POLICY_URL=https://example.com/privacy \
    BOUNDLESS_TRANSLATOR_APP_STORE_COPYRIGHT='© 2026 Example Company' \
        zsh "${BUILDER}" "$@"
}

function test_build_app_when_requested_then_builds_test_dmg_app {
    # Arrange
    : > "${CALL_LOG}"

    # Act
    run_builder

    # Assert
    [[ -f "${BUILD_ROOT}/Boundless Translator.app/Contents/MacOS/BoundlessTranslator" ]]
    local build_call="$(sed -n '1p' "${CALL_LOG}")"
    [[ "${build_call}" == build\ * ]]
    [[ "${build_call}" == *'-scheme BoundlessTranslator-Direct'* ]]
    [[ "${build_call}" == *'-configuration DirectRelease'* ]]
    [[ "${build_call}" == *'MARKETING_VERSION=1.2.3'* ]]
    [[ "${build_call}" == *'CURRENT_PROJECT_VERSION=42'* ]]
    [[ "${build_call}" != *SUBSCRIPTION_REQUIRED* ]]
    [[ "$(sed -n '2p' "${CALL_LOG}")" == verify\ *'/Boundless Translator.app' ]]
}

function test_build_app_when_xcode_build_fails_then_preserves_previous_app {
    # Arrange
    mkdir -p "${BUILD_ROOT}/Boundless Translator.app"
    print previous > "${BUILD_ROOT}/Boundless Translator.app/marker"

    # Act & Assert
    if TEST_XCODEBUILD_FAIL=true run_builder >/dev/null 2>&1; then
        print -u2 'Expected Xcode build failure to stop the build.'
        return 1
    fi
    [[ "$(<"${BUILD_ROOT}/Boundless Translator.app/marker")" == previous ]]
}

function test_build_app_when_verification_fails_then_preserves_previous_app {
    # Arrange
    mkdir -p "${BUILD_ROOT}/Boundless Translator.app"
    print previous > "${BUILD_ROOT}/Boundless Translator.app/marker"

    # Act & Assert
    if TEST_VERIFY_FAIL=true run_builder >/dev/null 2>&1; then
        print -u2 'Expected verification failure to stop the build.'
        return 1
    fi
    [[ "$(<"${BUILD_ROOT}/Boundless Translator.app/marker")" == previous ]]
}

function test_build_app_when_argument_is_given_then_stops_before_xcode_build {
    # Arrange
    : > "${CALL_LOG}"

    # Act & Assert
    if run_builder --formal-dmg >/dev/null 2>&1; then
        print -u2 'Expected build_app.sh to reject arguments.'
        return 1
    fi
    [[ ! -s "${CALL_LOG}" ]]
}

test_build_app_when_requested_then_builds_test_dmg_app
test_build_app_when_xcode_build_fails_then_preserves_previous_app
test_build_app_when_verification_fails_then_preserves_previous_app
test_build_app_when_argument_is_given_then_stops_before_xcode_build
print 'App build tests passed.'
