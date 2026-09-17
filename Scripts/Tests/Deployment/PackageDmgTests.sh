#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly PACKAGER="${PROJECT_ROOT}/Scripts/Tools/package_dmg.sh"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-dmg-tests.XXXXXX)"
readonly APP_PATH="${TEMP_ROOT}/Boundless Translator.app"
readonly MOCK_BIN="${TEMP_ROOT}/bin"
readonly CALL_LOG="${TEMP_ROOT}/calls.log"
trap 'rm -rf "${TEMP_ROOT}"' EXIT

function create_tool_stubs {
    mkdir -p "${MOCK_BIN}"
    cat > "${MOCK_BIN}/create-dmg" <<'EOF'
#!/bin/zsh
print -r -- "create-dmg $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
print image > "${@[-2]}"
EOF
    cat > "${MOCK_BIN}/codesign" <<'EOF'
#!/bin/zsh
print -r -- "codesign $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
if [[ "$*" == *--display* ]]; then
    print 'Authority=Developer ID Application: Chun Ting Kuo (3S9ZKKJ6PW)'
    print 'TeamIdentifier=3S9ZKKJ6PW'
    print 'Timestamp=verified-test-timestamp'
fi
EOF
    cat > "${MOCK_BIN}/hdiutil" <<'EOF'
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
EOF
    cat > "${MOCK_BIN}/verify-app" <<'EOF'
#!/bin/zsh
print -r -- "verify-app $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
EOF
    chmod +x "${MOCK_BIN}/create-dmg" "${MOCK_BIN}/codesign" "${MOCK_BIN}/hdiutil" "${MOCK_BIN}/verify-app"
}

function run_packager {
    PATH="${MOCK_BIN}:${PATH}" \
    BOUNDLESS_TRANSLATOR_CREATE_DMG_EXECUTABLE="${MOCK_BIN}/create-dmg" \
    BOUNDLESS_TRANSLATOR_VERIFY_EXECUTABLE="${MOCK_BIN}/verify-app" \
    BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
        zsh "${PACKAGER}" "$@"
}

function test_package_dmg_when_paths_are_missing_then_fails_before_creating_image {
    # Arrange
    : > "${CALL_LOG}"

    # Act & Assert
    if run_packager >/dev/null 2>&1; then
        print -u2 'Expected packaging without App and DMG paths to fail.'
        return 1
    fi
    [[ ! -s "${CALL_LOG}" ]]
}

function test_package_dmg_when_source_app_is_missing_then_preserves_existing_image {
    # Arrange
    local missing_app="${TEMP_ROOT}/Missing.app"
    local output_dmg="${TEMP_ROOT}/Existing.dmg"
    print -n 'existing image' > "${output_dmg}"
    : > "${CALL_LOG}"

    # Act & Assert
    if run_packager "${missing_app}" "${output_dmg}" >/dev/null 2>&1; then
        print -u2 'Expected packaging to fail when the source App is missing.'
        return 1
    fi
    [[ "$(<"${output_dmg}")" == 'existing image' ]]
    [[ ! -s "${CALL_LOG}" ]]
}

function test_package_dmg_when_image_is_complete_then_validates_mounted_contents {
    # Arrange
    local output_dmg="${TEMP_ROOT}/Complete.dmg"
    mkdir -p "${APP_PATH}"
    : > "${CALL_LOG}"

    # Act
    run_packager "${APP_PATH}" "${output_dmg}"

    # Assert
    [[ -f "${output_dmg}" ]]
    local calls="$(<"${CALL_LOG}")"
    [[ "${calls}" == *$'hdiutil verify '* ]]
    [[ "${calls}" == *$'codesign --verify --strict --verbose=2 '* ]]
    [[ "${calls}" == *$'hdiutil attach -readonly -nobrowse -mountpoint '* ]]
    [[ "${calls}" == *$'verify-app '*'/Boundless Translator.app'* ]]
    [[ "${calls}" == *$'hdiutil detach '* ]]
}

function test_package_dmg_when_mounted_contents_are_incomplete_then_preserves_existing_image {
    # Arrange
    local output_dmg="${TEMP_ROOT}/Existing.dmg"
    print -n 'existing image' > "${output_dmg}"
    mkdir -p "${APP_PATH}"
    : > "${CALL_LOG}"

    # Act & Assert
    if TEST_MOUNT_CONTENTS_COMPLETE=false run_packager "${APP_PATH}" "${output_dmg}" >/dev/null 2>&1; then
        print -u2 'Expected incomplete mounted contents to fail validation.'
        return 1
    fi
    [[ "$(<"${output_dmg}")" == 'existing image' ]]
    [[ "$(<"${CALL_LOG}")" == *$'hdiutil detach '* ]]
}

create_tool_stubs
test_package_dmg_when_paths_are_missing_then_fails_before_creating_image
test_package_dmg_when_source_app_is_missing_then_preserves_existing_image
test_package_dmg_when_image_is_complete_then_validates_mounted_contents
test_package_dmg_when_mounted_contents_are_incomplete_then_preserves_existing_image

print 'DMG packaging tests passed.'
