#!/bin/zsh
set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly RELEASER="${PROJECT_ROOT}/Scripts/release_dmg.sh"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-release-tests.XXXXXX)"
trap 'rm -rf "${TEMP_ROOT}"' EXIT
readonly BUILD_ROOT="${TEMP_ROOT}/Build"
readonly INFO_PLIST="${TEMP_ROOT}/Info.plist"
readonly DMG_PATH="${BUILD_ROOT}/Boundless Translator-test.dmg"
readonly CALL_LOG="${TEMP_ROOT}/calls.log"
readonly MOCK_BUILD="${TEMP_ROOT}/mock-build"
readonly MOCK_NOTARIZE="${TEMP_ROOT}/notarize"
readonly STUB_MV="${TEMP_ROOT}/mv"
mkdir -p "${BUILD_ROOT}"
print 'original metadata' > "${INFO_PLIST}"
cat > "${MOCK_BUILD}" <<'STUB'
#!/bin/zsh
set -eu
print build >> "${TEST_LOG}"
[[ "${FAIL_STEP:-}" != build ]]
cmp "${BOUNDLESS_TRANSLATOR_BUILD_INFO_PLIST}" "${BOUNDLESS_TRANSLATOR_INFO_PLIST}"
print -n built > "$1"
STUB
cat > "${MOCK_NOTARIZE}" <<'STUB'
#!/bin/zsh
set -eu
print notarize >> "${TEST_LOG}"
[[ "$(<"${TEST_DMG}")" == previous ]]
[[ "${FAIL_STEP:-}" != notarize ]]
print -n ' notarized' >> "$1"
STUB
cat > "${STUB_MV}" <<'STUB'
#!/bin/zsh
set -eu
[[ "${FAIL_STEP:-}" != publish ]]
/bin/mv "$@"
STUB
chmod +x "${MOCK_BUILD}" "${MOCK_NOTARIZE}" "${STUB_MV}"

function run_releaser {
    TEST_LOG="${CALL_LOG}" TEST_DMG="${DMG_PATH}" \
    BOUNDLESS_TRANSLATOR_BUILD_DMG_EXECUTABLE="${MOCK_BUILD}" \
    BOUNDLESS_TRANSLATOR_NOTARIZE_EXECUTABLE="${MOCK_NOTARIZE}" \
    BOUNDLESS_TRANSLATOR_MV_EXECUTABLE="${STUB_MV}" \
    BOUNDLESS_TRANSLATOR_INFO_PLIST="${INFO_PLIST}" \
    BOUNDLESS_TRANSLATOR_RELEASE_BUILD_ROOT="${BUILD_ROOT}" \
        zsh "${RELEASER}" "$@"
}

function test_release_dmg_when_test_requested_then_notarizes_before_replacing_previous_dmg {
    # Arrange
    print -n previous > "${DMG_PATH}"
    : > "${CALL_LOG}"
    # Act
    run_releaser --test
    # Assert
    [[ "$(<"${CALL_LOG}")" == $'build\nnotarize' ]]
    [[ "$(<"${DMG_PATH}")" == 'built notarized' ]]
    [[ "$(<"${INFO_PLIST}")" == 'original metadata' ]]
}

function test_release_dmg_when_step_fails_then_preserves_previous_dmg {
    # Arrange
    local step
    for step in build notarize publish; do
        print -n previous > "${DMG_PATH}"
        : > "${CALL_LOG}"
        # Act & Assert
        if FAIL_STEP="${step}" run_releaser --test; then
            print -u2 "Expected ${step} failure to stop release."
            return 1
        fi
        [[ "$(<"${DMG_PATH}")" == previous ]]
        [[ "$(<"${INFO_PLIST}")" == 'original metadata' ]]
        [[ -z "$(find "${BUILD_ROOT}" -name '.boundless-translator-test.*' -print)" ]]
    done
}

function test_release_dmg_when_version_given_then_rejects_before_building {
    # Arrange
    : > "${CALL_LOG}"
    # Act & Assert
    if run_releaser 0.2.0 > "${TEMP_ROOT}/error.log" 2>&1; then
        print -u2 'Expected versioned DMG release to be rejected.'
        return 1
    fi
    [[ ! -s "${CALL_LOG}" ]]
    [[ "$(<"${TEMP_ROOT}/error.log")" == *'Usage: release_dmg.sh --test'* ]]
}

test_release_dmg_when_test_requested_then_notarizes_before_replacing_previous_dmg
test_release_dmg_when_step_fails_then_preserves_previous_dmg
test_release_dmg_when_version_given_then_rejects_before_building
print 'DMG release tests passed.'
