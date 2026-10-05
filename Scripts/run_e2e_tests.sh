#!/bin/zsh

set -euo pipefail

typeset -i from_permission_setup=0
typeset -a selected=()
for argument in "$@"; do
    case "$argument" in
        --from-permission-setup) from_permission_setup=1 ;;
        -*) print -u2 'Usage: Scripts/run_e2e_tests.sh [--from-permission-setup] [TestClass[/testMethod] ...]'; exit 2 ;;
        PermissionE2ETests*) print -u2 'Use --from-permission-setup for permission tests.'; exit 2 ;;
        SelectionTranslationE2ETests|SelectionTranslationE2ETests/*|ScreenshotE2ETests|ScreenshotE2ETests/*)
            selected+=("-only-testing:BoundlessTranslatorE2ETests/${argument}") ;;
        *) print -u2 "Unknown E2E test: ${argument}"; exit 2 ;;
    esac
done
if (( ${#selected} == 0 )); then
    selected=(
        -only-testing:BoundlessTranslatorE2ETests/SelectionTranslationE2ETests
        -only-testing:BoundlessTranslatorE2ETests/ScreenshotE2ETests
    )
fi

readonly PROJECT_ROOT="${0:A:h:h}"
readonly PRODUCT_NAME='Boundless Translator E2E'
readonly APP_NAME="${PRODUCT_NAME}.app"
readonly BUNDLE_IDENTIFIER='com.lillard.BoundlessTranslator.e2e'
readonly E2E_ROOT="${BOUNDLESS_TRANSLATOR_E2E_ROOT:-${PROJECT_ROOT}/Build/E2E}"
readonly APP_ROOT="${E2E_ROOT}/App"
readonly APP_PATH="${APP_ROOT}/${APP_NAME}"
readonly RESULT_ROOT="${E2E_ROOT}/Results"
readonly DERIVED_DATA_PATH="${E2E_ROOT}/DerivedData"
readonly BUILD_APP_EXECUTABLE="${BOUNDLESS_TRANSLATOR_BUILD_APP_EXECUTABLE:-${PROJECT_ROOT}/Scripts/DMG/build_app.sh}"
readonly RESET_PERMISSIONS_EXECUTABLE="${BOUNDLESS_TRANSLATOR_RESET_PERMISSIONS_EXECUTABLE:-${PROJECT_ROOT}/Scripts/Reset/reset_permissions.sh}"
readonly XCODEBUILD_EXECUTABLE="${BOUNDLESS_TRANSLATOR_XCODEBUILD_EXECUTABLE:-xcodebuild}"

function quit_e2e_app {
    local info="${APP_PATH}/Contents/Info.plist"
    [[ -f "$info" ]] || return 0
    local name
    name="$(plutil -extract CFBundleExecutable raw "$info")" || return 0
    pkill -f "^${APP_PATH}/Contents/MacOS/${name}([[:space:]]|$)" >/dev/null 2>&1 || true
}

function run_xcuitest_phase {
    local result_name="$1"
    shift
    local result_path="${RESULT_ROOT}/${result_name}.xcresult"
    rm -rf "${result_path}"

    "${XCODEBUILD_EXECUTABLE}" test \
        -project "${PROJECT_ROOT}/Tests/Infrastructure/BoundlessTranslatorTests.xcodeproj" \
        -scheme BoundlessTranslatorE2ETests \
        -testPlan BoundlessTranslatorE2ETests \
        -destination 'platform=macOS' \
        -derivedDataPath "${DERIVED_DATA_PATH}" \
        -resultBundlePath "${result_path}" \
        -parallel-testing-enabled NO -jobs 1 \
        BOUNDLESS_TRANSLATOR_E2E_APP_PATH="${APP_PATH}" \
        "$@"
    "${PROJECT_ROOT}/Scripts/Shared/check_xcode_test_results.sh" "${result_path}"
}

function run_permission_setup_tests {
    BOUNDLESS_TRANSLATOR_APP_PATH="${APP_PATH}" \
        "${RESET_PERMISSIONS_EXECUTABLE}" e2e

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

trap quit_e2e_app EXIT
trap 'exit 130' INT TERM
mkdir -p "${APP_ROOT}" "${RESULT_ROOT}" "${DERIVED_DATA_PATH}"
quit_e2e_app
BOUNDLESS_TRANSLATOR_BUILD_ROOT="${APP_ROOT}" \
BOUNDLESS_TRANSLATOR_PRODUCT_NAME="${PRODUCT_NAME}" \
BOUNDLESS_TRANSLATOR_BUNDLE_IDENTIFIER="${BUNDLE_IDENTIFIER}" \
    "${BUILD_APP_EXECUTABLE}"
[[ -d "${APP_PATH}" ]] || { print -u2 "Build did not produce ${APP_PATH}"; exit 1; }
if (( from_permission_setup )); then
    run_permission_setup_tests
fi
quit_e2e_app
print 'Running product E2E tests…'
run_xcuitest_phase Features "${selected[@]}"
print "E2E tests passed. Results: ${RESULT_ROOT}"
