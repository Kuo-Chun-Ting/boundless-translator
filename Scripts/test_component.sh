#!/bin/zsh

set -euo pipefail

repository_root="${0:A:h:h}"
cd "$repository_root"
export CLANG_MODULE_CACHE_PATH="$repository_root/.build/clang-module-cache"

swift test --disable-sandbox --filter BoundlessTranslatorComponentTests
