#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly DMG_BUILDER="${PROJECT_ROOT}/Scripts/Tools/build_dmg.sh"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-build-dmg-tests.XXXXXX)"
readonly CALL_LOG="${TEMP_ROOT}/calls.log"
readonly BUILD_ROOT="${TEMP_ROOT}/Build"
readonly APP_PATH="${BUILD_ROOT}/Boundless Translator.app"
readonly DMG_PATH="${BUILD_ROOT}/Boundless Translator-0.2.0.dmg"

function clean_up {
    rm -rf "${TEMP_ROOT}"
}
trap clean_up EXIT

function create_step_stub {
    local stub_path="$1"

    cat > "${stub_path}" <<'EOF'
#!/bin/zsh
print -r -- "${0:t} $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
if [[ "${0:t}" == *step-build ]]; then
    mkdir -p "${BOUNDLESS_TRANSLATOR_BUILD_ROOT}/Boundless Translator.app"
    print -n "${TEST_APP_MARKER:-built app}" > "${BOUNDLESS_TRANSLATOR_BUILD_ROOT}/Boundless Translator.app/marker"
elif [[ "${0:t}" == *step-package ]]; then
    mkdir -p "${2:h}"
    print -n "$(<"$1/marker")" > "$2"
fi
EOF
    chmod +x "${stub_path}"
}

function run_dmg_builder {
    local build_stub="$1"
    local verify_stub="$2"
    local package_stub="$3"
    shift 3

    BOUNDLESS_TRANSLATOR_BUILD_EXECUTABLE="${build_stub}" \
    BOUNDLESS_TRANSLATOR_VERIFY_EXECUTABLE="${verify_stub}" \
    BOUNDLESS_TRANSLATOR_PACKAGE_EXECUTABLE="${package_stub}" \
    BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
    TEST_APP_MARKER="${TEST_APP_MARKER:-built app}" \
        zsh "${DMG_BUILDER}" "$@"
}

function test_build_dmg_when_output_path_is_provided_then_builds_verifies_and_packages_app {
    # Arrange
    local build_stub="${TEMP_ROOT}/step-build"
    local verify_stub="${TEMP_ROOT}/step-verify"
    local package_stub="${TEMP_ROOT}/step-package"
    create_step_stub "${build_stub}"
    create_step_stub "${verify_stub}"
    create_step_stub "${package_stub}"
    : > "${CALL_LOG}"

    # Act
    run_dmg_builder "${build_stub}" "${verify_stub}" "${package_stub}" "${DMG_PATH}"

    # Assert
    local expected_calls
    expected_calls=$'step-build \n'
    local staged_app_path="$(sed -n '2p' "${CALL_LOG}")"
    staged_app_path="${staged_app_path#step-verify }"
    expected_calls+=$'step-verify '${staged_app_path}$'\n'
    expected_calls+=$'step-package '${staged_app_path}$' '${DMG_PATH}
    [[ "$(<"${CALL_LOG}")" == "${expected_calls}" ]]
    [[ "$(<"${DMG_PATH}")" == "built app" ]]
    [[ "${staged_app_path}" != "${APP_PATH}" ]]
}

function test_build_dmg_when_shared_app_changes_after_build_then_packages_its_staged_app {
    # Arrange
    local build_stub="${TEMP_ROOT}/race-step-build"
    local verify_stub="${TEMP_ROOT}/race-step-verify"
    local package_stub="${TEMP_ROOT}/race-step-package"
    create_step_stub "${build_stub}"
    create_step_stub "${verify_stub}"
    create_step_stub "${package_stub}"
    mkdir -p "${APP_PATH}"
    print -n 'other build' > "${APP_PATH}/marker"
    : > "${CALL_LOG}"

    # Act
    TEST_APP_MARKER='this invocation' run_dmg_builder "${build_stub}" "${verify_stub}" "${package_stub}" "${DMG_PATH}"

    # Assert
    [[ "$(<"${DMG_PATH}")" == 'this invocation' ]]
    [[ "$(<"${APP_PATH}/marker")" == 'other build' ]]
}

function test_build_dmg_when_output_path_is_missing_then_skips_build {
    # Arrange
    local build_stub="${TEMP_ROOT}/missing-path-step-build"
    local verify_stub="${TEMP_ROOT}/missing-path-step-verify"
    local package_stub="${TEMP_ROOT}/missing-path-step-package"
    create_step_stub "${build_stub}"
    create_step_stub "${verify_stub}"
    create_step_stub "${package_stub}"
    : > "${CALL_LOG}"

    # Act & Assert
    if run_dmg_builder "${build_stub}" "${verify_stub}" "${package_stub}" >/dev/null 2>&1; then
        print -u2 "Expected a missing output path to fail."
        return 1
    fi
    [[ ! -s "${CALL_LOG}" ]]
}

test_build_dmg_when_output_path_is_provided_then_builds_verifies_and_packages_app
test_build_dmg_when_shared_app_changes_after_build_then_packages_its_staged_app
test_build_dmg_when_output_path_is_missing_then_skips_build

print "DMG build tests passed."
