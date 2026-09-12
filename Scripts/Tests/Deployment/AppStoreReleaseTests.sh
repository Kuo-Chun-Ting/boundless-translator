#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly RELEASER="${PROJECT_ROOT}/Scripts/release_app_store.sh"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-app-store-release-tests.XXXXXX)"
readonly BUILD_ROOT="${TEMP_ROOT}/Build/AppStore"
readonly CALL_LOG="${TEMP_ROOT}/calls.log"
readonly BUILD_STUB="${TEMP_ROOT}/build-app"
readonly PRODUCTBUILD_STUB="${TEMP_ROOT}/productbuild"
readonly PKGUTIL_STUB="${TEMP_ROOT}/pkgutil"
readonly MV_STUB="${TEMP_ROOT}/mv"
readonly PACKAGE_PATH="${BUILD_ROOT}/BoundlessTranslator-1.2.3-42.pkg"
readonly APP_PATH="${BUILD_ROOT}/Boundless Translator.app"

function clean_up {
    rm -rf "${TEMP_ROOT}"
}
trap clean_up EXIT

function create_step_stubs {
    cat > "${BUILD_STUB}" <<'EOF'
#!/bin/zsh
set -eu
print -r -- "build $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
mkdir -p "${BOUNDLESS_TRANSLATOR_APP_STORE_BUILD_ROOT}/Boundless Translator.app"
print -r -- "${BOUNDLESS_TRANSLATOR_APP_STORE_VERSION}:${BOUNDLESS_TRANSLATOR_APP_STORE_BUILD_NUMBER}" > "${BOUNDLESS_TRANSLATOR_APP_STORE_BUILD_ROOT}/Boundless Translator.app/marker"
EOF

    cat > "${PRODUCTBUILD_STUB}" <<'EOF'
#!/bin/zsh
set -eu
print -r -- "productbuild $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
if [[ "${TEST_PRODUCTBUILD_FAIL:-false}" == true ]]; then
    exit 1
fi
print 'signed package' > "${@: -1}"
EOF

    cat > "${PKGUTIL_STUB}" <<'EOF'
#!/bin/zsh
set -eu
print -r -- "pkgutil $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
[[ "${TEST_PKGUTIL_FAIL:-false}" != true ]]
EOF

    cat > "${MV_STUB}" <<'EOF'
#!/bin/zsh
set -eu
if [[ "${TEST_LOG_MV:-false}" == true && "$1" == */staged/'Boundless Translator.app' && "$2" == "${TEST_FINAL_APP_PATH}" ]]; then
    print 'publish app' >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
elif [[ "${TEST_LOG_MV:-false}" == true && "$1" == */BoundlessTranslator-1.2.3-42.pkg && "$2" == "${TEST_FINAL_PACKAGE_PATH}" ]]; then
    print 'publish package' >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
fi
if [[ "${TEST_MV_FAIL_SOURCE:-}" == "$1" && "$2" == */previous.app && ! -e "${TEST_MV_FAILED_MARKER:-/nonexistent}" ]]; then
    touch "${TEST_MV_FAILED_MARKER}"
    exit 1
fi
if [[ "${TEST_MV_FAIL_PUBLISH_PACKAGE:-false}" == true && "$1" == */BoundlessTranslator-1.2.3-42.pkg && "$2" == "${TEST_FINAL_PACKAGE_PATH}" ]]; then
    exit 1
fi
if [[ "${TEST_MV_FAIL_EVACUATE_APP:-false}" == true && "$1" == "${TEST_FINAL_APP_PATH}" && "$2" == */failed.app ]]; then
    exit 1
fi
if [[ "${TEST_MV_FAIL_RESTORE_APP:-false}" == true && "$1" == */previous.app && "$2" == "${TEST_FINAL_APP_PATH}" ]]; then
    exit 1
fi
/bin/mv "$@"
EOF
    chmod +x "${BUILD_STUB}" "${PRODUCTBUILD_STUB}" "${PKGUTIL_STUB}" "${MV_STUB}"
}

