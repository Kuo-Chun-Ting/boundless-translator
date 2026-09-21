#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"
readonly RESETTER="${PROJECT_ROOT}/Scripts/reset_test_permissions.sh"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-permission-reset-tests.XXXXXX)"
readonly CALL_LOG="${TEMP_ROOT}/calls.log"
readonly APP_PATH="${TEMP_ROOT}/Boundless Translator E2E.app"
readonly PKILL_STUB="${TEMP_ROOT}/mock-pkill"
readonly TCCUTIL_STUB="${TEMP_ROOT}/mock-tccutil"

function clean_up {
    rm -rf "${TEMP_ROOT}"
}
trap clean_up EXIT

function create_command_stubs {
    cat > "${PKILL_STUB}" <<'EOF'
#!/bin/zsh
print -r -- "pkill $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
exit "${BOUNDLESS_TRANSLATOR_TEST_PKILL_EXIT_CODE:-0}"
EOF

    cat > "${TCCUTIL_STUB}" <<'EOF'
#!/bin/zsh
print -r -- "tccutil $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
if [[ "${BOUNDLESS_TRANSLATOR_TEST_FAIL_SERVICE:-}" == "$2" ]]; then
    exit 1
fi
EOF

    chmod +x "${PKILL_STUB}" "${TCCUTIL_STUB}"
}

function create_app_fixture {
    local info_plist="${APP_PATH}/Contents/Info.plist"
    mkdir -p "${APP_PATH}/Contents/MacOS"
    plutil -create xml1 "${info_plist}"
    plutil -insert CFBundleExecutable -string 'Boundless Translator E2E' "${info_plist}"
}

function run_resetter {
    BOUNDLESS_TRANSLATOR_BUNDLE_IDENTIFIER="com.example.BoundlessTranslator" \
    BOUNDLESS_TRANSLATOR_APP_PATH="${APP_PATH}" \
    BOUNDLESS_TRANSLATOR_PKILL_EXECUTABLE="${PKILL_STUB}" \
    BOUNDLESS_TRANSLATOR_TCCUTIL_EXECUTABLE="${TCCUTIL_STUB}" \
    BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
        zsh "${RESETTER}"
}

function test_reset_test_permissions_when_no_app_is_specified_then_defaults_to_production_app {
    # Arrange
    local script_contents="$(<"${RESETTER}")"

    # Act & Assert
    [[ "${script_contents}" == *'${BOUNDLESS_TRANSLATOR_BUNDLE_IDENTIFIER:-com.lillard.BoundlessTranslator}'* ]]
    [[ "${script_contents}" == *'${BOUNDLESS_TRANSLATOR_APP_PATH:-/Applications/Boundless Translator.app}'* ]]
    [[ "${script_contents}" != *'readonly PROJECT_ROOT='* ]]
}

function test_reset_test_permissions_when_app_is_running_then_quits_app_and_resets_both_permissions {
    # Arrange
    : > "${CALL_LOG}"

    # Act
    run_resetter >/dev/null

    # Assert
    [[ "$(<"${CALL_LOG}")" == "pkill -f ^${APP_PATH}/Contents/MacOS/Boundless Translator E2E([[:space:]]|$)"$'\n''tccutil reset Accessibility com.example.BoundlessTranslator'$'\n''tccutil reset ScreenCapture com.example.BoundlessTranslator' ]]
}

function test_reset_test_permissions_when_app_is_not_running_then_still_resets_both_permissions {
    # Arrange
    : > "${CALL_LOG}"

    # Act
    BOUNDLESS_TRANSLATOR_TEST_PKILL_EXIT_CODE=1 run_resetter >/dev/null

    # Assert
    [[ "$(<"${CALL_LOG}")" == "pkill -f ^${APP_PATH}/Contents/MacOS/Boundless Translator E2E([[:space:]]|$)"$'\n''tccutil reset Accessibility com.example.BoundlessTranslator'$'\n''tccutil reset ScreenCapture com.example.BoundlessTranslator' ]]
}

function test_reset_test_permissions_when_accessibility_reset_fails_then_stops_before_screen_capture_reset {
    # Arrange
    : > "${CALL_LOG}"

    # Act & Assert
    if BOUNDLESS_TRANSLATOR_TEST_FAIL_SERVICE=Accessibility run_resetter >/dev/null 2>&1; then
        print -u2 "Expected an Accessibility reset failure to stop the script."
        return 1
    fi
    [[ "$(<"${CALL_LOG}")" == "pkill -f ^${APP_PATH}/Contents/MacOS/Boundless Translator E2E([[:space:]]|$)"$'\n''tccutil reset Accessibility com.example.BoundlessTranslator' ]]
}

create_command_stubs
create_app_fixture
test_reset_test_permissions_when_no_app_is_specified_then_defaults_to_production_app
test_reset_test_permissions_when_app_is_running_then_quits_app_and_resets_both_permissions
test_reset_test_permissions_when_app_is_not_running_then_still_resets_both_permissions
test_reset_test_permissions_when_accessibility_reset_fails_then_stops_before_screen_capture_reset

print "Test permission reset tests passed."
