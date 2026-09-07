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
    create_step_stub "${swift_stub}" 'if [[ "$3" == "--xunit-output" ]]; then print -r -- "<testsuites><testsuite tests=\"1\" errors=\"0\" failures=\"0\"><testcase name=\"example\"/></testsuite></testsuites>" > "${4:r}-swift-testing.xml"; fi'
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
    expected_calls=$'step-gui \n'
    expected_calls+=$'step-build \n'
    expected_calls+=$'step-app-verify '${APP_PATH}$'\n'
    expected_calls+=$'step-deployment '
    [[ "$(head -n 1 "${CALL_LOG}")" == 'step-swift test --disable-sandbox --xunit-output '* ]]
    [[ "$(tail -n +2 "${CALL_LOG}")" == "${expected_calls}" ]]
}

function test_verify_when_swift_exits_without_complete_results_then_stops_before_gui_and_build {
    # Arrange
    local swift_stub="${TEMP_ROOT}/incomplete-swift"
    local unexpected_step="${TEMP_ROOT}/unexpected-step"
    create_step_stub "${swift_stub}" 'if [[ "$3" == "--xunit-output" && -n "${BOUNDLESS_TRANSLATOR_TEST_REPORT_XML:-}" ]]; then print -r -- "${BOUNDLESS_TRANSLATOR_TEST_REPORT_XML}" > "${4:r}-swift-testing.xml"; fi'
    create_step_stub "${unexpected_step}"
    local report
    for report in '' '<testsuites><testsuite tests="1">' '<testsuites><testsuite tests="0" errors="0" failures="0"/></testsuites>' '<testsuites><testsuite tests="1" errors="0" failures="1"/></testsuites>'; do
        : > "${CALL_LOG}"

        # Act & Assert
        if BOUNDLESS_TRANSLATOR_SWIFT_EXECUTABLE="${swift_stub}" \
            BOUNDLESS_TRANSLATOR_GUI_TEST_EXECUTABLE="${unexpected_step}" \
            BOUNDLESS_TRANSLATOR_BUILD_EXECUTABLE="${unexpected_step}" \
            BOUNDLESS_TRANSLATOR_APP_VERIFY_EXECUTABLE="${unexpected_step}" \
            BOUNDLESS_TRANSLATOR_DEPLOYMENT_TEST_EXECUTABLE="${unexpected_step}" \
            BOUNDLESS_TRANSLATOR_TEST_REPORT_XML="${report}" \
            BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
                zsh "${VERIFIER}" > "${TEMP_ROOT}/output.log" 2>&1; then
            print -u2 "verify accepted missing, incomplete, empty or failing test results"
            return 1
        fi
        [[ "$(wc -l < "${CALL_LOG}" | tr -d ' ')" == 1 ]]
    done
}

test_verify_when_swift_exits_without_complete_results_then_stops_before_gui_and_build
test_verify_when_steps_succeed_then_runs_every_automated_check_and_builds_app

print "Verification workflow tests passed."
