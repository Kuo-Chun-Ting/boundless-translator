#!/bin/zsh
set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h}"
readonly MODE="${1:-compare}"
if [[ "$MODE" != compare && "$MODE" != baseline && "$MODE" != cancel && "$MODE" != concurrent && "$MODE" != cancel-both && "$MODE" != task-cancel && "$MODE" != chunked && "$MODE" != short-only ]]; then
    print -u2 'Usage: Scripts/diagnose_apple_translation.sh [compare|baseline|cancel|concurrent|cancel-both|task-cancel|chunked|short-only]'
    exit 2
fi
if (( $(sw_vers -productVersion | cut -d. -f1) < 26 )); then
    print -u2 'This diagnostic requires macOS 26 or later and Xcode with the macOS 26 SDK.'
    exit 2
fi
readonly FIXTURE="${APPLE_TRANSLATION_FIXTURE:-${PROJECT_ROOT}/Tests/Fixtures/Translation/100K_words.txt}"
readonly SOURCE_LANGUAGE="${APPLE_TRANSLATION_SOURCE:-en}"
readonly TARGET_LANGUAGE="${APPLE_TRANSLATION_TARGET:-zh-Hant}"
readonly SHORT_TEXT="${APPLE_TRANSLATION_SHORT_TEXT:-THE CITY THAT LEARNS}"
readonly CANCEL_DELAY="${APPLE_TRANSLATION_CANCEL_DELAY:-2.7}"
readonly TIMEOUT="${APPLE_TRANSLATION_TIMEOUT:-360}"
readonly OUTPUT_ROOT="${PROJECT_ROOT}/Build/TranslationDiagnostics"
mkdir -p "$OUTPUT_ROOT"
readonly RUN_ROOT="$(mktemp -d "${OUTPUT_ROOT}/run-$(date +%Y%m%d-%H%M%S).XXXXXX")"
print "Logs: ${RUN_ROOT}"
print 'This calls Apple directly. Restarting the probe does not reset Apple background services.'
print 'Keep other translation apps idle during the comparison.'
mkdir -p "${OUTPUT_ROOT}/ModuleCache"
xcrun swiftc -parse-as-library -swift-version 5 \
    -module-cache-path "${OUTPUT_ROOT}/ModuleCache" \
    "${PROJECT_ROOT}/Scripts/Diagnostics/AppleTranslationProbe.swift" \
    -o "${RUN_ROOT}/apple-translation-probe" > "${RUN_ROOT}/build.log" 2>&1 || {
    cat "${RUN_ROOT}/build.log"
    exit 1
}
function run_condition {
    local condition="$1"
    print "Running ${condition}; timeout ${TIMEOUT}s."
    "${RUN_ROOT}/apple-translation-probe" "$condition" "$FIXTURE" \
        "$SOURCE_LANGUAGE" "$TARGET_LANGUAGE" "$CANCEL_DELAY" "$TIMEOUT" "$SHORT_TEXT" \
        > "${RUN_ROOT}/${condition}.log" 2>&1 &
    local probe_pid=$!
    trap 'kill "$probe_pid" 2>/dev/null || true; exit 130' INT TERM
    local probe_exit=0
    wait "$probe_pid" || probe_exit=$?
    trap - INT TERM
    cat "${RUN_ROOT}/${condition}.log"
    print "${condition}: exit=${probe_exit}"
    if (( probe_exit == 3 )); then
        print 'Translation returned, but the short request exceeded the latency target. Logs are saved above.'
    fi
    return "$probe_exit"
}
if [[ "$MODE" == compare ]]; then
    run_condition baseline
    run_condition cancel
else
    run_condition "$MODE"
fi
print "Completed. Logs: ${RUN_ROOT}"
