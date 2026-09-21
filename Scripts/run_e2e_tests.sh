#!/bin/zsh

set -euo pipefail

typeset -i from_permission_setup=0
case "${1:-}" in
    '') ;;
    --from-permission-setup)
        if [[ "$#" -ne 1 ]]; then
            print -u2 'Usage: Scripts/run_e2e_tests.sh [--from-permission-setup]'
            exit 2
        fi
        from_permission_setup=1
        ;;
    *)
        print -u2 'Usage: Scripts/run_e2e_tests.sh [--from-permission-setup]'
        exit 2
        ;;
esac

readonly PROJECT_ROOT="${0:A:h:h}"
readonly PRODUCT_NAME='Boundless Translator E2E'
readonly APP_NAME="${PRODUCT_NAME}.app"
readonly BUNDLE_IDENTIFIER='com.lillard.BoundlessTranslator.e2e'
readonly DMG_NAME="${PRODUCT_NAME}-test.dmg"
readonly E2E_ROOT="${BOUNDLESS_TRANSLATOR_E2E_ROOT:-${PROJECT_ROOT}/Build/E2E}"
readonly ARTIFACT_ROOT="${E2E_ROOT}/Artifacts"
readonly INSTALL_ROOT="${E2E_ROOT}/Installed"
readonly INSTALL_PATH="${INSTALL_ROOT}/${APP_NAME}"
readonly DMG_PATH="${ARTIFACT_ROOT}/${DMG_NAME}"
readonly RESULT_ROOT="${E2E_ROOT}/Results"
readonly DERIVED_DATA_PATH="${E2E_ROOT}/DerivedData"
readonly RELEASE_DMG_EXECUTABLE="${BOUNDLESS_TRANSLATOR_RELEASE_DMG_EXECUTABLE:-${PROJECT_ROOT}/Scripts/release_dmg.sh}"
readonly RESET_PERMISSIONS_EXECUTABLE="${BOUNDLESS_TRANSLATOR_RESET_PERMISSIONS_EXECUTABLE:-${PROJECT_ROOT}/Scripts/reset_test_permissions.sh}"
readonly HDIUTIL_EXECUTABLE="${BOUNDLESS_TRANSLATOR_HDIUTIL_EXECUTABLE:-hdiutil}"
readonly DITTO_EXECUTABLE="${BOUNDLESS_TRANSLATOR_DITTO_EXECUTABLE:-ditto}"
readonly PKILL_EXECUTABLE="${BOUNDLESS_TRANSLATOR_PKILL_EXECUTABLE:-pkill}"
readonly XCODEBUILD_EXECUTABLE="${BOUNDLESS_TRANSLATOR_XCODEBUILD_EXECUTABLE:-xcodebuild}"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-e2e.XXXXXX)"
readonly MOUNT_POINT="${TEMP_ROOT}/DMG"

typeset -i mounted=0

function app_executable_path {
    local app_path="$1"
    local info_plist="${app_path}/Contents/Info.plist"
    [[ -f "${info_plist}" ]] || return 1

    local executable_name
    executable_name="$(plutil -extract CFBundleExecutable raw "${info_plist}")" || return 1
    print -r -- "${app_path}/Contents/MacOS/${executable_name}"
}

function quit_e2e_app {
    local executable_path
    executable_path="$(app_executable_path "${INSTALL_PATH}")" || return 0
    "${PKILL_EXECUTABLE}" -f "^${executable_path}([[:space:]]|$)" >/dev/null 2>&1 || true
}

function clean_up {
    set +e
    quit_e2e_app
    if (( mounted )); then
        "${HDIUTIL_EXECUTABLE}" detach "${MOUNT_POINT}" >/dev/null 2>&1
    fi
    rm -rf "${TEMP_ROOT}"
}

function release_e2e_dmg {
    BOUNDLESS_TRANSLATOR_RELEASE_BUILD_ROOT="${ARTIFACT_ROOT}" \
    BOUNDLESS_TRANSLATOR_PRODUCT_NAME="${PRODUCT_NAME}" \
    BOUNDLESS_TRANSLATOR_BUNDLE_IDENTIFIER="${BUNDLE_IDENTIFIER}" \
        "${RELEASE_DMG_EXECUTABLE}"
}

