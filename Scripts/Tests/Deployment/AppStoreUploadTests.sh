#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly UPLOADER="${PROJECT_ROOT}/Scripts/upload_app_store.sh"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-app-store-upload-tests.XXXXXX)"
readonly PACKAGE_PATH="${TEMP_ROOT}/BoundlessTranslator-1.2.3-42.pkg"
readonly CALL_LOG="${TEMP_ROOT}/calls.log"
readonly XCRUN_STUB="${TEMP_ROOT}/xcrun"
readonly LOCAL_PROJECT_ROOT="${TEMP_ROOT}/local-project"
readonly LOCAL_UPLOADER="${LOCAL_PROJECT_ROOT}/Scripts/upload_app_store.sh"
readonly EMPTY_PROJECT_ROOT="${TEMP_ROOT}/empty-project"
readonly EMPTY_UPLOADER="${EMPTY_PROJECT_ROOT}/Scripts/upload_app_store.sh"

function clean_up {
    rm -rf "${TEMP_ROOT}"
}
trap clean_up EXIT

function create_xcrun_stub {
    cat > "${XCRUN_STUB}" <<'EOF'
#!/bin/zsh
set -eu
[[ "$1" == altool ]]
shift
operation="$1"
expected_key_id="${BOUNDLESS_TRANSLATOR_TEST_EXPECTED_KEY_ID:-${BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_KEY_ID}}"
expected_issuer_id="${BOUNDLESS_TRANSLATOR_TEST_EXPECTED_ISSUER_ID:-${BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_ISSUER_ID}}"
[[ "$*" == *"--apiKey ${expected_key_id}"* ]]
[[ "$*" == *"--apiIssuer ${expected_issuer_id}"* ]]
package_path=""
while [[ "$#" -gt 0 ]]; do
    if [[ "$1" == -f ]]; then
        package_path="$2"
        break
    fi
    shift
done
print -r -- "altool ${operation} ${package_path}" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
if [[ "${TEST_ALTOOL_VALIDATE_FAIL:-false}" == true && "${operation}" == --validate-app ]]; then
    exit 1
fi
EOF
    chmod +x "${XCRUN_STUB}"
}

function run_uploader {
    BOUNDLESS_TRANSLATOR_XCRUN_EXECUTABLE="${XCRUN_STUB}" \
    BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
    BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_KEY_ID='KEYID12345' \
    BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_ISSUER_ID='11111111-2222-3333-4444-555555555555' \
        zsh "${UPLOADER}" "$@"
}

function test_upload_app_store_when_package_is_valid_then_validates_before_uploading {
    # Arrange
    print 'signed package' > "${PACKAGE_PATH}"
    : > "${CALL_LOG}"

    # Act
    run_uploader "${PACKAGE_PATH}"

    # Assert
    [[ "$(sed -n '1p' "${CALL_LOG}")" == "altool --validate-app ${PACKAGE_PATH}" ]]
    [[ "$(sed -n '2p' "${CALL_LOG}")" == "altool --upload-app ${PACKAGE_PATH}" ]]
    [[ "$(wc -l < "${CALL_LOG}" | tr -d ' ')" == 2 ]]
    [[ "$(<"${CALL_LOG}")" != *KEYID12345* ]]
    [[ "$(<"${CALL_LOG}")" != *11111111-2222-3333-4444-555555555555* ]]
}

function test_upload_app_store_when_package_is_missing_then_stops_before_apple_tools {
    # Arrange
    rm -f "${PACKAGE_PATH}"
    : > "${CALL_LOG}"

    # Act & Assert
    if run_uploader "${PACKAGE_PATH}" > "${TEMP_ROOT}/missing-package.log" 2>&1; then
        print -u2 'Expected a missing package to fail.'
        return 1
    fi
    [[ ! -s "${CALL_LOG}" ]]
    [[ "$(<"${TEMP_ROOT}/missing-package.log")" == *'App Store package does not exist:'* ]]
}

