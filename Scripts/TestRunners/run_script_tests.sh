#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"

function run_tests {
    local test_path
    for test_path in "$@"; do
        zsh "${PROJECT_ROOT}/Tests/Scripts/${test_path}Tests.sh"
    done
}

case "${1:-all}" in
    features)
        run_tests \
            DMG/BuildApp \
            DMG/NotarizeDmg \
            DMG/PackageDmg \
            DMG/ReleaseDmg \
            DMG/VerifyApp \
            DMG/VerifyDmg \
            ResetTestPermissions \
            Verification/GuiTestRunner \
            Verification/VerifyWorkflow \
            XcodeProject
        ;;
    subscription)
        run_tests \
            Verification/StoreKitTestRunner \
            Verification/VerifyWorkflow \
            XcodeProject
        ;;
    all)
        while IFS= read -r test_script; do
            zsh "${test_script}"
        done < <(find "${PROJECT_ROOT}/Tests/Scripts" -type f -name '*Tests.sh' | sort)
        ;;
    *)
        print -u2 'Usage: Scripts/TestRunners/run_script_tests.sh [features|subscription|all]'
        exit 2
        ;;
esac
