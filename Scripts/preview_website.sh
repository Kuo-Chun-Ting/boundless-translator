#!/bin/zsh
set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h}"

if command -v brew >/dev/null 2>&1; then
    ruby_prefix="$(brew --prefix ruby@3.3 2>/dev/null || true)"
    if [[ -x "${ruby_prefix}/bin/ruby" ]]; then
        export PATH="${ruby_prefix}/bin:${PATH}"
    fi
fi

if ! ruby -e 'exit(Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.3") ? 0 : 1)' 2>/dev/null; then
    print -u2 '網站預覽需要 Ruby 3.3 或更新版本。請先執行：brew install ruby@3.3'
    exit 1
fi
if ! command -v bundle >/dev/null 2>&1; then
    print -u2 '找不到 Bundler。請使用目前的 Ruby 執行：gem install bundler'
    exit 1
fi

export BUNDLE_GEMFILE="${PROJECT_ROOT}/docs/Gemfile"
export BUNDLE_PATH="${PROJECT_ROOT}/Build/Website/Gems"
cd "${PROJECT_ROOT}"

if ! bundle check >/dev/null 2>&1; then
    print '首次執行，正在安裝網站預覽所需套件…'
    export DEVELOPER_DIR="${DEVELOPER_DIR:-$(xcode-select -p)}"
    export SDKROOT="${SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
    bundle install
fi

print '正在啟動網站預覽，瀏覽器會自動開啟。按 Ctrl-C 停止。'
exec bundle exec jekyll serve \
    --source "${PROJECT_ROOT}/docs" \
    --destination "${PROJECT_ROOT}/Build/Website/Site" \
    --host 127.0.0.1 \
    --port 4000 \
    --open-url \
    --livereload