function test_upload_app_store_when_api_credentials_are_missing_then_stops_before_apple_tools {
    # Arrange
    mkdir -p "${EMPTY_PROJECT_ROOT}/Scripts"
    cp "${UPLOADER}" "${EMPTY_UPLOADER}"
    print 'signed package' > "${PACKAGE_PATH}"
    : > "${CALL_LOG}"

    # Act & Assert
    if env -u BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_KEY_ID \
        -u BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_ISSUER_ID \
        BOUNDLESS_TRANSLATOR_XCRUN_EXECUTABLE="${XCRUN_STUB}" \
        BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
        zsh "${EMPTY_UPLOADER}" "${PACKAGE_PATH}" > "${TEMP_ROOT}/missing-credentials.log" 2>&1; then
        print -u2 'Expected missing API credentials to fail.'
        return 1
    fi
    [[ ! -s "${CALL_LOG}" ]]
    [[ "$(<"${TEMP_ROOT}/missing-credentials.log")" == *'BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_KEY_ID is required.'* ]]
}

function test_upload_app_store_when_local_environment_exists_then_loads_credentials {
    # Arrange
    mkdir -p "${LOCAL_PROJECT_ROOT}/Scripts"
    cp "${UPLOADER}" "${LOCAL_UPLOADER}"
    cat > "${LOCAL_PROJECT_ROOT}/.env.local" <<'EOF'
BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_KEY_ID=LOCALKEY123
BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_ISSUER_ID=aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee
EOF
    print 'signed package' > "${PACKAGE_PATH}"
    : > "${CALL_LOG}"

    # Act
    env -u BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_KEY_ID \
        -u BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_ISSUER_ID \
        BOUNDLESS_TRANSLATOR_XCRUN_EXECUTABLE="${XCRUN_STUB}" \
        BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
        zsh "${LOCAL_UPLOADER}" "${PACKAGE_PATH}"

    # Assert
    [[ "$(sed -n '1p' "${CALL_LOG}")" == "altool --validate-app ${PACKAGE_PATH}" ]]
    [[ "$(sed -n '2p' "${CALL_LOG}")" == "altool --upload-app ${PACKAGE_PATH}" ]]
}

function test_upload_app_store_when_shell_credentials_exist_then_they_override_local_environment {
    # Arrange
    print 'signed package' > "${PACKAGE_PATH}"
    : > "${CALL_LOG}"

    # Act
    BOUNDLESS_TRANSLATOR_XCRUN_EXECUTABLE="${XCRUN_STUB}" \
    BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
    BOUNDLESS_TRANSLATOR_TEST_EXPECTED_KEY_ID='OVERRIDEKEY' \
    BOUNDLESS_TRANSLATOR_TEST_EXPECTED_ISSUER_ID='99999999-8888-7777-6666-555555555555' \
    BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_KEY_ID='OVERRIDEKEY' \
    BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_ISSUER_ID='99999999-8888-7777-6666-555555555555' \
        zsh "${LOCAL_UPLOADER}" "${PACKAGE_PATH}"

    # Assert
    [[ "$(sed -n '1p' "${CALL_LOG}")" == "altool --validate-app ${PACKAGE_PATH}" ]]
    [[ "$(sed -n '2p' "${CALL_LOG}")" == "altool --upload-app ${PACKAGE_PATH}" ]]
}

function test_upload_app_store_when_remote_validation_fails_then_does_not_upload {
    # Arrange
    print 'signed package' > "${PACKAGE_PATH}"
    : > "${CALL_LOG}"

    # Act & Assert
    if TEST_ALTOOL_VALIDATE_FAIL=true run_uploader "${PACKAGE_PATH}" > "${TEMP_ROOT}/validation-failure.log" 2>&1; then
        print -u2 'Expected failed App Store validation to stop the upload.'
        return 1
    fi
    [[ "$(sed -n '1p' "${CALL_LOG}")" == "altool --validate-app ${PACKAGE_PATH}" ]]
    [[ "$(<"${CALL_LOG}")" != *--upload-app* ]]
}

create_xcrun_stub
test_upload_app_store_when_package_is_valid_then_validates_before_uploading
test_upload_app_store_when_package_is_missing_then_stops_before_apple_tools
test_upload_app_store_when_api_credentials_are_missing_then_stops_before_apple_tools
test_upload_app_store_when_local_environment_exists_then_loads_credentials
test_upload_app_store_when_shell_credentials_exist_then_they_override_local_environment
test_upload_app_store_when_remote_validation_fails_then_does_not_upload

print 'App Store upload tests passed.'
