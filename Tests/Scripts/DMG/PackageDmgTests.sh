#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly PACKAGER="${PROJECT_ROOT}/Scripts/DMG/package_dmg.sh"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-package-dmg-tests.XXXXXX)"
readonly APP_PATH="${TEMP_ROOT}/Boundless Translator.app"
readonly MOCK_BIN="${TEMP_ROOT}/bin"
readonly CALL_LOG="${TEMP_ROOT}/calls.log"
trap 'rm -rf "${TEMP_ROOT}"' EXIT

function create_tool_stubs {
    mkdir -p "${MOCK_BIN}"
    cat > "${MOCK_BIN}/create-dmg" <<'STUB'
#!/bin/zsh
print -r -- "create-dmg $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
print image > "${@[-2]}"
STUB
    cat > "${MOCK_BIN}/codesign" <<'STUB'
#!/bin/zsh
print -r -- "codesign $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
[[ "${TEST_CODESIGN_FAIL:-false}" != true ]]
STUB
    cat > "${MOCK_BIN}/hdiutil" <<'STUB'
#!/bin/zsh
print -r -- "hdiutil $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
STUB
    chmod +x "${MOCK_BIN}/create-dmg" "${MOCK_BIN}/codesign" "${MOCK_BIN}/hdiutil"
}

function run_packager {
    PATH="${MOCK_BIN}:${PATH}" \
    BOUNDLESS_TRANSLATOR_CREATE_DMG_EXECUTABLE="${MOCK_BIN}/create-dmg" \
    BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
        zsh "${PACKAGER}" "$@"
}

function test_package_dmg_when_paths_are_missing_then_stops_before_packaging {
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

function test_package_dmg_when_inputs_are_valid_then_creates_and_signs_image_without_verifying_it {
    # Arrange
    local output_dmg="${TEMP_ROOT}/Complete.dmg"
    mkdir -p "${APP_PATH}"
    : > "${CALL_LOG}"

    # Act
    run_packager "${APP_PATH}" "${output_dmg}"

    # Assert
    [[ -f "${output_dmg}" ]]
    local calls="$(<"${CALL_LOG}")"
    [[ "${calls}" == *$'create-dmg '* ]]
    [[ "${calls}" == *$'codesign --force --timestamp --sign '* ]]
    [[ "${calls}" != *hdiutil* ]]
}

function test_package_dmg_when_signing_fails_then_preserves_existing_image {
    # Arrange
    local output_dmg="${TEMP_ROOT}/Existing.dmg"
    print -n 'existing image' > "${output_dmg}"
    mkdir -p "${APP_PATH}"
    : > "${CALL_LOG}"

    # Act & Assert
    if TEST_CODESIGN_FAIL=true run_packager "${APP_PATH}" "${output_dmg}" >/dev/null 2>&1; then
        print -u2 'Expected signing failure to stop packaging.'
        return 1
    fi
    [[ "$(<"${output_dmg}")" == 'existing image' ]]
}

function test_package_dmg_when_e2e_app_is_given_then_uses_e2e_volume_and_app_name {
    # Arrange
    local e2e_app="${TEMP_ROOT}/Boundless Translator E2E.app"
    local output_dmg="${TEMP_ROOT}/Boundless Translator E2E-test.dmg"
    mkdir -p "${e2e_app}"
    : > "${CALL_LOG}"

    # Act
    run_packager "${e2e_app}" "${output_dmg}"

    # Assert
    local calls="$(<"${CALL_LOG}")"
    [[ "${calls}" == *'--volname Boundless Translator E2E'* ]]
    [[ "${calls}" == *'--icon Boundless Translator E2E.app 170 180'* ]]
    [[ "${calls}" == *'--hide-extension Boundless Translator E2E.app'* ]]
}

create_tool_stubs
test_package_dmg_when_paths_are_missing_then_stops_before_packaging
test_package_dmg_when_source_app_is_missing_then_preserves_existing_image
test_package_dmg_when_inputs_are_valid_then_creates_and_signs_image_without_verifying_it
test_package_dmg_when_e2e_app_is_given_then_uses_e2e_volume_and_app_name
test_package_dmg_when_signing_fails_then_preserves_existing_image
print 'DMG packaging tests passed.'
