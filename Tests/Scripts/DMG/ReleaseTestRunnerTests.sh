#!/bin/zsh
set -euo pipefail
readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-release-runner-tests.XXXXXX)"
trap 'rm -rf "${TEMP_ROOT}"' EXIT
export MOCK_CALL_LOG="${TEMP_ROOT}/calls"
export BOUNDLESS_TRANSLATOR_RELEASE_BUILD_ROOT="${TEMP_ROOT}/Build"
mkdir -p "${BOUNDLESS_TRANSLATOR_RELEASE_BUILD_ROOT}"
for name in release verify-dmg xcrun spctl verify-app; do
    cat > "${TEMP_ROOT}/${name}" <<'STUB'
#!/bin/zsh
print -r -- "${0:t} $*" >> "${MOCK_CALL_LOG}"
[[ "${FAIL_STEP:-}" != "${0:t}" ]] || exit 42
if [[ "${0:t}" == release ]]; then
    touch "${BOUNDLESS_TRANSLATOR_RELEASE_BUILD_ROOT}/Boundless Translator DMG Test.dmg"
fi
STUB
    chmod +x "${TEMP_ROOT}/${name}"
done
cat > "${TEMP_ROOT}/hdiutil" <<'STUB'
#!/bin/zsh
print -r -- "hdiutil $*" >> "${MOCK_CALL_LOG}"
if [[ "$1" == attach ]]; then
    while [[ "$1" != -mountpoint ]]; do shift; done
    mkdir -p "$2/Boundless Translator DMG Test.app"
fi
STUB
cat > "${TEMP_ROOT}/ditto" <<'STUB'
#!/bin/zsh
print -r -- "ditto $*" >> "${MOCK_CALL_LOG}"
/usr/bin/ditto "$@"
STUB
chmod +x "${TEMP_ROOT}"/{hdiutil,ditto}
function run_release_tests {
    PATH="${TEMP_ROOT}:${PATH}" \
    BOUNDLESS_TRANSLATOR_RELEASE_DMG_EXECUTABLE="${TEMP_ROOT}/release" \
    BOUNDLESS_TRANSLATOR_VERIFY_DMG_EXECUTABLE="${TEMP_ROOT}/verify-dmg" \
    BOUNDLESS_TRANSLATOR_VERIFY_APP_EXECUTABLE="${TEMP_ROOT}/verify-app" \
        zsh "${PROJECT_ROOT}/Scripts/run_release_tests.sh" "$@"
}
function test_release_checks_when_default_then_builds_once_and_launches_installed_copy {
    # Arrange
    : > "${MOCK_CALL_LOG}"
    # Act
    run_release_tests
    # Assert
    local calls="$(<"${MOCK_CALL_LOG}")"
    [[ "$(grep -c '^release ' "${MOCK_CALL_LOG}")" == 1 ]]
    [[ "$calls" == *'xcrun stapler validate '* && "$calls" == *'spctl --assess '* ]]
    [[ "$calls" == *'ditto '*'/Installed/Boundless Translator DMG Test.app'* ]]
    [[ "$(tail -n 1 "${MOCK_CALL_LOG}")" == 'verify-app '*'/Installed/Boundless Translator DMG Test.app' ]]
}
function test_release_checks_when_existing_dmg_then_does_not_rebuild_or_submit {
    # Arrange
    : > "${MOCK_CALL_LOG}"
    local dmg="${BOUNDLESS_TRANSLATOR_RELEASE_BUILD_ROOT}/Boundless Translator DMG Test.dmg"
    # Act
    run_release_tests "$dmg"
    # Assert
    [[ "$(head -n 1 "${MOCK_CALL_LOG}")" == "verify-dmg $dmg" ]]
    ! grep -q '^release ' "${MOCK_CALL_LOG}"
    ! grep -q notarytool "${MOCK_CALL_LOG}"
}
function test_release_checks_when_validation_or_launch_fails_then_returns_failure {
    # Act & Assert
    if FAIL_STEP=spctl run_release_tests >/dev/null 2>&1; then return 1; fi
    if FAIL_STEP=verify-app run_release_tests >/dev/null 2>&1; then return 1; fi
    [[ "$(grep -c 'hdiutil detach' "${MOCK_CALL_LOG}")" -gt 0 ]]
}
test_release_checks_when_default_then_builds_once_and_launches_installed_copy
test_release_checks_when_existing_dmg_then_does_not_rebuild_or_submit
test_release_checks_when_validation_or_launch_fails_then_returns_failure
print 'Release runner tests passed.'
