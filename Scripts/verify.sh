#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h}"
readonly SWIFT_EXECUTABLE="${BOUNDLESS_TRANSLATOR_SWIFT_EXECUTABLE:-$(command -v swift)}"
readonly GUI_TEST_EXECUTABLE="${BOUNDLESS_TRANSLATOR_GUI_TEST_EXECUTABLE:-${PROJECT_ROOT}/Scripts/Tests/test_gui.sh}"
readonly STOREKIT_TEST_EXECUTABLE="${BOUNDLESS_TRANSLATOR_STOREKIT_TEST_EXECUTABLE:-${PROJECT_ROOT}/Scripts/Tests/test_storekit.sh}"
readonly BUILD_EXECUTABLE="${BOUNDLESS_TRANSLATOR_BUILD_EXECUTABLE:-${PROJECT_ROOT}/Scripts/Tools/build_app.sh}"
readonly APP_VERIFY_EXECUTABLE="${BOUNDLESS_TRANSLATOR_APP_VERIFY_EXECUTABLE:-${PROJECT_ROOT}/Scripts/Tools/verify_app.sh}"
readonly DEPLOYMENT_TEST_EXECUTABLE="${BOUNDLESS_TRANSLATOR_DEPLOYMENT_TEST_EXECUTABLE:-${PROJECT_ROOT}/Scripts/Tests/test_deployment.sh}"
readonly APP_PATH="${BOUNDLESS_TRANSLATOR_VERIFY_APP_PATH:-${PROJECT_ROOT}/Build/Boundless Translator.app}"
readonly TEST_REPORT_ROOT="$(mktemp -d /private/tmp/boundless-translator-test-results.XXXXXX)"
readonly VERIFICATION_BUILD_ROOT="${PROJECT_ROOT}/.build/verification"
storekit_integration_skipped=false
trap 'rm -rf "${TEST_REPORT_ROOT}"' EXIT

cd "${PROJECT_ROOT}"

function verify_swift_tests {
    local mode="$1"
    shift
    local report="${TEST_REPORT_ROOT}/${mode}.xml"
    print "Verifying ${mode} mode."

    CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-${VERIFICATION_BUILD_ROOT}/clang-cache}" \
    SWIFTPM_MODULECACHE_OVERRIDE="${SWIFTPM_MODULECACHE_OVERRIDE:-${VERIFICATION_BUILD_ROOT}/module-cache}" \
        "${SWIFT_EXECUTABLE}" test --disable-sandbox --xunit-output "${report}" \
            --scratch-path "${VERIFICATION_BUILD_ROOT}/${mode}" \
            --cache-path "${VERIFICATION_BUILD_ROOT}/cache" \
            --config-path "${VERIFICATION_BUILD_ROOT}/config" \
            --security-path "${VERIFICATION_BUILD_ROOT}/security" \
            "$@"

    # SwiftPM gives Swift Testing its own suffixed report, separate from XCTest.
    local swift_test_report="${report:r}-swift-testing.xml"
    if [[ ! -s "${swift_test_report}" ]] || [[ "$(/usr/bin/xmllint --xpath \
        'sum(/testsuites/testsuite/@tests) > 0 and sum(/testsuites/testsuite/@errors) = 0 and sum(/testsuites/testsuite/@failures) = 0' \
        "${swift_test_report}" 2>/dev/null)" != true ]]; then
        print -u2 "Swift ${mode} tests did not produce complete, passing results. Verification stopped."
        exit 1
    fi
}

function verify_features {
    verify_swift_tests features
    "${GUI_TEST_EXECUTABLE}"
    "${BUILD_EXECUTABLE}"
    "${APP_VERIFY_EXECUTABLE}" "${APP_PATH}"
    "${DEPLOYMENT_TEST_EXECUTABLE}" features
    print "Feature verification passed."
}

function verify_subscription {
    verify_swift_tests subscription -Xswiftc -DSUBSCRIPTION_REQUIRED
    local storekit_exit_status=0
    "${STOREKIT_TEST_EXECUTABLE}" || storekit_exit_status=$?
    case "${storekit_exit_status}" in
        0) ;;
        78) storekit_integration_skipped=true ;;
        *) return "${storekit_exit_status}" ;;
    esac
    "${DEPLOYMENT_TEST_EXECUTABLE}" subscription
    if [[ "${storekit_integration_skipped}" == true ]]; then
        print "Subscription unit and deployment checks passed; StoreKit integration tests were skipped."
    else
        print "Subscription verification passed."
    fi
}

case "${1:-all}" in
    features)
        verify_features
        ;;
    subscription)
        verify_subscription
        ;;
    all)
        verify_features
        verify_subscription
        ;;
    *)
        print -u2 'Usage: Scripts/verify.sh [features|subscription|all]'
        exit 2
        ;;
esac

if [[ "${storekit_integration_skipped}" == true ]]; then
    print -u2 "Executed verification checks passed. StoreKit integration coverage is incomplete; release readiness is not established."
else
    print "Verification passed."
fi