function run_releaser {
    BOUNDLESS_TRANSLATOR_BUILD_APP_EXECUTABLE="${BUILD_STUB}" \
    BOUNDLESS_TRANSLATOR_PRODUCTBUILD_EXECUTABLE="${PRODUCTBUILD_STUB}" \
    BOUNDLESS_TRANSLATOR_PKGUTIL_EXECUTABLE="${PKGUTIL_STUB}" \
    BOUNDLESS_TRANSLATOR_MV_EXECUTABLE="${MV_STUB}" \
    BOUNDLESS_TRANSLATOR_APP_STORE_RELEASE_ROOT="${BUILD_ROOT}" \
    BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
    TEST_FINAL_APP_PATH="${APP_PATH}" \
    TEST_FINAL_PACKAGE_PATH="${PACKAGE_PATH}" \
    BOUNDLESS_TRANSLATOR_APP_STORE_SIGNING_IDENTITY='Apple Distribution: Example (ABCDE12345)' \
    BOUNDLESS_TRANSLATOR_INSTALLER_SIGNING_IDENTITY='Mac Installer Distribution: Example (ABCDE12345)' \
    BOUNDLESS_TRANSLATOR_APP_STORE_PROVISIONING_PROFILE="${TEMP_ROOT}/distribution.provisionprofile" \
    BOUNDLESS_TRANSLATOR_APP_STORE_TEAM_ID='ABCDE12345' \
    BOUNDLESS_TRANSLATOR_SUBSCRIPTION_PRODUCT_ID='com.lillard.boundless.annual' \
    BOUNDLESS_TRANSLATOR_PRIVACY_POLICY_URL='https://example.com/privacy' \
    BOUNDLESS_TRANSLATOR_APP_STORE_COPYRIGHT='© 2026 Example Company' \
        zsh "${RELEASER}" "$@"
}

function test_release_app_store_when_configuration_is_valid_then_publishes_signed_package {
    # Arrange
    : > "${CALL_LOG}"

    # Act
    run_releaser 1.2.3 42

    # Assert
    [[ "$(<"${APP_PATH}/marker")" == '1.2.3:42' ]]
    [[ "$(<"${PACKAGE_PATH}")" == 'signed package' ]]
    [[ "$(sed -n '1p' "${CALL_LOG}")" == 'build --app-store' ]]
    [[ "$(sed -n '2p' "${CALL_LOG}")" == *'productbuild --sign Mac Installer Distribution: Example (ABCDE12345) --component '*'/Boundless Translator.app /Applications '*'/BoundlessTranslator-1.2.3-42.pkg' ]]
    [[ "$(sed -n '3p' "${CALL_LOG}")" == *'pkgutil --check-signature '*'/BoundlessTranslator-1.2.3-42.pkg' ]]
    [[ "$(wc -l < "${CALL_LOG}" | tr -d ' ')" == 3 ]]
}

function test_release_app_store_when_version_has_two_components_then_accepts_it {
    # Arrange
    : > "${CALL_LOG}"
    local package_path="${BUILD_ROOT}/BoundlessTranslator-1.0-1.pkg"

    # Act
    run_releaser 1.0 1

    # Assert
    [[ "$(<"${APP_PATH}/marker")" == '1.0:1' ]]
    [[ "$(<"${package_path}")" == 'signed package' ]]
}

function test_release_app_store_when_build_number_is_invalid_then_preserves_existing_artifacts {
    # Arrange
    mkdir -p "${APP_PATH}"
    print 'existing app' > "${APP_PATH}/marker"
    print 'existing package' > "${PACKAGE_PATH}"
    : > "${CALL_LOG}"

    # Act & Assert
    if run_releaser 1.2.3 0 > "${TEMP_ROOT}/invalid-build.log" 2>&1; then
        print -u2 'Expected a zero build number to fail.'
        return 1
    fi
    [[ "$(<"${APP_PATH}/marker")" == 'existing app' ]]
    [[ "$(<"${PACKAGE_PATH}")" == 'existing package' ]]
    [[ ! -s "${CALL_LOG}" ]]
}

function test_release_app_store_when_packaging_fails_then_preserves_existing_artifacts {
    # Arrange
    mkdir -p "${APP_PATH}"
    print 'existing app' > "${APP_PATH}/marker"
    print 'existing package' > "${PACKAGE_PATH}"
    : > "${CALL_LOG}"

    # Act & Assert
    if TEST_PRODUCTBUILD_FAIL=true run_releaser 1.2.3 42 > "${TEMP_ROOT}/package-failure.log" 2>&1; then
        print -u2 'Expected productbuild failure to stop the release.'
        return 1
    fi
    [[ "$(<"${APP_PATH}/marker")" == 'existing app' ]]
    [[ "$(<"${PACKAGE_PATH}")" == 'existing package' ]]
}

