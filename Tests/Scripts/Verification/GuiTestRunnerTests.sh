#!/bin/zsh
set -euo pipefail
readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-gui-runner-tests.XXXXXX)"
trap 'rm -rf "${TEMP_ROOT}"' EXIT
export MOCK_CALL_LOG="${TEMP_ROOT}/calls"
cat > "${TEMP_ROOT}/xcodebuild" <<'STUB'
#!/bin/zsh
print -r -- "$*" >> "${MOCK_CALL_LOG}"
exit "${BUILD_EXIT:-0}"
STUB
cat > "${TEMP_ROOT}/xcrun" <<'STUB'
#!/bin/zsh
print -r -- "${SUMMARY:-{\"totalTestCount\":1,\"passedTests\":1,\"failedTests\":0,\"skippedTests\":0}}"
STUB
chmod +x "${TEMP_ROOT}/xcodebuild" "${TEMP_ROOT}/xcrun"
function run_gui {
    PATH="${TEMP_ROOT}:${PATH}" BOUNDLESS_TRANSLATOR_GUI_ROOT="${TEMP_ROOT}/GUI" \
        BOUNDLESS_TRANSLATOR_E2E_ROOT="${TEMP_ROOT}/E2E" \
        zsh "${PROJECT_ROOT}/Scripts/run_gui_tests.sh" "$@"
}
function test_gui_when_image_case_selected_then_keeps_original_runner_and_filters_case {
    # Arrange
    : > "${MOCK_CALL_LOG}"
    # Act
    run_gui ImageTextFocusGUITests
    run_gui ImageTextFocusGUITests/test_focus_when_translationCloses_then_sourceCanSelectImmediately
    # Assert
    [[ "$(wc -l < "${MOCK_CALL_LOG}" | tr -d ' ')" == 2 ]]
    local calls="$(<"${MOCK_CALL_LOG}")"
    [[ "$calls" == *"-derivedDataPath ${TEMP_ROOT}/E2E/DerivedData"* ]]
    [[ "$calls" == *'-only-testing:BoundlessTranslatorE2ETests/ImageTextFocusGUITests'* ]]
    [[ "$calls" == *'-scheme BoundlessTranslatorE2ETests'* ]]
    [[ "$calls" != *'-scheme BoundlessTranslatorGUITests'* ]]
    [[ "$calls" != *'CODE_SIGN_IDENTITY='* && "$calls" != *'DEVELOPMENT_TEAM='* ]]
}
function test_gui_when_all_requested_then_selects_only_gui_cases_with_original_runners {
    # Arrange
    : > "${MOCK_CALL_LOG}"
    # Act
    run_gui
    # Assert
    [[ "$(wc -l < "${MOCK_CALL_LOG}" | tr -d ' ')" == 2 ]]
    local calls="$(<"${MOCK_CALL_LOG}")"
    [[ "$calls" == *'-only-testing:BoundlessTranslatorGUITests/HintPresentationGUITests'* ]]
    [[ "$calls" != *'DictionaryLookupCursorGUITests'* ]]
    [[ "$calls" == *'CODE_SIGN_IDENTITY=-'* ]]
    for name in ImageTextSelectionGUITests ImageTextFocusGUITests; do
        [[ "$calls" == *"-only-testing:BoundlessTranslatorE2ETests/${name}"* ]]
    done
    [[ "$calls" != *'/ScreenshotE2ETests'* && "$calls" != *'/SelectionTranslationE2ETests'* ]]
}
function test_gui_when_build_fails_or_no_tests_run_then_returns_failure {
    # Act & Assert
    if BUILD_EXIT=65 run_gui >/dev/null 2>&1; then return 1; fi
    if SUMMARY='{"totalTestCount":0,"passedTests":0,"failedTests":0}' run_gui >/dev/null 2>&1; then return 1; fi
    if SUMMARY='{"totalTestCount":2,"passedTests":1,"failedTests":0,"skippedTests":1}' run_gui >/dev/null 2>&1; then return 1; fi
}
test_gui_when_image_case_selected_then_keeps_original_runner_and_filters_case
test_gui_when_all_requested_then_selects_only_gui_cases_with_original_runners
test_gui_when_build_fails_or_no_tests_run_then_returns_failure
print 'GUI runner tests passed.'
