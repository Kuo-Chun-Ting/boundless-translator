#!/bin/zsh
set -euo pipefail
readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-swift-runner-tests.XXXXXX)"
trap 'rm -rf "${TEMP_ROOT}"' EXIT
export MOCK_CALL_LOG="${TEMP_ROOT}/calls"
cat > "${TEMP_ROOT}/swift" <<'STUB'
#!/bin/zsh
print -r -- "$*" >> "${MOCK_CALL_LOG}"
[[ "${FAIL_SWIFT:-0}" == 0 ]] || exit 65
[[ "${MISSING_REPORT:-0}" == 0 ]] || exit 0
while (( $# )); do
    if [[ "$1" == --xunit-output ]]; then
        report="${2:r}-swift-testing.xml"
        print '<testsuites><testsuite tests="2" errors="0" failures="0"/></testsuites>' > "$report"
        break
    fi
    shift
done
STUB
chmod +x "${TEMP_ROOT}/swift"
function run_tests {
    local level="$1"
    shift
    BOUNDLESS_TRANSLATOR_SWIFT_EXECUTABLE="${TEMP_ROOT}/swift" \
    BOUNDLESS_TRANSLATOR_VERIFICATION_BUILD_ROOT="${TEMP_ROOT}/Build" \
        zsh "${PROJECT_ROOT}/Scripts/run_${level}_tests.sh" "$@"
}
function test_swift_runner_when_started_then_runs_only_its_target_once {
    local level target
    for level in unit component; do
        # Arrange
        target=BoundlessTranslatorUnitTests
        [[ "$level" != component ]] || target=BoundlessTranslatorComponentTests
        : > "${MOCK_CALL_LOG}"
        # Act
        run_tests "$level"
        # Assert
        [[ "$(wc -l < "${MOCK_CALL_LOG}" | tr -d ' ')" == 1 ]]
        [[ "$(sed -n '1p' "${MOCK_CALL_LOG}")" == *"--filter ${target}"* ]]
        [[ "$(sed -n '1p' "${MOCK_CALL_LOG}")" != *SUBSCRIPTION_REQUIRED* ]]
    done
}
function test_swift_runner_when_build_fails_or_report_missing_then_returns_failure {
    # Arrange / Act / Assert
    if FAIL_SWIFT=1 run_tests unit >/dev/null 2>&1; then return 1; fi
    if MISSING_REPORT=1 run_tests component >/dev/null 2>&1; then return 1; fi
}
test_swift_runner_when_started_then_runs_only_its_target_once
test_swift_runner_when_build_fails_or_report_missing_then_returns_failure
print 'Swift test runner tests passed.'
