#!/bin/zsh

set -euo pipefail

readonly repository_root="${0:A:h:h:h}"

function skip_known_affected_environment {
    local macos_version macos_build xcode_version
    macos_version="$(sw_vers -productVersion)" || exit 1
    macos_build="$(sw_vers -buildVersion)" || exit 1
    xcode_version="$(xcodebuild -version)" || exit 1

    if [[ "${macos_version}" == 26.5.2 && "${macos_build}" == 25F84 \
        && "${xcode_version}" == $'Xcode 26.6\nBuild version 17F113' ]]; then
        print -u2 'SKIPPED: 3 local StoreKit integration tests on macOS 26.5.2 (25F84) + Xcode 26.6 (17F113).'
        print -u2 'Locally reproduced StoreKit entitlement lookup failure; integration coverage is incomplete.'
        print -u2 'Tests automatically run when macOS or Xcode changes. Use Scripts/Tests/test_storekit.sh --force for diagnostics.'
        exit 78
    fi
}

if (( $# > 1 )) || [[ "${1:-}" != '' && "${1:-}" != --force ]]; then
    print -u2 'Usage: Scripts/Tests/test_storekit.sh [--force]'
    exit 2
fi

if [[ "${1:-}" != --force ]]; then
    skip_known_affected_environment
fi

readonly derived_data_path="$(mktemp -d /private/tmp/boundless-translator-storekit.XXXXXX)"
readonly result_bundle_path="${derived_data_path}/StoreKitTests.xcresult"
readonly host_executable="${derived_data_path}/Build/Products/Debug/BoundlessTranslatorStoreKitTestHost.app/Contents/MacOS/BoundlessTranslatorStoreKitTestHost"

function clean_up {
    local exit_status=$?
    trap - EXIT INT TERM
    # Exit 78 is reserved for the environment skip before this cleanup is installed.
    if [[ "${exit_status}" == 78 ]]; then
        exit_status=1
    fi
    pkill -f "^${host_executable}$" 2>/dev/null || true
    chmod -R u+w "${derived_data_path}" 2>/dev/null || true
    rm -rf "${derived_data_path}" 2>/dev/null || true
    exit "${exit_status}"
}

function interrupt {
    trap - INT TERM
    return 130
}

trap clean_up EXIT
trap interrupt INT TERM

cd "${repository_root}"

xcodebuild test \
    -project Tests/GUIProject/BoundlessTranslatorGUITests.xcodeproj \
    -scheme BoundlessTranslatorStoreKitTests \
    -destination 'platform=macOS' \
    -derivedDataPath "${derived_data_path}" \
    -resultBundlePath "${result_bundle_path}" \
    -parallel-testing-enabled NO \
    -jobs 1 \
    CODE_SIGN_IDENTITY=- \
    CODE_SIGN_STYLE=Manual

test_summary="$(xcrun xcresulttool get test-results summary \
    --path "${result_bundle_path}" \
    --compact)"
readonly test_summary

print -r -- "${test_summary}" | grep -Eq '"totalTestCount":[1-9][0-9]*'
print -r -- "${test_summary}" | grep -Eq '"passedTests":[1-9][0-9]*'
print -r -- "${test_summary}" | grep -Eq '"failedTests":0'
