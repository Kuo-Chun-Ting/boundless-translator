#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"
readonly BUILD_APP="${PROJECT_ROOT}/Build/Boundless Translator.app"
readonly VERIFIER="${PROJECT_ROOT}/Scripts/verify_app.sh"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-verify-tests.XXXXXX)"
active_app_pid=""

function clean_up {
    if [[ -n "${active_app_pid}" ]]; then
        kill "${active_app_pid}" >/dev/null 2>&1 || true
        wait "${active_app_pid}" >/dev/null 2>&1 || true
    fi
    rm -rf "${TEMP_ROOT}"
}
trap clean_up EXIT

function test_verify_app_when_app_has_expected_signature_then_succeeds {
    # Arrange
    local app_path="${BUILD_APP}"

    # Act & Assert
    zsh "${VERIFIER}" "${app_path}"

    local resources_path="${app_path}/Contents/Resources"
    [[ -d "${resources_path}/en.lproj" ]]
    [[ -d "${resources_path}/zh-Hant.lproj" ]]
    [[ "$(find "${resources_path}" -mindepth 1 -maxdepth 1 -type d -name '*.lproj' | wc -l | tr -d ' ')" == "48" ]]
}

function test_verify_app_when_app_is_launched_then_remains_running {
    # Arrange
    local executable="${BUILD_APP}/Contents/MacOS/BoundlessTranslator"
    local output="${TEMP_ROOT}/launch.log"

    # Act
    "${executable}" >"${output}" 2>&1 &
    active_app_pid=$!
    sleep 2

    # Assert
    if ! kill -0 "${active_app_pid}" >/dev/null 2>&1; then
        cat "${output}" >&2
        print -u2 "Expected the built App to remain running after launch."
        return 1
    fi
    kill "${active_app_pid}"
    wait "${active_app_pid}" >/dev/null 2>&1 || true
    active_app_pid=""
}

function test_verify_app_when_environment_attempts_to_override_signer_then_uses_pinned_fingerprint {
    # Arrange
    local unexpected_sha1="0000000000000000000000000000000000000000"

    # Act & Assert
    BOUNDLESS_TRANSLATOR_EXPECTED_SIGNER_SHA1="${unexpected_sha1}" \
        zsh "${VERIFIER}" "${BUILD_APP}"
}

function test_verify_app_when_executable_is_modified_then_fails {
    # Arrange
    local test_app="${TEMP_ROOT}/Modified.app"
    ditto "${BUILD_APP}" "${test_app}"
    print '\0' >> "${test_app}/Contents/MacOS/BoundlessTranslator"

    # Act & Assert
    if zsh "${VERIFIER}" "${test_app}" >/dev/null 2>&1; then
        print -u2 "Expected modified App verification to fail."
        return 1
    fi
}

function test_verify_app_when_app_is_ad_hoc_signed_then_fails {
    # Arrange
    local test_app="${TEMP_ROOT}/Ad Hoc.app"
    ditto "${BUILD_APP}" "${test_app}"
    codesign --force --sign - "${test_app}" >/dev/null 2>&1

    # Act & Assert
    if zsh "${VERIFIER}" "${test_app}" >/dev/null 2>&1; then
        print -u2 "Expected ad hoc signed App verification to fail."
        return 1
    fi
}

test_verify_app_when_app_has_expected_signature_then_succeeds
test_verify_app_when_app_is_launched_then_remains_running
test_verify_app_when_environment_attempts_to_override_signer_then_uses_pinned_fingerprint
test_verify_app_when_executable_is_modified_then_fails
test_verify_app_when_app_is_ad_hoc_signed_then_fails

print "App verification tests passed."
