#!/bin/zsh
set -euo pipefail
readonly PROJECT_ROOT="${0:A:h:h}"
if (( $# )); then
    print -u2 'Usage: Scripts/verify.sh (all checks; use Scripts/run_*_tests.sh for individual levels)'
    exit 2
fi

typeset -a summary=()
integer passed=0 failed=0 skipped=0
function run_check {
    local name="$1"
    local executable="$2"
    local result=0
    print "Verifying ${name}…"
    "${executable}" || result=$?
    case "${result}" in
        0)
            print "PASS: ${name}"
            summary+=("${name}: PASS")
            (( passed += 1 )) ;;
        78)
            summary+=("${name}: SKIPPED (environment unavailable)")
            (( skipped += 1 )) ;;
        *)
            summary+=("${name}: FAIL (exit ${result})")
            (( failed += 1 )) ;;
    esac
}

run_check Unit "${BOUNDLESS_TRANSLATOR_UNIT_TEST_EXECUTABLE:-${PROJECT_ROOT}/Scripts/run_unit_tests.sh}"
run_check Component "${BOUNDLESS_TRANSLATOR_COMPONENT_TEST_EXECUTABLE:-${PROJECT_ROOT}/Scripts/run_component_tests.sh}"
run_check Scripts "${BOUNDLESS_TRANSLATOR_SCRIPT_TEST_EXECUTABLE:-${PROJECT_ROOT}/Scripts/run_script_tests.sh}"
run_check GUI "${BOUNDLESS_TRANSLATOR_GUI_TEST_EXECUTABLE:-${PROJECT_ROOT}/Scripts/run_gui_tests.sh}"
run_check E2E "${BOUNDLESS_TRANSLATOR_E2E_TEST_EXECUTABLE:-${PROJECT_ROOT}/Scripts/run_e2e_tests.sh}"
run_check StoreKit "${BOUNDLESS_TRANSLATOR_STOREKIT_TEST_EXECUTABLE:-${PROJECT_ROOT}/Scripts/run_storekit_tests.sh}"
run_check Languages "${BOUNDLESS_TRANSLATOR_LANGUAGE_TEST_EXECUTABLE:-${PROJECT_ROOT}/Scripts/run_language_support_tests.sh}"
run_check Release "${BOUNDLESS_TRANSLATOR_RELEASE_TEST_EXECUTABLE:-${PROJECT_ROOT}/Scripts/run_release_tests.sh}"

print '\nVerification summary:'
printf '  %s\n' "${summary[@]}"
print "Total: ${passed} passed, ${failed} failed, ${skipped} skipped"
if (( failed + skipped )); then
    print -u2 'Verification incomplete.'
    exit 1
fi
print 'Verification passed.'
