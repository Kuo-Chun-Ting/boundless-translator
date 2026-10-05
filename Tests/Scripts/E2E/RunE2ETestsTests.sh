#!/bin/zsh
set -euo pipefail
readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-e2e-runner-tests.XXXXXX)"
trap 'rm -rf "${TEMP_ROOT}"' EXIT
export MOCK_CALL_LOG="${TEMP_ROOT}/calls"
cat > "${TEMP_ROOT}/build-app" <<'STUB'
#!/bin/zsh
print -r -- "build ${BOUNDLESS_TRANSLATOR_PRODUCT_NAME} ${BOUNDLESS_TRANSLATOR_BUNDLE_IDENTIFIER}" >> "${MOCK_CALL_LOG}"
[[ "${FAIL_BUILD:-0}" == 0 ]] || exit 42
mkdir -p "${BOUNDLESS_TRANSLATOR_BUILD_ROOT}/${BOUNDLESS_TRANSLATOR_PRODUCT_NAME}.app/Contents/MacOS"
plutil -create xml1 "${BOUNDLESS_TRANSLATOR_BUILD_ROOT}/${BOUNDLESS_TRANSLATOR_PRODUCT_NAME}.app/Contents/Info.plist"
plutil -insert CFBundleExecutable -string "${BOUNDLESS_TRANSLATOR_PRODUCT_NAME}" "${BOUNDLESS_TRANSLATOR_BUILD_ROOT}/${BOUNDLESS_TRANSLATOR_PRODUCT_NAME}.app/Contents/Info.plist"
STUB
cat > "${TEMP_ROOT}/reset" <<'STUB'
#!/bin/zsh
print -r -- "reset $* ${BOUNDLESS_TRANSLATOR_APP_PATH}" >> "${MOCK_CALL_LOG}"
STUB
cat > "${TEMP_ROOT}/xcodebuild" <<'STUB'
#!/bin/zsh
print -r -- "xcodebuild $*" >> "${MOCK_CALL_LOG}"
exit "${FAIL_XCODE:-0}"
STUB
cat > "${TEMP_ROOT}/xcrun" <<'STUB'
#!/bin/zsh
print '{"totalTestCount":1,"passedTests":1,"failedTests":0,"skippedTests":0}'
STUB
cat > "${TEMP_ROOT}/forbidden" <<'STUB'
#!/bin/zsh
print forbidden >> "${MOCK_CALL_LOG}"
exit 90
STUB
cat > "${TEMP_ROOT}/pkill" <<'STUB'
#!/bin/zsh
exit 1
STUB
chmod +x "${TEMP_ROOT}"/{build-app,reset,xcodebuild,xcrun,forbidden,pkill}
function run_e2e {
    PATH="${TEMP_ROOT}:${PATH}" \
    BOUNDLESS_TRANSLATOR_E2E_ROOT="${TEMP_ROOT}/E2E" \
    BOUNDLESS_TRANSLATOR_E2E_SKIP_APPROVAL_WAIT=1 \
    BOUNDLESS_TRANSLATOR_BUILD_APP_EXECUTABLE="${TEMP_ROOT}/build-app" \
    BOUNDLESS_TRANSLATOR_RELEASE_DMG_EXECUTABLE="${TEMP_ROOT}/forbidden" \
    BOUNDLESS_TRANSLATOR_HDIUTIL_EXECUTABLE="${TEMP_ROOT}/forbidden" \
    BOUNDLESS_TRANSLATOR_RESET_PERMISSIONS_EXECUTABLE="${TEMP_ROOT}/reset" \
    BOUNDLESS_TRANSLATOR_XCODEBUILD_EXECUTABLE="${TEMP_ROOT}/xcodebuild" \
        zsh "${PROJECT_ROOT}/Scripts/run_e2e_tests.sh" "$@"
}
function test_e2e_when_run_then_builds_app_without_installing_dmg_or_running_gui {
    # Arrange
    : > "${MOCK_CALL_LOG}"
    # Act
    run_e2e
    # Assert
    local calls="$(<"${MOCK_CALL_LOG}")"
    [[ "$calls" == *'build Boundless Translator E2E com.lillard.BoundlessTranslator.e2e'* ]]
    [[ "$calls" == *"BOUNDLESS_TRANSLATOR_E2E_APP_PATH=${TEMP_ROOT}/E2E/App/Boundless Translator E2E.app"* ]]
    [[ "$calls" == *'-only-testing:BoundlessTranslatorE2ETests/ScreenshotE2ETests'* ]]
    [[ "$calls" == *'-only-testing:BoundlessTranslatorE2ETests/SelectionTranslationE2ETests'* ]]
    [[ "$calls" != *GUITests* && "$calls" != *forbidden* && "$calls" != *'reset '* ]]
}
function test_e2e_when_permission_setup_requested_then_resets_only_e2e_and_runs_both_permission_tests {
    # Arrange
    : > "${MOCK_CALL_LOG}"
    # Act
    run_e2e --from-permission-setup
    # Assert
    [[ "$(<"${MOCK_CALL_LOG}")" == *"reset e2e ${TEMP_ROOT}/E2E/App/Boundless Translator E2E.app"* ]]
    [[ "$(grep -c '^xcodebuild ' "${MOCK_CALL_LOG}")" == 3 ]]
}
function test_e2e_when_filter_given_then_runs_only_requested_case {
    # Arrange
    : > "${MOCK_CALL_LOG}"
    # Act
    run_e2e ScreenshotE2ETests/example
    # Assert
    [[ "$(<"${MOCK_CALL_LOG}")" == *'-only-testing:BoundlessTranslatorE2ETests/ScreenshotE2ETests/example'* ]]
    [[ "$(<"${MOCK_CALL_LOG}")" != *'-only-testing:BoundlessTranslatorE2ETests/SelectionTranslationE2ETests'* ]]
}
function test_e2e_when_build_or_tests_fail_then_returns_failure {
    # Act & Assert
    if FAIL_BUILD=1 run_e2e >/dev/null 2>&1; then return 1; fi
    if FAIL_XCODE=65 run_e2e >/dev/null 2>&1; then return 1; fi
    : > "${MOCK_CALL_LOG}"
    if run_e2e --unknown >/dev/null 2>&1; then return 1; fi
    [[ ! -s "${MOCK_CALL_LOG}" ]]
}
test_e2e_when_run_then_builds_app_without_installing_dmg_or_running_gui
test_e2e_when_permission_setup_requested_then_resets_only_e2e_and_runs_both_permission_tests
test_e2e_when_filter_given_then_runs_only_requested_case
test_e2e_when_build_or_tests_fail_then_returns_failure
print 'E2E runner tests passed.'
