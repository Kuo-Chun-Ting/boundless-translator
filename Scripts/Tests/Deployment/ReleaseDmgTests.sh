#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly RELEASER="${PROJECT_ROOT}/Scripts/release_dmg.sh"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-release-test-dmg-tests.XXXXXX)"
readonly BUILD_ROOT="${TEMP_ROOT}/Build"
readonly CALL_LOG="${TEMP_ROOT}/calls.log"
readonly BUILD_STUB="${TEMP_ROOT}/build-dmg"
readonly NOTARIZE_STUB="${TEMP_ROOT}/notarize"
readonly MV_STUB="${TEMP_ROOT}/mv"
trap 'rm -rf "${TEMP_ROOT}"' EXIT

cat > "${BUILD_STUB}" <<'STUB'
#!/bin/zsh
set -eu
print -r -- "build $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
[[ "${TEST_FAIL_RELEASE_STEP:-}" != build ]]
print built > "$1"
STUB

cat > "${NOTARIZE_STUB}" <<'STUB'
#!/bin/zsh
set -eu
print notarize >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
[[ "${TEST_FAIL_RELEASE_STEP:-}" != notarize ]]
print -n notarized >> "$1"
STUB

cat > "${MV_STUB}" <<'STUB'
#!/bin/zsh
set -eu
[[ "${TEST_FAIL_RELEASE_STEP:-}" != publish ]]
exec /bin/mv "$@"
STUB
chmod +x "${BUILD_STUB}" "${NOTARIZE_STUB}" "${MV_STUB}"

function run_releaser {
    BOUNDLESS_TRANSLATOR_BUILD_DMG_EXECUTABLE="${BUILD_STUB}" \
    BOUNDLESS_TRANSLATOR_NOTARIZE_EXECUTABLE="${NOTARIZE_STUB}" \
    BOUNDLESS_TRANSLATOR_MV_EXECUTABLE="${MV_STUB}" \
    BOUNDLESS_TRANSLATOR_RELEASE_BUILD_ROOT="${BUILD_ROOT}" \
    BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
        zsh "${RELEASER}" "$@"
}

function test_release_dmg_when_run_then_notarizes_and_publishes_test_image {
    # Arrange
    : > "${CALL_LOG}"

    # Act
    run_releaser

    # Assert
    [[ "$(sed -n '1p' "${CALL_LOG}")" == build\ *'/Boundless Translator-test.dmg' ]]
    [[ "$(sed -n '2p' "${CALL_LOG}")" == notarize ]]
    [[ "$(<"${BUILD_ROOT}/Boundless Translator-test.dmg")" == $'built\nnotarized' ]]
}

function test_release_dmg_when_argument_is_given_then_stops_before_build {
    # Arrange
    : > "${CALL_LOG}"

    # Act & Assert
    if run_releaser --test >/dev/null 2>&1; then
        print -u2 'Expected release_dmg.sh to reject arguments.'
        return 1
    fi
    [[ ! -s "${CALL_LOG}" ]]
}

function test_release_dmg_when_release_step_fails_then_preserves_previous_image {
    local step
    for step in build notarize publish; do
        # Arrange
        mkdir -p "${BUILD_ROOT}"
        print -n previous > "${BUILD_ROOT}/Boundless Translator-test.dmg"
        : > "${CALL_LOG}"

        # Act & Assert
        if TEST_FAIL_RELEASE_STEP="${step}" run_releaser >/dev/null 2>&1; then
            print -u2 "Expected ${step} failure to stop the test DMG release."
            return 1
        fi
        [[ "$(<"${BUILD_ROOT}/Boundless Translator-test.dmg")" == previous ]]
    done
}

test_release_dmg_when_run_then_notarizes_and_publishes_test_image
test_release_dmg_when_argument_is_given_then_stops_before_build
test_release_dmg_when_release_step_fails_then_preserves_previous_image
print 'Test DMG release tests passed.'
