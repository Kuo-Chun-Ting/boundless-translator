#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly BUILDER="${PROJECT_ROOT}/Scripts/DMG/build_app.sh"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-build-app-tests.XXXXXX)"
readonly BUILD_ROOT="${TEMP_ROOT}/Build"
readonly CALL_LOG="${TEMP_ROOT}/calls.log"
readonly XCODEBUILD_STUB="${TEMP_ROOT}/xcodebuild"
trap 'rm -rf "${TEMP_ROOT}"' EXIT

cat > "${XCODEBUILD_STUB}" <<'STUB'
#!/bin/zsh
set -eu
print -r -- "$*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
[[ "${TEST_XCODEBUILD_FAIL:-false}" != true ]]

derived_data_path=''
configuration=''
product_name='Boundless Translator'
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -derivedDataPath) derived_data_path="$2"; shift 2 ;;
        -configuration) configuration="$2"; shift 2 ;;
        BOUNDLESS_TRANSLATOR_PRODUCT_NAME=*)
            product_name="${1#BOUNDLESS_TRANSLATOR_PRODUCT_NAME=}"
            shift
            ;;
        *) shift ;;
    esac
done
mkdir -p "${derived_data_path}/Build/Products/${configuration}/${product_name}.app/Contents/MacOS"
print app > "${derived_data_path}/Build/Products/${configuration}/${product_name}.app/Contents/MacOS/${product_name}"
STUB

chmod +x "${XCODEBUILD_STUB}"

function run_builder {
    BOUNDLESS_TRANSLATOR_XCODEBUILD_EXECUTABLE="${XCODEBUILD_STUB}" \
    BOUNDLESS_TRANSLATOR_BUILD_ROOT="${BUILD_ROOT}" \
    BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
        zsh "${BUILDER}" "$@"
}

function test_build_app_when_requested_then_builds_test_dmg_app {
    # Arrange
    : > "${CALL_LOG}"

    # Act
    run_builder

    # Assert
    [[ -f "${BUILD_ROOT}/Boundless Translator.app/Contents/MacOS/Boundless Translator" ]]
    local build_call="$(sed -n '1p' "${CALL_LOG}")"
    [[ "${build_call}" == build\ * ]]
    [[ "${build_call}" == *'-scheme BoundlessTranslator-Direct'* ]]
    [[ "${build_call}" == *'-configuration DirectRelease'* ]]
    [[ "${build_call}" != *MARKETING_VERSION=* ]]
    [[ "${build_call}" != *CURRENT_PROJECT_VERSION=* ]]
    [[ "${build_call}" != *SUBSCRIPTION_REQUIRED* ]]
    [[ "${build_call}" == *'BOUNDLESS_TRANSLATOR_PRODUCT_NAME=Boundless Translator'* ]]
    [[ "${build_call}" == *'BOUNDLESS_TRANSLATOR_BUNDLE_IDENTIFIER=com.lillard.BoundlessTranslator'* ]]
    [[ "$(wc -l < "${CALL_LOG}" | tr -d ' ')" == 1 ]]
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

function test_build_app_when_e2e_identity_is_requested_then_overrides_product_identity {
    # Arrange
    : > "${CALL_LOG}"

    # Act
    BOUNDLESS_TRANSLATOR_PRODUCT_NAME='Boundless Translator E2E' \
    BOUNDLESS_TRANSLATOR_BUNDLE_IDENTIFIER='com.lillard.BoundlessTranslator.e2e' \
        run_builder

    # Assert
    [[ -d "${BUILD_ROOT}/Boundless Translator E2E.app" ]]
    local build_call="$(sed -n '1p' "${CALL_LOG}")"
    [[ "${build_call}" == *'BOUNDLESS_TRANSLATOR_PRODUCT_NAME=Boundless Translator E2E'* ]]
    [[ "${build_call}" == *'BOUNDLESS_TRANSLATOR_BUNDLE_IDENTIFIER=com.lillard.BoundlessTranslator.e2e'* ]]
    [[ "${build_call}" != *' PRODUCT_NAME='* ]]
    [[ "${build_call}" != *' PRODUCT_BUNDLE_IDENTIFIER='* ]]
    [[ "${build_call}" != *BOUNDLESS_TRANSLATOR_DISPLAY_NAME* ]]
    [[ "${build_call}" != *BOUNDLESS_TRANSLATOR_EXECUTABLE_NAME* ]]
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
test_build_app_when_e2e_identity_is_requested_then_overrides_product_identity
test_build_app_when_xcode_build_fails_then_preserves_previous_app
test_build_app_when_argument_is_given_then_stops_before_xcode_build
print 'App build tests passed.'
