#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h}"
readonly LOCAL_ENV_PATH="${PROJECT_ROOT}/.env.local"
readonly XCRUN_EXECUTABLE="${BOUNDLESS_TRANSLATOR_XCRUN_EXECUTABLE:-xcrun}"

function fail {
    print -u2 "$1"
    exit 1
}

function print_usage {
    print -u2 'Usage: upload_app_store.sh <pkg-path>'
    print -u2 'Example: Scripts/upload_app_store.sh Build/AppStore/BoundlessTranslator-1.0-1.pkg'
}

function load_local_environment {
    [[ -f "${LOCAL_ENV_PATH}" ]] || return 0

    local existing_key_id="${BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_KEY_ID:-}"
    local existing_issuer_id="${BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_ISSUER_ID:-}"
    set -a
    source "${LOCAL_ENV_PATH}"
    set +a

    if [[ -n "${existing_key_id}" ]]; then
        export BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_KEY_ID="${existing_key_id}"
    fi
    if [[ -n "${existing_issuer_id}" ]]; then
        export BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_ISSUER_ID="${existing_issuer_id}"
    fi
}

if [[ "$#" -ne 1 ]]; then
    print_usage
    exit 1
fi

readonly PACKAGE_PATH="${1:A}"

[[ -f "${PACKAGE_PATH}" ]] || fail "App Store package does not exist: ${PACKAGE_PATH}"
load_local_environment
[[ -n "${BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_KEY_ID:-}" ]] || fail 'BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_KEY_ID is required.'
[[ -n "${BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_ISSUER_ID:-}" ]] || fail 'BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_ISSUER_ID is required.'

if ! "${XCRUN_EXECUTABLE}" altool \
    --validate-app \
    -f "${PACKAGE_PATH}" \
    -t macos \
    --apiKey "${BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_KEY_ID}" \
    --apiIssuer "${BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_ISSUER_ID}"; then
    fail "App Store validation failed: ${PACKAGE_PATH}"
fi

if ! "${XCRUN_EXECUTABLE}" altool \
    --upload-app \
    -f "${PACKAGE_PATH}" \
    -t macos \
    --apiKey "${BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_KEY_ID}" \
    --apiIssuer "${BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_ISSUER_ID}"; then
    fail "App Store upload failed: ${PACKAGE_PATH}"
fi

print "App Store upload completed: ${PACKAGE_PATH}"
