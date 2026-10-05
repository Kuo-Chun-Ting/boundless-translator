#!/bin/zsh
set -euo pipefail
[[ $# == 1 ]] || exit 2
summary="$(xcrun xcresulttool get test-results summary --path "$1" --compact)"
print -r -- "$summary" | python3 -c '
import json, sys
r = json.load(sys.stdin)
assert r.get("totalTestCount", 0) > 0, "No tests ran"
assert r.get("failedTests", 0) == 0, "Tests failed"
assert r.get("skippedTests", 0) == 0, "Tests were skipped"
assert r.get("passedTests", 0) == r["totalTestCount"], "Incomplete test results"
'
