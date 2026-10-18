#!/bin/zsh
set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-website-tests.XXXXXX)"
trap 'rm -rf "${TEMP_ROOT}"' EXIT
readonly FIXTURE_ROOT="${TEMP_ROOT}/Project With Spaces"
readonly MOCK_BIN="${TEMP_ROOT}/bin"
readonly CALL_LOG="${TEMP_ROOT}/calls.log"
mkdir -p "${FIXTURE_ROOT}/Scripts" "${FIXTURE_ROOT}/docs" "${MOCK_BIN}"
cp "${PROJECT_ROOT}/Scripts/preview_website.sh" "${FIXTURE_ROOT}/Scripts/"

cat > "${MOCK_BIN}/brew" <<'MOCK'
#!/bin/zsh
exit 1
MOCK
cat > "${MOCK_BIN}/ruby" <<'MOCK'
#!/bin/zsh
exit "${MOCK_RUBY_STATUS:-0}"
MOCK
cat > "${MOCK_BIN}/xcode-select" <<'MOCK'
#!/bin/zsh
print /Developer
MOCK
cat > "${MOCK_BIN}/xcrun" <<'MOCK'
#!/bin/zsh
set -euo pipefail
[[ "${DEVELOPER_DIR}" == /Developer ]]
print /SDK
MOCK
cat > "${MOCK_BIN}/bundle" <<'MOCK'
#!/bin/zsh
set -euo pipefail
print -r -- "$*" >> "${CALL_LOG}"
case "$1" in
    check) exit "${MOCK_CHECK_STATUS:-0}" ;;
    install)
        [[ "${SDKROOT}" == /SDK ]]
        exit "${MOCK_INSTALL_STATUS:-0}"
        ;;
    exec)
        [[ "${BUNDLE_GEMFILE}" == "${FIXTURE_ROOT}/docs/Gemfile" ]]
        [[ "${BUNDLE_PATH}" == "${FIXTURE_ROOT}/Build/Website/Gems" ]]
        [[ "$PWD" == "${FIXTURE_ROOT}" ]]
        [[ "$*" == "exec jekyll serve --source ${FIXTURE_ROOT}/docs --destination ${FIXTURE_ROOT}/Build/Website/Site --host 127.0.0.1 --port 4000 --open-url --livereload" ]]
        ;;
esac
MOCK
chmod +x "${MOCK_BIN}"/*
export PATH="${MOCK_BIN}:${PATH}"
export FIXTURE_ROOT CALL_LOG

function test_preview_when_dependencies_exist_then_serves_from_any_directory {
    : > "${CALL_LOG}"
    (cd /; zsh "${FIXTURE_ROOT}/Scripts/preview_website.sh")
    [[ "$(sed -n '1p' "${CALL_LOG}")" == check ]]
    [[ "$(wc -l < "${CALL_LOG}" | tr -d ' ')" == 2 ]]
}

function test_preview_when_dependencies_are_missing_then_installs_before_serving {
    : > "${CALL_LOG}"
    MOCK_CHECK_STATUS=1 zsh "${FIXTURE_ROOT}/Scripts/preview_website.sh"
    [[ "$(sed -n '2p' "${CALL_LOG}")" == install ]]
    [[ "$(wc -l < "${CALL_LOG}" | tr -d ' ')" == 3 ]]
}

function test_preview_when_install_fails_then_does_not_serve {
    : > "${CALL_LOG}"
    if MOCK_CHECK_STATUS=1 MOCK_INSTALL_STATUS=9 zsh "${FIXTURE_ROOT}/Scripts/preview_website.sh"; then
        return 1
    fi
    [[ "$(wc -l < "${CALL_LOG}" | tr -d ' ')" == 2 ]]
}

function test_preview_when_ruby_is_too_old_then_explains_setup {
    : > "${CALL_LOG}"
    if MOCK_RUBY_STATUS=1 zsh "${FIXTURE_ROOT}/Scripts/preview_website.sh" > "${TEMP_ROOT}/error.log" 2>&1; then
        return 1
    fi
    rg -q 'brew install ruby@3.3' "${TEMP_ROOT}/error.log"
    [[ ! -s "${CALL_LOG}" ]]
}

test_preview_when_dependencies_exist_then_serves_from_any_directory
test_preview_when_dependencies_are_missing_then_installs_before_serving
test_preview_when_install_fails_then_does_not_serve
test_preview_when_ruby_is_too_old_then_explains_setup
print 'Website preview tests passed (4 cases).'
