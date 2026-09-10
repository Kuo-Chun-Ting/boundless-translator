#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly ALL_VERIFIER="${PROJECT_ROOT}/Scripts/verify.sh"
readonly FEATURE_VERIFIER="${PROJECT_ROOT}/Scripts/verify_features.sh"
readonly SUBSCRIPTION_VERIFIER="${PROJECT_ROOT}/Scripts/verify_subscription.sh"
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

function create_passing_steps {
    create_step_stub "${TEMP_ROOT}/step-swift" 'if [[ "$3" == "--xunit-output" ]]; then print -r -- "<testsuites><testsuite tests=\"1\" errors=\"0\" failures=\"0\"><testcase name=\"example\"/></testsuite></testsuites>" > "${4:r}-swift-testing.xml"; fi'
    create_step_stub "${TEMP_ROOT}/step-gui"
    create_step_stub "${TEMP_ROOT}/step-storekit"
    create_step_stub "${TEMP_ROOT}/step-build" 'mkdir -p "${BOUNDLESS_TRANSLATOR_VERIFY_APP_PATH}"'
    create_step_stub "${TEMP_ROOT}/step-app-verify"
    create_step_stub "${TEMP_ROOT}/step-deployment"
}

function run_verifier {
    local verifier="$1"
    shift

    BOUNDLESS_TRANSLATOR_SWIFT_EXECUTABLE="${TEMP_ROOT}/step-swift" \
    BOUNDLESS_TRANSLATOR_GUI_TEST_EXECUTABLE="${TEMP_ROOT}/step-gui" \
    BOUNDLESS_TRANSLATOR_STOREKIT_TEST_EXECUTABLE="${TEMP_ROOT}/step-storekit" \
    BOUNDLESS_TRANSLATOR_BUILD_EXECUTABLE="${TEMP_ROOT}/step-build" \
    BOUNDLESS_TRANSLATOR_APP_VERIFY_EXECUTABLE="${TEMP_ROOT}/step-app-verify" \
    BOUNDLESS_TRANSLATOR_DEPLOYMENT_TEST_EXECUTABLE="${TEMP_ROOT}/step-deployment" \
    BOUNDLESS_TRANSLATOR_VERIFY_APP_PATH="${APP_PATH}" \
    BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
        zsh "${verifier}" "$@"
}

function test_verify_features_when_steps_succeed_then_runs_only_free_feature_checks {
    # Arrange
    create_passing_steps
    : > "${CALL_LOG}"

    # Act
    run_verifier "${FEATURE_VERIFIER}"

    # Assert
    [[ "$(wc -l < "${CALL_LOG}" | tr -d ' ')" == 5 ]]
    local swift_call="$(sed -n '1p' "${CALL_LOG}")"
    [[ "${swift_call}" == 'step-swift test --disable-sandbox --xunit-output '* ]]
    [[ "${swift_call}" != *SUBSCRIPTION_REQUIRED* ]]
    [[ "${swift_call}" == *'--scratch-path '*'/features'* ]]
    [[ "$(sed -n '2p' "${CALL_LOG}")" == 'step-gui ' ]]
    [[ "$(sed -n '3p' "${CALL_LOG}")" == 'step-build ' ]]
    [[ "$(sed -n '4p' "${CALL_LOG}")" == "step-app-verify ${APP_PATH}" ]]
    [[ "$(sed -n '5p' "${CALL_LOG}")" == 'step-deployment features' ]]
}

function test_verify_subscription_when_steps_succeed_then_runs_only_subscription_checks {
    # Arrange
    create_passing_steps
    : > "${CALL_LOG}"

    # Act
    run_verifier "${SUBSCRIPTION_VERIFIER}"

    # Assert
    [[ "$(wc -l < "${CALL_LOG}" | tr -d ' ')" == 3 ]]
    local swift_call="$(sed -n '1p' "${CALL_LOG}")"
    [[ "${swift_call}" == 'step-swift test --disable-sandbox --xunit-output '*'-Xswiftc -DSUBSCRIPTION_REQUIRED'* ]]
    [[ "${swift_call}" == *'--scratch-path '*'/subscription'* ]]
    [[ "$(sed -n '2p' "${CALL_LOG}")" == 'step-storekit ' ]]
    [[ "$(sed -n '3p' "${CALL_LOG}")" == 'step-deployment subscription' ]]
}

function test_verify_when_steps_succeed_then_runs_features_before_subscription {
    # Arrange
    create_passing_steps
    : > "${CALL_LOG}"

    # Act
    run_verifier "${ALL_VERIFIER}"

    # Assert
    [[ "$(wc -l < "${CALL_LOG}" | tr -d ' ')" == 8 ]]
    [[ "$(sed -n '1p' "${CALL_LOG}")" != *SUBSCRIPTION_REQUIRED* ]]
    [[ "$(sed -n '5p' "${CALL_LOG}")" == 'step-deployment features' ]]
    [[ "$(sed -n '6p' "${CALL_LOG}")" == *SUBSCRIPTION_REQUIRED* ]]
    [[ "$(sed -n '8p' "${CALL_LOG}")" == 'step-deployment subscription' ]]
}

function test_verify_features_when_results_are_incomplete_then_stops_before_gui {
    # Arrange
    create_step_stub "${TEMP_ROOT}/step-swift"
    create_step_stub "${TEMP_ROOT}/step-gui"
    create_step_stub "${TEMP_ROOT}/step-storekit"
    create_step_stub "${TEMP_ROOT}/step-build"
    create_step_stub "${TEMP_ROOT}/step-app-verify"
    create_step_stub "${TEMP_ROOT}/step-deployment"
    : > "${CALL_LOG}"

    # Act & Assert
    if run_verifier "${FEATURE_VERIFIER}" > "${TEMP_ROOT}/feature-output.log" 2>&1; then
        print -u2 'feature verification accepted missing test results'
        return 1
    fi
    [[ "$(wc -l < "${CALL_LOG}" | tr -d ' ')" == 1 ]]
}

