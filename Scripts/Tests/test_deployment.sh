#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"

function run_tests {
    local test_name
    for test_name in "$@"; do
        zsh "${PROJECT_ROOT}/Scripts/Tests/Deployment/${test_name}Tests.sh"
    done
}

case "${1:-all}" in
    features)
        run_tests \
            BuildApp \
            BuildDmg \
            NotarizeDmg \
            PackageDmg \
            ReleaseDmg \
            ResetTestPermissions \
            TestGuiScript \
            VerifyApp \
            VerifyWorkflow
        ;;
    subscription)
        run_tests \
            AppStoreBuild \
            AppStoreRelease \
            TestStoreKitScript \
            VerifyWorkflow
        ;;
    all)
        for test_script in "${PROJECT_ROOT}"/Scripts/Tests/Deployment/*Tests.sh; do
            zsh "${test_script}"
        done
        ;;
    *)
        print -u2 'Usage: Scripts/Tests/test_deployment.sh [features|subscription|all]'
        exit 2
        ;;
esac
