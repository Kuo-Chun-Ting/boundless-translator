#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly RUNNER="${PROJECT_ROOT}/Scripts/run_e2e_tests.sh"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-e2e-runner-tests.XXXXXX)"
readonly E2E_ROOT="${TEMP_ROOT}/E2E"
readonly CALL_LOG="${TEMP_ROOT}/calls.log"
readonly RELEASE_STUB="${TEMP_ROOT}/release-dmg"
readonly RESET_STUB="${TEMP_ROOT}/reset-permissions"
readonly HDIUTIL_STUB="${TEMP_ROOT}/hdiutil"
readonly DITTO_STUB="${TEMP_ROOT}/ditto"
readonly PKILL_STUB="${TEMP_ROOT}/pkill"
readonly XCODEBUILD_STUB="${TEMP_ROOT}/xcodebuild"

function clean_up {
    rm -rf "${TEMP_ROOT}"
}
trap clean_up EXIT

function create_command_stubs {
    mkdir -p "${E2E_ROOT}"

cat > "${RELEASE_STUB}" <<'STUB'
#!/bin/zsh
set -eu
print -r -- "release ${BOUNDLESS_TRANSLATOR_PRODUCT_NAME} ${BOUNDLESS_TRANSLATOR_BUNDLE_IDENTIFIER} ${BOUNDLESS_TRANSLATOR_COMPILATION_CONDITION:-<unset>}" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
if [[ "${BOUNDLESS_TRANSLATOR_TEST_FAIL_RELEASE:-0}" == 1 ]]; then
    exit 42
fi
mkdir -p "${BOUNDLESS_TRANSLATOR_RELEASE_BUILD_ROOT}"
print -n dmg > "${BOUNDLESS_TRANSLATOR_RELEASE_BUILD_ROOT}/${BOUNDLESS_TRANSLATOR_PRODUCT_NAME}-test.dmg"
STUB

    cat > "${RESET_STUB}" <<'STUB'
#!/bin/zsh
set -eu
print -r -- "reset-permissions ${BOUNDLESS_TRANSLATOR_BUNDLE_IDENTIFIER} ${BOUNDLESS_TRANSLATOR_APP_PATH}" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
STUB

    cat > "${HDIUTIL_STUB}" <<'STUB'
#!/bin/zsh
set -eu
print -r -- "hdiutil $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
case "$1" in
    attach)
        local mount_point=''
        local index
        for (( index = 1; index <= $#; index++ )); do
            if [[ "${@[index]}" == -mountpoint ]]; then
                mount_point="${@[index + 1]}"
                break
            fi
        done
        mkdir -p "${mount_point}/Boundless Translator E2E.app/Contents/MacOS"
        local info_plist="${mount_point}/Boundless Translator E2E.app/Contents/Info.plist"
        /usr/bin/plutil -create xml1 "${info_plist}"
        /usr/bin/plutil -insert CFBundleExecutable -string 'Boundless Translator E2E' "${info_plist}"
        print -n installed > "${mount_point}/Boundless Translator E2E.app/Contents/MacOS/Boundless Translator E2E"
        ;;
    detach)
        ;;
esac
STUB

    cat > "${DITTO_STUB}" <<'STUB'
#!/bin/zsh
set -eu
print -r -- "ditto $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
/usr/bin/ditto "$1" "$2"
STUB

    cat > "${PKILL_STUB}" <<'STUB'
#!/bin/zsh
set -eu
print -r -- "pkill $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
exit 1
STUB

    cat > "${XCODEBUILD_STUB}" <<'STUB'
#!/bin/zsh
set -eu
print -r -- "xcodebuild $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
[[ "$*" != *"${BOUNDLESS_TRANSLATOR_TEST_FAIL_PHASE:-__never_fail__}"* ]]
STUB

    chmod +x \
        "${RELEASE_STUB}" \
        "${RESET_STUB}" \
        "${HDIUTIL_STUB}" \
        "${DITTO_STUB}" \
        "${PKILL_STUB}" \
        "${XCODEBUILD_STUB}"
}

function run_e2e {
    BOUNDLESS_TRANSLATOR_E2E_ROOT="${E2E_ROOT}" \
    BOUNDLESS_TRANSLATOR_E2E_SKIP_APPROVAL_WAIT=1 \
    BOUNDLESS_TRANSLATOR_RELEASE_DMG_EXECUTABLE="${RELEASE_STUB}" \
    BOUNDLESS_TRANSLATOR_RESET_PERMISSIONS_EXECUTABLE="${RESET_STUB}" \
    BOUNDLESS_TRANSLATOR_HDIUTIL_EXECUTABLE="${HDIUTIL_STUB}" \
    BOUNDLESS_TRANSLATOR_DITTO_EXECUTABLE="${DITTO_STUB}" \
    BOUNDLESS_TRANSLATOR_PKILL_EXECUTABLE="${PKILL_STUB}" \
    BOUNDLESS_TRANSLATOR_XCODEBUILD_EXECUTABLE="${XCODEBUILD_STUB}" \
    BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
        zsh "${RUNNER}" "$@"
}

