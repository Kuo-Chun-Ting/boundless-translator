#!/bin/zsh
set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-app-store-build-tests.XXXXXX)"
readonly APP_PATH="${TEMP_ROOT}/Build/AppStore/Boundless Translator.app"
readonly CALL_LOG="${TEMP_ROOT}/calls.log"
trap 'rm -rf "${TEMP_ROOT}"' EXIT

mkdir -p "${TEMP_ROOT}/Scripts" "${TEMP_ROOT}/bin" "${APP_PATH}"
[[ -f "${PROJECT_ROOT}/Scripts/build_app_store_app.sh" ]] || {
    print -u2 'Missing App Store App builder.'
    exit 1
}
cp "${PROJECT_ROOT}/Scripts/build_app_store_app.sh" "${TEMP_ROOT}/Scripts/"
cat > "${TEMP_ROOT}/bin/xcodebuild" <<'MOCK'
#!/bin/zsh
set -eu
print -r -- "$*" >> "${TEST_CALL_LOG}"
if [[ "$1" == -showBuildSettings ]]; then
    print -r -- '[{"target":"BoundlessTranslator","buildSettings":{"SWIFT_ACTIVE_COMPILATION_CONDITIONS":"'"${TEST_CONDITIONS:-SUBSCRIPTION_REQUIRED}"'"}}]'
    exit 0
fi
[[ "${TEST_BUILD_FAIL:-false}" != true ]] || exit 65
while (( $# )); do
    case "$1" in
        -derivedDataPath) derived="$2"; shift 2 ;;
        *) shift ;;
    esac
done
mkdir -p "${derived}/Build/Products/AppStoreRelease/Boundless Translator.app"
print new > "${derived}/Build/Products/AppStoreRelease/Boundless Translator.app/marker"
MOCK
cat > "${TEMP_ROOT}/bin/open" <<'MOCK'
#!/bin/zsh
print unexpected-open >> "${TEST_CALL_LOG}"
exit 1
MOCK
chmod +x "${TEMP_ROOT}/bin/"*

function run_builder {
    (cd /private/tmp && PATH="${TEMP_ROOT}/bin:${PATH}" TEST_CALL_LOG="${CALL_LOG}" \
        zsh "${TEMP_ROOT}/Scripts/build_app_store_app.sh")
}

function test_build_app_store_app_when_build_fails_then_preserves_previous_app {
    # Arrange
    print previous > "${APP_PATH}/marker"
    : > "${CALL_LOG}"
    # Act & Assert
    if TEST_BUILD_FAIL=true run_builder > "${TEMP_ROOT}/output" 2>&1; then
        print -u2 'Expected build failure.'
        return 1
    fi
    [[ "$(<"${APP_PATH}/marker")" == previous ]]
    ! grep -Fq 'Built ' "${TEMP_ROOT}/output"
}

function test_build_app_store_app_when_subscription_disabled_then_does_not_build {
    # Arrange
    print previous > "${APP_PATH}/marker"
    : > "${CALL_LOG}"
    # Act & Assert
    if TEST_CONDITIONS=DEBUG run_builder > "${TEMP_ROOT}/output" 2>&1; then
        print -u2 'Expected disabled subscription to prevent build.'
        return 1
    fi
    [[ "$(wc -l < "${CALL_LOG}" | tr -d ' ')" == 1 ]]
    [[ "$(<"${APP_PATH}/marker")" == previous ]]
    grep -Fq 'App Store build must enable SUBSCRIPTION_REQUIRED.' "${TEMP_ROOT}/output"
}

function test_build_app_store_app_when_build_succeeds_then_replaces_only_app {
    # Arrange
    print previous > "${APP_PATH}/marker"
    mkdir -p "${TEMP_ROOT}/Build/AppStore/BoundlessTranslator.xcarchive" \
        "${TEMP_ROOT}/Build/AppStore/Upload" "${TEMP_ROOT}/Build/AppStore/Validation"
    print archive > "${TEMP_ROOT}/Build/AppStore/BoundlessTranslator.xcarchive/marker"
    : > "${CALL_LOG}"
    # Act
    run_builder > "${TEMP_ROOT}/output" 2>&1
    # Assert
    [[ "$(<"${APP_PATH}/marker")" == new ]]
    [[ "$(<"${TEMP_ROOT}/Build/AppStore/BoundlessTranslator.xcarchive/marker")" == archive ]]
    [[ -d "${TEMP_ROOT}/Build/AppStore/Upload" && -d "${TEMP_ROOT}/Build/AppStore/Validation" ]]
    grep -Fxq "Built ${APP_PATH}" "${TEMP_ROOT}/output"
    [[ "$(wc -l < "${CALL_LOG}" | tr -d ' ')" == 2 ]]
    local build_call="$(sed -n '2p' "${CALL_LOG}")"
    [[ "${build_call}" == build\ * ]]
    [[ "${build_call}" == *'-scheme BoundlessTranslator-AppStore'* ]]
    [[ "${build_call}" == *'-configuration AppStoreRelease'* ]]
    [[ "${build_call}" == *'-allowProvisioningUpdates'* ]]
    [[ "${build_call}" != *BOUNDLESS_TRANSLATOR_BUNDLE_IDENTIFIER=* ]]
    [[ "${build_call}" != *CODE_SIGN_IDENTITY=* ]]
    [[ "${build_call}" != *-exportArchive* ]]
}

test_build_app_store_app_when_build_fails_then_preserves_previous_app
test_build_app_store_app_when_subscription_disabled_then_does_not_build
test_build_app_store_app_when_build_succeeds_then_replaces_only_app
print 'App Store App build tests passed.'
