#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly STOREKIT_TESTER="${PROJECT_ROOT}/Scripts/Tests/test_storekit.sh"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-test-storekit-script-tests.XXXXXX)"
readonly CALL_LOG="${TEMP_ROOT}/calls.log"
readonly OUTPUT_LOG="${TEMP_ROOT}/output.log"
runner_exit_status=0

function clean_up {
    rm -rf "${TEMP_ROOT}"
}
trap clean_up EXIT

function create_tool_doubles {
    cat > "${TEMP_ROOT}/sw_vers" <<'EOF'
#!/bin/zsh
case "$1" in
    -productVersion) print -r -- "${STUB_MACOS_VERSION}" ;;
    -buildVersion) print -r -- "${STUB_MACOS_BUILD}" ;;
    *) exit 2 ;;
esac
EOF
    cat > "${TEMP_ROOT}/xcodebuild" <<'EOF'
#!/bin/zsh
print -r -- "xcodebuild $*" >> "${MOCK_CALL_LOG}"
if [[ "$1" == -version ]]; then
    print -r -- "Xcode ${STUB_XCODE_VERSION}"
    print -r -- "Build version ${STUB_XCODE_BUILD}"
    exit "${STUB_VERSION_EXIT_STATUS}"
fi
exit "${STUB_TEST_EXIT_STATUS}"
EOF
    cat > "${TEMP_ROOT}/xcrun" <<'EOF'
#!/bin/zsh
print -r -- "xcrun $*" >> "${MOCK_CALL_LOG}"
print -r -- '{"totalTestCount":3,"passedTests":3,"failedTests":0}'
exit "${STUB_SUMMARY_EXIT_STATUS}"
EOF
    chmod +x "${TEMP_ROOT}/sw_vers" "${TEMP_ROOT}/xcodebuild" "${TEMP_ROOT}/xcrun"
}

function reset_environment {
    stub_macos_version=26.5.2
    stub_macos_build=25F84
    stub_xcode_version=26.6
    stub_xcode_build=17F113
    stub_test_exit_status=0
    stub_version_exit_status=0
    stub_summary_exit_status=0
    : > "${CALL_LOG}"
}

function run_storekit {
    if PATH="${TEMP_ROOT}:${PATH}" MOCK_CALL_LOG="${CALL_LOG}" \
        STUB_MACOS_VERSION="${stub_macos_version}" STUB_MACOS_BUILD="${stub_macos_build}" \
        STUB_XCODE_VERSION="${stub_xcode_version}" STUB_XCODE_BUILD="${stub_xcode_build}" \
        STUB_TEST_EXIT_STATUS="${stub_test_exit_status}" STUB_VERSION_EXIT_STATUS="${stub_version_exit_status}" \
        STUB_SUMMARY_EXIT_STATUS="${stub_summary_exit_status}" \
        zsh "${STOREKIT_TESTER}" "$@" > "${OUTPUT_LOG}" 2>&1; then
        runner_exit_status=0
    else
        runner_exit_status=$?
    fi
}

function test_test_storekit_when_exact_affected_environment_then_reports_skip_without_running_tests {
    # Arrange
    reset_environment

    # Act
    run_storekit

    # Assert
    if [[ "${runner_exit_status}" != 78 ]]; then
        print -u2 "Expected the known environment to return 78, got ${runner_exit_status}."
        return 1
    fi
    [[ "$(<"${CALL_LOG}")" == 'xcodebuild -version' ]]
    local output="$(<"${OUTPUT_LOG}")"
    [[ "${output}" == *'SKIPPED: 3 local StoreKit integration tests'* ]]
    [[ "${output}" == *'macOS 26.5.2 (25F84)'*'Xcode 26.6 (17F113)'* ]]
    [[ "${output}" == *'--force'* ]]
}

function assert_integration_ran {
    [[ "${runner_exit_status}" == 0 ]]
    local calls="$(<"${CALL_LOG}")"
    [[ "${calls}" == *'xcodebuild test '*'-scheme BoundlessTranslatorStoreKitTests '* ]]
    [[ "${calls}" == *'xcrun xcresulttool get test-results summary '* ]]
}

function test_test_storekit_when_any_environment_component_changes_then_runs_integration_tests {
    local changed_component
    for changed_component in macos_version macos_build xcode_version xcode_build; do
        # Arrange
        reset_environment
        case "${changed_component}" in
            macos_version) stub_macos_version=26.5.3 ;;
            macos_build) stub_macos_build=25F85 ;;
            xcode_version) stub_xcode_version=26.7 ;;
            xcode_build) stub_xcode_build=17F114 ;;
        esac

        # Act
        run_storekit

        # Assert
        assert_integration_ran
    done
}

function test_test_storekit_when_forced_in_affected_environment_then_runs_integration_tests {
    # Arrange
    reset_environment

    # Act
    run_storekit --force

    # Assert
    assert_integration_ran
}

function test_test_storekit_when_integration_fails_then_returns_failure {
    # Arrange
    reset_environment
    stub_macos_build=25F85
    stub_test_exit_status=65

    # Act
    run_storekit

    # Assert
    [[ "${runner_exit_status}" == 65 ]]
    [[ "$(<"${CALL_LOG}")" != *'xcrun '* ]]
}

function test_test_storekit_when_xcodebuild_returns_reserved_skip_status_then_reports_failure {
    # Arrange
    reset_environment
    stub_test_exit_status=78

    # Act
    run_storekit --force

    # Assert
    if [[ "${runner_exit_status}" == 0 || "${runner_exit_status}" == 78 ]]; then
        print -u2 "Expected xcodebuild exit 78 to remain a failure, got ${runner_exit_status}."
        return 1
    fi
    [[ "$(<"${CALL_LOG}")" != *'xcrun '* ]]
}

function test_test_storekit_when_environment_lookup_fails_then_stops_with_failure {
    # Arrange
    reset_environment
    stub_version_exit_status=78

    # Act
    run_storekit

    # Assert
    [[ "${runner_exit_status}" != 0 && "${runner_exit_status}" != 78 ]]
    [[ "$(<"${CALL_LOG}")" == 'xcodebuild -version' ]]
}

function test_test_storekit_when_result_lookup_fails_then_reports_failure {
    # Arrange
    reset_environment
    stub_summary_exit_status=78

    # Act
    run_storekit --force

    # Assert
    if [[ "${runner_exit_status}" == 0 || "${runner_exit_status}" == 78 ]]; then
        print -u2 "Expected result lookup failure to remain a failure, got ${runner_exit_status}."
        return 1
    fi
}

function test_test_storekit_when_arguments_are_invalid_then_stops_before_tests {
    local argument
    for argument in --unknown '--force --force'; do
        # Arrange
        reset_environment

        # Act
        run_storekit ${=argument}

        # Assert
        [[ "${runner_exit_status}" == 2 ]]
        [[ ! -s "${CALL_LOG}" ]]
    done
}

create_tool_doubles
test_test_storekit_when_exact_affected_environment_then_reports_skip_without_running_tests
test_test_storekit_when_any_environment_component_changes_then_runs_integration_tests
test_test_storekit_when_forced_in_affected_environment_then_runs_integration_tests
test_test_storekit_when_integration_fails_then_returns_failure
test_test_storekit_when_environment_lookup_fails_then_stops_with_failure
test_test_storekit_when_arguments_are_invalid_then_stops_before_tests
test_test_storekit_when_xcodebuild_returns_reserved_skip_status_then_reports_failure
test_test_storekit_when_result_lookup_fails_then_reports_failure

print "StoreKit test script tests passed."
