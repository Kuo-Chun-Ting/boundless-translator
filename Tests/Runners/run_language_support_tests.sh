#!/bin/zsh
set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"
cd "${PROJECT_ROOT}"

BOUNDLESS_TRANSLATOR_LANGUAGE_TESTS=1 swift test --disable-sandbox \
    --filter BoundlessTranslatorLanguageSupportTests "$@"