function install_e2e_app {
    "${HDIUTIL_EXECUTABLE}" attach \
        -readonly \
        -nobrowse \
        -mountpoint "${MOUNT_POINT}" \
        "${DMG_PATH}" >/dev/null
    mounted=1

    local mounted_app="${MOUNT_POINT}/${APP_NAME}"
    if [[ ! -d "${mounted_app}" ]]; then
        print -u2 "The mounted DMG does not contain ${APP_NAME}."
        exit 1
    fi

    quit_e2e_app
    rm -rf "${INSTALL_PATH}"
    "${DITTO_EXECUTABLE}" "${mounted_app}" "${INSTALL_PATH}"
    "${HDIUTIL_EXECUTABLE}" detach "${MOUNT_POINT}" >/dev/null
    mounted=0
}

function run_xcuitest_phase {
    local result_name="$1"
    shift
    local result_path="${RESULT_ROOT}/${result_name}.xcresult"
    rm -rf "${result_path}"

    "${XCODEBUILD_EXECUTABLE}" test \
        -project "${PROJECT_ROOT}/Tests/GUIProject/BoundlessTranslatorGUITests.xcodeproj" \
        -scheme BoundlessTranslatorE2ETests \
        -testPlan BoundlessTranslatorE2ETests \
        -destination 'platform=macOS' \
        -derivedDataPath "${DERIVED_DATA_PATH}" \
        -resultBundlePath "${result_path}" \
        -jobs 1 \
        BOUNDLESS_TRANSLATOR_E2E_APP_PATH="${INSTALL_PATH}" \
        "$@"
}

function run_permission_setup_tests {
    BOUNDLESS_TRANSLATOR_BUNDLE_IDENTIFIER="${BUNDLE_IDENTIFIER}" \
    BOUNDLESS_TRANSLATOR_APP_PATH="${INSTALL_PATH}" \
        "${RESET_PERMISSIONS_EXECUTABLE}"

    print 'Opening the Accessibility permission flow…'
    run_xcuitest_phase \
        AccessibilityPermission \
        -only-testing:BoundlessTranslatorE2ETests/PermissionE2ETests/test_translationAction_withoutAccessibilityPermission_thenContinuesToSystemSettings
    wait_for_permission \
        'Enable Boundless Translator E2E in Accessibility.'

    quit_e2e_app
    print 'Opening the Screen & System Audio Recording permission flow…'
    run_xcuitest_phase \
        ScreenRecordingPermission \
        -only-testing:BoundlessTranslatorE2ETests/PermissionE2ETests/test_screenshotAction_withoutScreenRecordingPermission_thenRequestsSystemPermission
    wait_for_permission \
        'Enable Boundless Translator E2E in Screen & System Audio Recording.'
}

function wait_for_permission {
    local instruction="$1"
    if [[ "${BOUNDLESS_TRANSLATOR_E2E_SKIP_APPROVAL_WAIT:-0}" == 1 ]]; then
        return
    fi
    print
    print "${instruction}"
    print -n 'Press Return after the permission is enabled: '
    read -r
}

function run_core_feature_tests {
    run_xcuitest_phase \
        Features \
        -only-testing:BoundlessTranslatorE2ETests/SelectionTranslationE2ETests/test_accessibilitySelection_whenTranslationActionRuns_thenPresentsSelectedSourceText \
        -only-testing:BoundlessTranslatorE2ETests/SelectionTranslationE2ETests/test_copyOnlySelection_whenTranslationActionRuns_thenUsesClipboardFallback \
        -only-testing:BoundlessTranslatorE2ETests/ScreenshotE2ETests/test_screenshotAction_whenFixtureRegionIsCaptured_thenRoutesLiveTextSelectionToTranslation
}

trap clean_up EXIT
trap 'exit 130' INT TERM

mkdir -p \
    "${ARTIFACT_ROOT}" \
    "${INSTALL_ROOT}" \
    "${RESULT_ROOT}" \
    "${MOUNT_POINT}"

release_e2e_dmg
if [[ ! -f "${DMG_PATH}" ]]; then
    print -u2 "Release did not produce the expected DMG: ${DMG_PATH}"
    exit 1
fi

install_e2e_app

if (( from_permission_setup )); then
    run_permission_setup_tests
fi

quit_e2e_app
print 'Running core feature E2E tests…'
run_core_feature_tests
print "E2E tests passed. Results: ${RESULT_ROOT}"
