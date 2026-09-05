#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly NOTARIZER="${PROJECT_ROOT}/Scripts/Tools/notarize_dmg.sh"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-notarize-tests.XXXXXX)"
readonly CALL_LOG="${TEMP_ROOT}/calls.log"
readonly XCRUN_STUB="${TEMP_ROOT}/xcrun"
readonly SPCTL_STUB="${TEMP_ROOT}/spctl"

function clean_up {
    rm -rf "${TEMP_ROOT}"
}
trap clean_up EXIT

function create_tool_stubs {
    cat > "${XCRUN_STUB}" <<'EOF'
#!/bin/zsh
print -r -- "xcrun $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
if [[ "$1" == "notarytool" && "${BOUNDLESS_TRANSLATOR_TEST_SUBMIT_RESULT:-success}" == "failure" ]]; then
    exit 1
fi
EOF
    chmod +x "${XCRUN_STUB}"

    cat > "${SPCTL_STUB}" <<'EOF'
#!/bin/zsh
print -r -- "spctl $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
EOF
    chmod +x "${SPCTL_STUB}"
}

function run_notarizer {
    BOUNDLESS_TRANSLATOR_XCRUN_EXECUTABLE="${XCRUN_STUB}" \
    BOUNDLESS_TRANSLATOR_SPCTL_EXECUTABLE="${SPCTL_STUB}" \
    BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
    BOUNDLESS_TRANSLATOR_TEST_SUBMIT_RESULT="${BOUNDLESS_TRANSLATOR_TEST_SUBMIT_RESULT:-success}" \
        zsh "${NOTARIZER}" "$@"
}

function test_notarize_dmg_when_path_is_missing_then_fails_before_calling_apple_tools {
    # Arrange
    : > "${CALL_LOG}"

    # Act & Assert
    if run_notarizer >/dev/null 2>&1; then
        print -u2 "Expected notarization without a DMG path to fail."
        return 1
    fi
    [[ ! -s "${CALL_LOG}" ]]
}

function test_notarize_dmg_when_dmg_is_missing_then_fails_before_calling_apple_tools {
    # Arrange
    local missing_dmg="${TEMP_ROOT}/Missing.dmg"
    : > "${CALL_LOG}"

    # Act & Assert
    if run_notarizer "${missing_dmg}" >/dev/null 2>&1; then
        print -u2 "Expected notarization to fail when the DMG is missing."
        return 1
    fi
    [[ ! -s "${CALL_LOG}" ]]
}

function test_notarize_dmg_when_submission_succeeds_then_staples_and_assesses_same_dmg {
    # Arrange
    local dmg_path="${TEMP_ROOT}/Boundless Translator.dmg"
    print -n "test image" > "${dmg_path}"
    : > "${CALL_LOG}"

    # Act
    run_notarizer "${dmg_path}"

    # Assert
    local expected_calls
    expected_calls=$'xcrun notarytool submit '${dmg_path}$' --keychain-profile BoundlessTranslatorNotary --wait\n'
    expected_calls+=$'xcrun stapler staple '${dmg_path}$'\n'
    expected_calls+=$'xcrun stapler validate '${dmg_path}$'\n'
    expected_calls+=$'spctl --assess --type open --context context:primary-signature --verbose=4 '${dmg_path}
    [[ "$(<"${CALL_LOG}")" == "${expected_calls}" ]]
}

function test_notarize_dmg_when_submission_fails_then_does_not_staple_or_assess {
    # Arrange
    local dmg_path="${TEMP_ROOT}/Rejected.dmg"
    print -n "test image" > "${dmg_path}"
    : > "${CALL_LOG}"

    # Act & Assert
    if BOUNDLESS_TRANSLATOR_TEST_SUBMIT_RESULT="failure" run_notarizer "${dmg_path}" >/dev/null 2>&1; then
        print -u2 "Expected rejected notarization to fail."
        return 1
    fi
    [[ "$(<"${CALL_LOG}")" == "xcrun notarytool submit ${dmg_path} --keychain-profile BoundlessTranslatorNotary --wait" ]]
}

create_tool_stubs
test_notarize_dmg_when_path_is_missing_then_fails_before_calling_apple_tools
test_notarize_dmg_when_dmg_is_missing_then_fails_before_calling_apple_tools
test_notarize_dmg_when_submission_succeeds_then_staples_and_assesses_same_dmg
test_notarize_dmg_when_submission_fails_then_does_not_staple_or_assess

print "DMG notarization tests passed."