function test_release_app_store_when_existing_app_cannot_be_backed_up_then_preserves_it {
    # Arrange
    mkdir -p "${APP_PATH}"
    print 'existing app' > "${APP_PATH}/marker"
    : > "${CALL_LOG}"

    # Act & Assert
    if TEST_MV_FAIL_SOURCE="${APP_PATH}" TEST_MV_FAILED_MARKER="${TEMP_ROOT}/mv-failed" run_releaser 1.2.3 42 > "${TEMP_ROOT}/backup-failure.log" 2>&1; then
        print -u2 'Expected a failed existing-app backup to stop publishing.'
        return 1
    fi
    [[ "$(<"${APP_PATH}/marker")" == 'existing app' ]]
    if [[ -e "${BUILD_ROOT}/.publish-lock" ]]; then
        cat "${TEMP_ROOT}/backup-failure.log" >&2
        print -u2 'Expected failed publishing to release its lock.'
        return 1
    fi
}

function test_release_app_store_when_rollback_restore_fails_then_preserves_recovery_artifacts {
    # Arrange
    mkdir -p "${APP_PATH}"
    print 'existing app' > "${APP_PATH}/marker"
    print 'existing package' > "${PACKAGE_PATH}"
    : > "${CALL_LOG}"

    # Act & Assert
    if TEST_MV_FAIL_PUBLISH_PACKAGE=true TEST_MV_FAIL_RESTORE_APP=true run_releaser 1.2.3 42 > "${TEMP_ROOT}/rollback-failure.log" 2>&1; then
        print -u2 'Expected failed publishing and rollback to fail the release.'
        return 1
    fi
    local recovery_paths=("${BUILD_ROOT}"/.boundless-translator-app-store-release.*(N))
    [[ "${#recovery_paths}" == 1 ]]
    [[ "$(<"${recovery_paths[1]}/previous.app/marker")" == 'existing app' ]]
    [[ "$(<"${recovery_paths[1]}/failed.app/marker")" == '1.2.3:42' ]]
    [[ "$(<"${PACKAGE_PATH}")" == 'existing package' ]]
    [[ "$(<"${TEMP_ROOT}/rollback-failure.log")" == *"${recovery_paths[1]}"* ]]
    [[ ! -e "${BUILD_ROOT}/.publish-lock" ]]
    rm -rf "${recovery_paths[1]}"
}

function test_release_app_store_when_new_app_cannot_be_evacuated_then_does_not_nest_previous_app {
    # Arrange
    mkdir -p "${APP_PATH}"
    print 'existing app' > "${APP_PATH}/marker"
    print 'existing package' > "${PACKAGE_PATH}"
    : > "${CALL_LOG}"

    # Act & Assert
    if TEST_MV_FAIL_PUBLISH_PACKAGE=true TEST_MV_FAIL_EVACUATE_APP=true run_releaser 1.2.3 42 > "${TEMP_ROOT}/evacuation-failure.log" 2>&1; then
        print -u2 'Expected failed package publishing and App evacuation to fail the release.'
        return 1
    fi
    local recovery_paths=("${BUILD_ROOT}"/.boundless-translator-app-store-release.*(N))
    [[ "${#recovery_paths}" == 1 ]]
    [[ "$(<"${APP_PATH}/marker")" == '1.2.3:42' ]]
    [[ ! -e "${APP_PATH}/previous.app" ]]
    [[ "$(<"${recovery_paths[1]}/previous.app/marker")" == 'existing app' ]]
    [[ "$(<"${PACKAGE_PATH}")" == 'existing package' ]]
    [[ "$(<"${TEMP_ROOT}/evacuation-failure.log")" == *"${recovery_paths[1]}"* ]]
}

function test_release_app_store_when_extra_argument_is_given_then_rejects_it {
    # Arrange
    : > "${CALL_LOG}"

    # Act & Assert
    if run_releaser 1.2.3 42 --upload > "${TEMP_ROOT}/extra-argument.log" 2>&1; then
        print -u2 'Expected an extra argument to fail.'
        return 1
    fi
    [[ "$(<"${TEMP_ROOT}/extra-argument.log")" == *'Usage: release_app_store.sh <version> <build-number>'* ]]
    [[ ! -s "${CALL_LOG}" ]]
}

touch "${TEMP_ROOT}/distribution.provisionprofile"
create_step_stubs
test_release_app_store_when_configuration_is_valid_then_publishes_signed_package
test_release_app_store_when_version_has_two_components_then_accepts_it
test_release_app_store_when_build_number_is_invalid_then_preserves_existing_artifacts
test_release_app_store_when_packaging_fails_then_preserves_existing_artifacts
test_release_app_store_when_existing_app_cannot_be_backed_up_then_preserves_it
test_release_app_store_when_rollback_restore_fails_then_preserves_recovery_artifacts
test_release_app_store_when_new_app_cannot_be_evacuated_then_does_not_nest_previous_app
test_release_app_store_when_extra_argument_is_given_then_rejects_it

print 'App Store release tests passed.'