function test_verify_subscription_when_storekit_fails_then_stops_before_packaging_checks {
    # Arrange
    create_passing_steps
    create_step_stub "${TEMP_ROOT}/step-storekit" 'exit 1'
    : > "${CALL_LOG}"

    # Act & Assert
    if run_verifier "${SUBSCRIPTION_VERIFIER}" > "${TEMP_ROOT}/subscription-output.log" 2>&1; then
        print -u2 'subscription verification accepted failing StoreKit tests'
        return 1
    fi
    [[ "$(wc -l < "${CALL_LOG}" | tr -d ' ')" == 2 ]]
    [[ "$(tail -n 1 "${CALL_LOG}")" == 'step-storekit ' ]]
}

function test_verify_subscription_when_storekit_is_skipped_then_finishes_checks_with_coverage_warning {
    # Arrange
    create_passing_steps
    create_step_stub "${TEMP_ROOT}/step-storekit" 'exit 78'
    : > "${CALL_LOG}"
    local exit_status=0

    # Act
    run_verifier "${SUBSCRIPTION_VERIFIER}" > "${TEMP_ROOT}/subscription-output.log" 2>&1 || exit_status=$?

    # Assert
    if [[ "$(wc -l < "${CALL_LOG}" | tr -d ' ')" != 3 ]]; then
        print -u2 'subscription verification stopped before deployment checks after a known StoreKit skip'
        return 1
    fi
    [[ "${exit_status}" == 0 ]]
    [[ "$(sed -n '1p' "${CALL_LOG}")" == *SUBSCRIPTION_REQUIRED* ]]
    [[ "$(tail -n 1 "${CALL_LOG}")" == 'step-deployment subscription' ]]
    local output="$(<"${TEMP_ROOT}/subscription-output.log")"
    [[ "${output}" == *'StoreKit integration coverage is incomplete'* ]]
    [[ "${output}" != *'Subscription verification passed.'* ]]
    [[ "${output}" != *'Verification passed.'* ]]
}

function test_verify_when_storekit_is_skipped_then_reports_incomplete_coverage_after_all_checks {
    # Arrange
    create_passing_steps
    create_step_stub "${TEMP_ROOT}/step-storekit" 'exit 78'
    : > "${CALL_LOG}"
    local exit_status=0

    # Act
    run_verifier "${ALL_VERIFIER}" > "${TEMP_ROOT}/all-output.log" 2>&1 || exit_status=$?

    # Assert
    [[ "${exit_status}" == 0 ]]
    [[ "$(wc -l < "${CALL_LOG}" | tr -d ' ')" == 8 ]]
    [[ "$(sed -n '6p' "${CALL_LOG}")" == *SUBSCRIPTION_REQUIRED* ]]
    [[ "$(tail -n 1 "${CALL_LOG}")" == 'step-deployment subscription' ]]
    local output="$(<"${TEMP_ROOT}/all-output.log")"
    [[ "${output}" == *'StoreKit integration coverage is incomplete'* ]]
    [[ "${output}" == *'release readiness is not established'* ]]
    [[ "${output}" != *'Verification passed.'* ]]
}

function test_verify_subscription_when_unit_tests_fail_then_stops_before_storekit {
    # Arrange
    create_passing_steps
    create_step_stub "${TEMP_ROOT}/step-swift" 'exit 65'
    create_step_stub "${TEMP_ROOT}/step-storekit" 'exit 78'
    : > "${CALL_LOG}"
    local exit_status=0

    # Act
    run_verifier "${SUBSCRIPTION_VERIFIER}" > "${TEMP_ROOT}/subscription-output.log" 2>&1 || exit_status=$?

    # Assert
    [[ "${exit_status}" == 65 ]]
    [[ "$(wc -l < "${CALL_LOG}" | tr -d ' ')" == 1 ]]
    [[ "$(<"${TEMP_ROOT}/subscription-output.log")" != *'checks passed'* ]]
}

function test_verify_subscription_when_deployment_fails_after_storekit_skip_then_returns_failure {
    # Arrange
    create_passing_steps
    create_step_stub "${TEMP_ROOT}/step-storekit" 'exit 78'
    create_step_stub "${TEMP_ROOT}/step-deployment" 'exit 5'
    : > "${CALL_LOG}"
    local exit_status=0

    # Act
    run_verifier "${SUBSCRIPTION_VERIFIER}" > "${TEMP_ROOT}/subscription-output.log" 2>&1 || exit_status=$?

    # Assert
    [[ "${exit_status}" == 5 ]]
    [[ "$(wc -l < "${CALL_LOG}" | tr -d ' ')" == 3 ]]
    [[ "$(<"${TEMP_ROOT}/subscription-output.log")" != *'checks passed'* ]]
}

test_verify_features_when_steps_succeed_then_runs_only_free_feature_checks
test_verify_subscription_when_steps_succeed_then_runs_only_subscription_checks
test_verify_when_steps_succeed_then_runs_features_before_subscription
test_verify_features_when_results_are_incomplete_then_stops_before_gui
test_verify_subscription_when_storekit_fails_then_stops_before_packaging_checks
test_verify_subscription_when_storekit_is_skipped_then_finishes_checks_with_coverage_warning
test_verify_when_storekit_is_skipped_then_reports_incomplete_coverage_after_all_checks
test_verify_subscription_when_unit_tests_fail_then_stops_before_storekit
test_verify_subscription_when_deployment_fails_after_storekit_skip_then_returns_failure

print "Verification workflow tests passed."
