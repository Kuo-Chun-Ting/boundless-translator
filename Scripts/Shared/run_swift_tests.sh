#!/bin/zsh
set -euo pipefail
readonly PROJECT_ROOT="${0:A:h:h:h}"
readonly SWIFT_EXECUTABLE="${BOUNDLESS_TRANSLATOR_SWIFT_EXECUTABLE:-swift}"
readonly BUILD_ROOT="${BOUNDLESS_TRANSLATOR_VERIFICATION_BUILD_ROOT:-${PROJECT_ROOT}/.build/verification}"
readonly TARGET="$1"
shift
if (( $# > 1 )); then
    print -u2 'Expected at most one test-name regular expression.'
    exit 2
fi
readonly FILTER="${TARGET}${1:+.*$1}"
readonly REPORT_ROOT="$(mktemp -d /private/tmp/boundless-swift-results.XXXXXX)"
trap 'rm -rf "${REPORT_ROOT}"' EXIT
cd "${PROJECT_ROOT}"

readonly REPORT="${REPORT_ROOT}/tests.xml"
print "Running ${TARGET}."
CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-${BUILD_ROOT}/clang-cache}" \
SWIFTPM_MODULECACHE_OVERRIDE="${SWIFTPM_MODULECACHE_OVERRIDE:-${BUILD_ROOT}/module-cache}" \
    "${SWIFT_EXECUTABLE}" test --disable-sandbox --xunit-output "${REPORT}" \
    --scratch-path "${BUILD_ROOT}/features" --cache-path "${BUILD_ROOT}/cache" \
    --config-path "${BUILD_ROOT}/config" --security-path "${BUILD_ROOT}/security" \
    --filter "${FILTER}"
readonly RESULTS="${REPORT:r}-swift-testing.xml"
if [[ ! -s "${RESULTS}" ]] || [[ "$(/usr/bin/xmllint --xpath \
    'sum(/testsuites/testsuite/@tests) > 0 and sum(/testsuites/testsuite/@errors) = 0 and sum(/testsuites/testsuite/@failures) = 0' \
    "${RESULTS}" 2>/dev/null)" != true ]]; then
    print -u2 "${TARGET}: missing, empty, or failing test results."
    exit 1
fi