function test_run_e2e_when_run_then_uses_isolated_notarized_dmg_and_runs_three_core_flows {
    # Arrange
    : > "${CALL_LOG}"

    # Act
    run_e2e >/dev/null

    # Assert
    local calls="$(<"${CALL_LOG}")"
    local release_call="$(grep '^release ' "${CALL_LOG}")"
    if [[ "${release_call}" != 'release Boundless Translator E2E com.lillard.BoundlessTranslator.e2e <unset>' ]]; then
        print -u2 'Expected the E2E release to use production compilation conditions.'
        print -u2 "Actual call: ${release_call}"
        return 1
    fi
    [[ "${calls}" == *'ditto '*'/Boundless Translator E2E.app '*'/E2E/Installed/Boundless Translator E2E.app'* ]]
    [[ "${calls}" == *'-only-testing:BoundlessTranslatorE2ETests/SelectionTranslationE2ETests/test_accessibilitySelection_whenTranslationActionRuns_thenPresentsSelectedSourceText'* ]]
    [[ "${calls}" == *'-only-testing:BoundlessTranslatorE2ETests/SelectionTranslationE2ETests/test_copyOnlySelection_whenTranslationActionRuns_thenUsesClipboardFallback'* ]]
    [[ "${calls}" == *'-only-testing:BoundlessTranslatorE2ETests/ScreenshotE2ETests/test_screenshotAction_whenFixtureRegionIsCaptured_thenRoutesLiveTextSelectionToTranslation'* ]]
    [[ "${calls}" == *"BOUNDLESS_TRANSLATOR_E2E_APP_PATH=${E2E_ROOT}/Installed/Boundless Translator E2E.app"* ]]
    [[ "${calls}" == *"pkill -f ^${E2E_ROOT}/Installed/Boundless Translator E2E.app/Contents/MacOS/Boundless Translator E2E([[:space:]]|$)"* ]]
    [[ "$(grep -c '^xcodebuild ' "${CALL_LOG}")" == 1 ]]
    ! grep -Fq 'reset-permissions' "${CALL_LOG}"
    ! grep -Fq 'com.lillard.BoundlessTranslator ' "${CALL_LOG}"
}

function test_run_e2e_from_permission_setup_then_resets_only_e2e_permissions_before_core_flows {
    # Arrange
    : > "${CALL_LOG}"

    # Act
    run_e2e --from-permission-setup >/dev/null

    # Assert
    local calls="$(<"${CALL_LOG}")"
    [[ "${calls}" == *"reset-permissions com.lillard.BoundlessTranslator.e2e ${E2E_ROOT}/Installed/Boundless Translator E2E.app"* ]]
    [[ "${calls}" == *'-only-testing:BoundlessTranslatorE2ETests/PermissionE2ETests/test_translationAction_withoutAccessibilityPermission_thenContinuesToSystemSettings'* ]]
    [[ "${calls}" == *'-only-testing:BoundlessTranslatorE2ETests/PermissionE2ETests/test_screenshotAction_withoutScreenRecordingPermission_thenRequestsSystemPermission'* ]]
    [[ "$(grep -c '^xcodebuild ' "${CALL_LOG}")" == 3 ]]
}

function test_run_e2e_when_release_fails_then_preserves_installed_e2e_app {
    # Arrange
    local installed_app="${E2E_ROOT}/Installed/Boundless Translator E2E.app"
    mkdir -p "${installed_app}"
    print -n original > "${installed_app}/marker"
    : > "${CALL_LOG}"

    # Act
    set +e
    BOUNDLESS_TRANSLATOR_TEST_FAIL_RELEASE=1 run_e2e >/dev/null 2>&1
    local exit_code="$?"
    set -e

    # Assert
    [[ "${exit_code}" == 42 ]]
    [[ "$(<"${installed_app}/marker")" == original ]]
}

function test_run_e2e_when_unknown_argument_is_given_then_stops_before_release {
    # Arrange
    : > "${CALL_LOG}"

    # Act & Assert
    if run_e2e --only-global-shortcut >/dev/null 2>&1; then
        print -u2 'Expected run_e2e_tests.sh to reject arguments.'
        return 1
    fi
    [[ ! -s "${CALL_LOG}" ]]
}

create_command_stubs
test_run_e2e_when_run_then_uses_isolated_notarized_dmg_and_runs_three_core_flows
test_run_e2e_from_permission_setup_then_resets_only_e2e_permissions_before_core_flows
test_run_e2e_when_release_fails_then_preserves_installed_e2e_app
test_run_e2e_when_unknown_argument_is_given_then_stops_before_release

print 'E2E runner tests passed.'
