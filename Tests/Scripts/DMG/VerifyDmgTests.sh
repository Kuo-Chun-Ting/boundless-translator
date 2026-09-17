#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly VERIFIER="${PROJECT_ROOT}/Scripts/DMG/verify_dmg.sh"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-verify-dmg-tests.XXXXXX)"
readonly DMG_PATH="${TEMP_ROOT}/Boundless Translator-test.dmg"
readonly MOCK_BIN="${TEMP_ROOT}/bin"
readonly CALL_LOG="${TEMP_ROOT}/calls.log"
trap 'rm -rf "${TEMP_ROOT}"' EXIT

function create_tool_stubs {
    mkdir -p "${MOCK_BIN}"
    cat > "${MOCK_BIN}/codesign" <<'STUB'
#!/bin/zsh
print -r -- "codesign $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
if [[ "$*" == *--display* ]]; then
    print 'TeamIdentifier=3S9ZKKJ6PW'
    print 'Timestamp=verified-test-timestamp'
fi
STUB
    cat > "${MOCK_BIN}/hdiutil" <<'STUB'
#!/bin/zsh
print -r -- "hdiutil $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
[[ "$1" == attach ]] || exit 0

mount_point=''
while [[ "$#" -gt 0 ]]; do
    if [[ "$1" == -mountpoint ]]; then
        mount_point="$2"
        break
    fi
    shift
done
mkdir -p "${mount_point}"
[[ "${TEST_MOUNT_CONTENTS_COMPLETE:-true}" == true ]] || exit 0
mkdir -p "${mount_point}/Boundless Translator.app" "${mount_point}/.background"
ln -s /Applications "${mount_point}/Applications"
touch "${mount_point}/.DS_Store" "${mount_point}/.background/DMGBackground.png"
STUB
    cat > "${MOCK_BIN}/verify-app" <<'STUB'
#!/bin/zsh
print -r -- "verify-app $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
STUB
    chmod +x "${MOCK_BIN}/codesign" "${MOCK_BIN}/hdiutil" "${MOCK_BIN}/verify-app"
}

function run_verifier {
    PATH="${MOCK_BIN}:${PATH}" \
    BOUNDLESS_TRANSLATOR_VERIFY_APP_EXECUTABLE="${MOCK_BIN}/verify-app" \
    BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
        zsh "${VERIFIER}" "$@"
}

function test_verify_dmg_when_path_is_missing_then_stops_before_verification {
    # Arrange
    : > "${CALL_LOG}"

    # Act & Assert
    if run_verifier >/dev/null 2>&1; then
        print -u2 'Expected verification without a DMG path to fail.'
        return 1
    fi
    [[ ! -s "${CALL_LOG}" ]]
}

function test_verify_dmg_when_image_is_complete_then_checks_image_and_contained_app {
    # Arrange
    print image > "${DMG_PATH}"
    : > "${CALL_LOG}"

    # Act
    run_verifier "${DMG_PATH}"

    # Assert
    local calls="$(<"${CALL_LOG}")"
    [[ "${calls}" == *$'hdiutil verify '* ]]
    [[ "${calls}" == *$'codesign --verify --strict --verbose=2 '* ]]
    [[ "${calls}" == *$'hdiutil attach -readonly -nobrowse -mountpoint '* ]]
    [[ "${calls}" == *$'verify-app '*'/Boundless Translator.app'* ]]
    [[ "${calls}" == *$'hdiutil detach '* ]]
}

function test_verify_dmg_when_mounted_contents_are_incomplete_then_detaches_and_fails {
    # Arrange
    print image > "${DMG_PATH}"
    : > "${CALL_LOG}"

    # Act & Assert
    if TEST_MOUNT_CONTENTS_COMPLETE=false run_verifier "${DMG_PATH}" >/dev/null 2>&1; then
        print -u2 'Expected incomplete mounted contents to fail verification.'
        return 1
    fi
    [[ "$(<"${CALL_LOG}")" == *$'hdiutil detach '* ]]
}

create_tool_stubs
test_verify_dmg_when_path_is_missing_then_stops_before_verification
test_verify_dmg_when_image_is_complete_then_checks_image_and_contained_app
test_verify_dmg_when_mounted_contents_are_incomplete_then_detaches_and_fails
print 'DMG verification tests passed.'
