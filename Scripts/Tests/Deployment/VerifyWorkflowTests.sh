#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly VERIFIER="${PROJECT_ROOT}/Scripts/verify.sh"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-verify-workflow-tests.XXXXXX)"
readonly CALL_LOG="${TEMP_ROOT}/calls.log"
readonly APP_PATH="${TEMP_ROOT}/Build/Boundless Translator.app"

function clean_up {
    rm -rf "${TEMP_ROOT}"
}
trap clean_up EXIT

function create_step_stub {
    local stub_path="$1"
    local stub_body="${2:-}"

    print '#!/bin/zsh' > "${stub_path}"
    print 'print -r -- "${0:t} $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"' >> "${stub_path}"
    if [[ -n "${stub_body}" ]]; then
        print -r -- "${stub_body}" >> "${stub_path}"
    fi
    chmod +x "${stub_path}"
}

function test_verify_when_steps_succeed_then_runs_every_automated_check_and_builds_app {
    # Arrange
    local swift_stub="${TEMP_ROOT}/step-swift"
    local gui_stub="${TEMP_ROOT}/step-gui"
    local build_stub="${TEMP_ROOT}/step-build"
    local app_verify_stub="${TEMP_ROOT}/step-app-verify"
    local deployment_stub="${TEMP_ROOT}/step-deployment"
    create_step_stub "${swift_stub}"
    create_step_stub "${gui_stub}"
    create_step_stub "${build_stub}" 'mkdir -p "${BOUNDLESS_TRANSLATOR_VERIFY_APP_PATH}"'
    create_step_stub "${app_verify_stub}"
    create_step_stub "${deployment_stub}"
    : > "${CALL_LOG}"

    # Act
    BOUNDLESS_TRANSLATOR_SWIFT_EXECUTABLE="${swift_stub}" \
    BOUNDLESS_TRANSLATOR_GUI_TEST_EXECUTABLE="${gui_stub}" \
    BOUNDLESS_TRANSLATOR_BUILD_EXECUTABLE="${build_stub}" \
    BOUNDLESS_TRANSLATOR_APP_VERIFY_EXECUTABLE="${app_verify_stub}" \
    BOUNDLESS_TRANSLATOR_DEPLOYMENT_TEST_EXECUTABLE="${deployment_stub}" \
    BOUNDLESS_TRANSLATOR_VERIFY_APP_PATH="${APP_PATH}" \
    BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
        zsh "${VERIFIER}"

    # Assert
    local expected_calls
    expected_calls=$'step-swift test --disable-sandbox\n'
    expected_calls+=$'step-gui \n'
    expected_calls+=$'step-build \n'
    expected_calls+=$'step-app-verify '${APP_PATH}$'\n'
    expected_calls+=$'step-deployment '
    [[ "$(<"${CALL_LOG}")" == "${expected_calls}" ]]
}

test_verify_when_steps_succeed_then_runs_every_automated_check_and_builds_app

print "Verification workflow tests passed."
