#!/bin/zsh

set -euo pipefail

readonly repository_root="${0:A:h:h}"

if (( $# > 1 )) || [[ "${1:-}" != '' && "${1:-}" != --force ]]; then
    print -u2 'Usage: Scripts/run_storekit_tests.sh [--force]'
    exit 2
fi

if [[ "${1:-}" != --force ]]; then
    print -u2 'SKIPPED: Local StoreKit tests are temporarily disabled.'
    print -u2 'Use Scripts/run_storekit_tests.sh --force for diagnostics.'
    exit 78
fi

readonly derived_data_path="$(mktemp -d /private/tmp/boundless-translator-storekit.XXXXXX)"
readonly result_bundle_path="${derived_data_path}/StoreKitTests.xcresult"
readonly host_executable="${derived_data_path}/Build/Products/Debug/BoundlessTranslatorStoreKitTestHost.app/Contents/MacOS/BoundlessTranslatorStoreKitTestHost"

function clean_up {
    local exit_status=$?
    trap - EXIT INT TERM
    # Exit 78 is reserved for the default skip before this cleanup is installed.
    if [[ "${exit_status}" == 78 ]]; then
        exit_status=1
    fi
    pkill -f "^${host_executable}$" 2>/dev/null || true
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
    -project Tests/Infrastructure/BoundlessTranslatorTests.xcodeproj \
    -scheme BoundlessTranslatorStoreKitTests \
    -destination 'platform=macOS' \
    -derivedDataPath "${derived_data_path}" \
    -resultBundlePath "${result_bundle_path}" \
    -parallel-testing-enabled NO \
    -jobs 1 \
    CODE_SIGN_IDENTITY=- \
    CODE_SIGN_STYLE=Manual

"${repository_root}/Scripts/Shared/check_xcode_test_results.sh" "${result_bundle_path}"
