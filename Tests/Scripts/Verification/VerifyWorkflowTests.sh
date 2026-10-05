#!/bin/zsh
set -euo pipefail
readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-verify-tests.XXXXXX)"
trap 'rm -rf "${TEMP_ROOT}"' EXIT
export MOCK_CALL_LOG="${TEMP_ROOT}/calls"
for name in unit component scripts gui e2e storekit language release; do
    cat > "${TEMP_ROOT}/${name}" <<'STUB'
#!/bin/zsh
print -r -- "${0:t}" >> "${MOCK_CALL_LOG}"
[[ "${0:t}" != "${FAIL_STEP:-}" ]] || exit "${FAIL_CODE:-1}"
STUB
    chmod +x "${TEMP_ROOT}/${name}"
done
function run_verify {
    BOUNDLESS_TRANSLATOR_UNIT_TEST_EXECUTABLE="${TEMP_ROOT}/unit" \
    BOUNDLESS_TRANSLATOR_COMPONENT_TEST_EXECUTABLE="${TEMP_ROOT}/component" \
    BOUNDLESS_TRANSLATOR_SCRIPT_TEST_EXECUTABLE="${TEMP_ROOT}/scripts" \
    BOUNDLESS_TRANSLATOR_GUI_TEST_EXECUTABLE="${TEMP_ROOT}/gui" \
    BOUNDLESS_TRANSLATOR_E2E_TEST_EXECUTABLE="${TEMP_ROOT}/e2e" \
    BOUNDLESS_TRANSLATOR_STOREKIT_TEST_EXECUTABLE="${TEMP_ROOT}/storekit" \
    BOUNDLESS_TRANSLATOR_LANGUAGE_TEST_EXECUTABLE="${TEMP_ROOT}/language" \
    BOUNDLESS_TRANSLATOR_RELEASE_TEST_EXECUTABLE="${TEMP_ROOT}/release" \
        zsh "${PROJECT_ROOT}/Scripts/verify.sh" "$@"
}
function test_verify_when_all_pass_then_runs_every_level_once {
    # Arrange
    : > "${MOCK_CALL_LOG}"
    # Act
    run_verify > "${TEMP_ROOT}/output"
    # Assert
    [[ "$(<"${MOCK_CALL_LOG}")" == $'unit\ncomponent\nscripts\ngui\ne2e\nstorekit\nlanguage\nrelease' ]]
    local summary="$(sed -n '/^Verification summary:/,$p' "${TEMP_ROOT}/output")"
    [[ "$summary" == $'Verification summary:\n  Unit: PASS\n  Component: PASS\n  Scripts: PASS\n  GUI: PASS\n  E2E: PASS\n  StoreKit: PASS\n  Languages: PASS\n  Release: PASS\nTotal: 8 passed, 0 failed, 0 skipped\nVerification passed.' ]]
    grep -q 'Verification passed' "${TEMP_ROOT}/output"
}
function test_verify_when_failure_or_skip_then_finishes_all_levels_and_returns_nonzero {
    local code
    for code in 1 78; do
        # Arrange
        : > "${MOCK_CALL_LOG}"
        local result=0
        # Act
        FAIL_STEP=storekit FAIL_CODE="$code" run_verify > "${TEMP_ROOT}/output" 2>&1 || result=$?
        # Assert
        [[ "$result" != 0 ]]
        [[ "$(tail -n 1 "${MOCK_CALL_LOG}")" == release ]]
        [[ "$(wc -l < "${MOCK_CALL_LOG}" | tr -d ' ')" == 8 ]]
        local summary="$(sed -n '/^Verification summary:/,$p' "${TEMP_ROOT}/output")"
        [[ "$summary" == *'Release: PASS'* ]]
        if (( code == 78 )); then
            [[ "$summary" == *'StoreKit: SKIPPED (environment unavailable)'* ]]
            [[ "$summary" == *'Total: 7 passed, 0 failed, 1 skipped'* ]]
        else
            [[ "$summary" == *'StoreKit: FAIL (exit 1)'* ]]
            [[ "$summary" == *'Total: 7 passed, 1 failed, 0 skipped'* ]]
        fi
        ! grep -q 'Verification passed' "${TEMP_ROOT}/output"
    done
}
function test_verify_when_partial_mode_requested_then_rejects_before_running {
    # Arrange
    : > "${MOCK_CALL_LOG}"
    # Act & Assert
    if run_verify features >/dev/null 2>&1; then return 1; fi
    [[ ! -s "${MOCK_CALL_LOG}" ]]
}
test_verify_when_all_pass_then_runs_every_level_once
test_verify_when_failure_or_skip_then_finishes_all_levels_and_returns_nonzero
test_verify_when_partial_mode_requested_then_rejects_before_running
print 'Verification workflow tests passed.'
