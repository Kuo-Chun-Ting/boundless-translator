#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h}"
readonly SWIFT_EXECUTABLE="${BOUNDLESS_TRANSLATOR_SWIFT_EXECUTABLE:-$(command -v swift)}"
readonly GUI_TEST_EXECUTABLE="${BOUNDLESS_TRANSLATOR_GUI_TEST_EXECUTABLE:-${PROJECT_ROOT}/Scripts/Tests/test_gui.sh}"
readonly BUILD_EXECUTABLE="${BOUNDLESS_TRANSLATOR_BUILD_EXECUTABLE:-${PROJECT_ROOT}/Scripts/Tools/build_app.sh}"
readonly APP_VERIFY_EXECUTABLE="${BOUNDLESS_TRANSLATOR_APP_VERIFY_EXECUTABLE:-${PROJECT_ROOT}/Scripts/Tools/verify_app.sh}"
readonly DEPLOYMENT_TEST_EXECUTABLE="${BOUNDLESS_TRANSLATOR_DEPLOYMENT_TEST_EXECUTABLE:-${PROJECT_ROOT}/Scripts/Tests/test_deployment.sh}"
readonly APP_PATH="${BOUNDLESS_TRANSLATOR_VERIFY_APP_PATH:-${PROJECT_ROOT}/Build/Boundless Translator.app}"
readonly TEST_REPORT_ROOT="$(mktemp -d /private/tmp/boundless-translator-test-results.XXXXXX)"
trap 'rm -rf "${TEST_REPORT_ROOT}"' EXIT

cd "${PROJECT_ROOT}"

"${SWIFT_EXECUTABLE}" test --disable-sandbox --xunit-output "${TEST_REPORT_ROOT}/tests.xml"
# SwiftPM gives Swift Testing its own suffixed report, separate from XCTest.
readonly SWIFT_TEST_REPORT="${TEST_REPORT_ROOT}/tests-swift-testing.xml"
if [[ ! -s "${SWIFT_TEST_REPORT}" ]] || [[ "$(/usr/bin/xmllint --xpath \
    'sum(/testsuites/testsuite/@tests) > 0 and sum(/testsuites/testsuite/@errors) = 0 and sum(/testsuites/testsuite/@failures) = 0' \
    "${SWIFT_TEST_REPORT}" 2>/dev/null)" != true ]]; then
    print -u2 "Swift tests did not produce complete, passing results. Verification stopped."
    exit 1
fi
"${GUI_TEST_EXECUTABLE}"
"${BUILD_EXECUTABLE}"
"${APP_VERIFY_EXECUTABLE}" "${APP_PATH}"
"${DEPLOYMENT_TEST_EXECUTABLE}"

print "Verification passed."
