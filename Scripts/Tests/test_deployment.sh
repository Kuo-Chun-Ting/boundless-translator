#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"

for test_script in "${PROJECT_ROOT}"/Scripts/Tests/Deployment/*Tests.sh; do
    zsh "${test_script}"
done
