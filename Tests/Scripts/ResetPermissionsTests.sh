#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"
readonly RESETTER="${PROJECT_ROOT}/Scripts/reset_permissions.sh"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-permission-reset-tests.XXXXXX)"
readonly CALL_LOG="${TEMP_ROOT}/calls.log"
readonly APP_PATH="${TEMP_ROOT}/Boundless Translator E2E.app"
readonly PKILL_MOCK="${TEMP_ROOT}/mock-pkill"
readonly TCCUTIL_MOCK="${TEMP_ROOT}/mock-tccutil"

function clean_up {
    rm -rf "${TEMP_ROOT}"
}
trap clean_up EXIT

function create_command_mocks {
    cat > "${PKILL_MOCK}" <<'EOF'
#!/bin/zsh
print -r -- "pkill $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
exit "${BOUNDLESS_TRANSLATOR_TEST_PKILL_EXIT_CODE:-0}"
EOF

    cat > "${TCCUTIL_MOCK}" <<'EOF'
#!/bin/zsh
print -r -- "tccutil $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
if [[ "${BOUNDLESS_TRANSLATOR_TEST_FAIL_SERVICE:-}" == "$2" ]]; then
    exit 1
fi
EOF

    chmod +x "${PKILL_MOCK}" "${TCCUTIL_MOCK}"
}

function create_app_fixture {
    local info_plist="${APP_PATH}/Contents/Info.plist"
    mkdir -p "${APP_PATH}/Contents/MacOS"
    plutil -create xml1 "${info_plist}"
    plutil -insert CFBundleExecutable -string 'Boundless Translator E2E' "${info_plist}"
}

function run_resetter {
    BOUNDLESS_TRANSLATOR_APP_PATH="${APP_PATH}" \
    BOUNDLESS_TRANSLATOR_PKILL_EXECUTABLE="${PKILL_MOCK}" \
    BOUNDLESS_TRANSLATOR_TCCUTIL_EXECUTABLE="${TCCUTIL_MOCK}" \
    BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
        zsh "${RESETTER}" "${1:-e2e}"
}

function test_reset_permissions_when_edition_is_selected_then_resets_only_its_permissions {
    # Arrange
    local edition identifier
    for edition in dmg app-store e2e; do
        case "${edition}" in
            dmg) identifier='com.lillard.BoundlessTranslator.dmgtest' ;;
            app-store) identifier='com.lillard.BoundlessTranslator' ;;
            e2e) identifier='com.lillard.BoundlessTranslator.e2e' ;;
        esac
        : > "${CALL_LOG}"

        # Act
        run_resetter "${edition}" >/dev/null

        # Assert
        [[ "$(<"${CALL_LOG}")" == "pkill -f ^${APP_PATH}/Contents/MacOS/Boundless Translator E2E([[:space:]]|$)"$'\n'"tccutil reset Accessibility ${identifier}"$'\n'"tccutil reset ScreenCapture ${identifier}" ]]
    done
}


function test_reset_permissions_when_using_default_path_then_targets_selected_edition {
    # Arrange
    local mock_bin="${TEMP_ROOT}/bin"
    mkdir -p "${mock_bin}"
    cat > "${mock_bin}/plutil" <<'MOCK'
#!/bin/zsh
print -r -- "plutil $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
print -r -- Executable
MOCK
    chmod +x "${mock_bin}/plutil"
    local edition app_path
    for edition in dmg app-store e2e; do
        case "${edition}" in
            dmg) app_path='/Applications/Boundless Translator DMG Test.app' ;;
            app-store) app_path='/Applications/Boundless Translator.app' ;;
            e2e) app_path="${PROJECT_ROOT}/Build/E2E/Installed/Boundless Translator E2E.app" ;;
        esac
        : > "${CALL_LOG}"

        # Act
        PATH="${mock_bin}:${PATH}" \
        BOUNDLESS_TRANSLATOR_PKILL_EXECUTABLE="${PKILL_MOCK}" \
        BOUNDLESS_TRANSLATOR_TCCUTIL_EXECUTABLE="${TCCUTIL_MOCK}" \
        BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
            zsh "${RESETTER}" "${edition}" >/dev/null

        # Assert
        [[ "$(<"${CALL_LOG}")" == "plutil -extract CFBundleExecutable raw ${app_path}/Contents/Info.plist"$'\n'"pkill -f ^${app_path}/Contents/MacOS/Executable([[:space:]]|$)"$'\n'* ]]
    done
}

function test_reset_permissions_when_app_is_running_then_quits_app_and_resets_both_permissions {
    # Arrange
    : > "${CALL_LOG}"

    # Act
    run_resetter >/dev/null

    # Assert
    [[ "$(<"${CALL_LOG}")" == "pkill -f ^${APP_PATH}/Contents/MacOS/Boundless Translator E2E([[:space:]]|$)"$'\n''tccutil reset Accessibility com.lillard.BoundlessTranslator.e2e'$'\n''tccutil reset ScreenCapture com.lillard.BoundlessTranslator.e2e' ]]
}

function test_reset_permissions_when_app_is_not_running_then_still_resets_both_permissions {
    # Arrange
    : > "${CALL_LOG}"

    # Act
    BOUNDLESS_TRANSLATOR_TEST_PKILL_EXIT_CODE=1 run_resetter >/dev/null

    # Assert
    [[ "$(<"${CALL_LOG}")" == "pkill -f ^${APP_PATH}/Contents/MacOS/Boundless Translator E2E([[:space:]]|$)"$'\n''tccutil reset Accessibility com.lillard.BoundlessTranslator.e2e'$'\n''tccutil reset ScreenCapture com.lillard.BoundlessTranslator.e2e' ]]
}

function test_reset_permissions_when_accessibility_reset_fails_then_stops_before_screen_capture_reset {
    # Arrange
    : > "${CALL_LOG}"

    # Act & Assert
    if BOUNDLESS_TRANSLATOR_TEST_FAIL_SERVICE=Accessibility run_resetter >/dev/null 2>&1; then
        print -u2 "Expected an Accessibility reset failure to stop the script."
        return 1
    fi
    [[ "$(<"${CALL_LOG}")" == "pkill -f ^${APP_PATH}/Contents/MacOS/Boundless Translator E2E([[:space:]]|$)"$'\n''tccutil reset Accessibility com.lillard.BoundlessTranslator.e2e' ]]
}

create_command_mocks
create_app_fixture
test_reset_permissions_when_using_default_path_then_targets_selected_edition
test_reset_permissions_when_edition_is_selected_then_resets_only_its_permissions
test_reset_permissions_when_app_is_running_then_quits_app_and_resets_both_permissions
test_reset_permissions_when_app_is_not_running_then_still_resets_both_permissions
test_reset_permissions_when_accessibility_reset_fails_then_stops_before_screen_capture_reset

print "Test permission reset tests passed."
