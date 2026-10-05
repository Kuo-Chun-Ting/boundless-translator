#!/bin/zsh
set -euo pipefail
exec "${0:A:h}/Shared/run_swift_tests.sh" BoundlessTranslatorUnitTests "$@"
