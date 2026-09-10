#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly RELEASER="${PROJECT_ROOT}/Scripts/release_dmg.sh"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-release-tests.XXXXXX)"
readonly CALL_LOG="${TEMP_ROOT}/calls.log"
readonly INFO_PLIST="${TEMP_ROOT}/Info.plist"
readonly BUILD_ROOT="${TEMP_ROOT}/Build"
readonly RELEASE_DMG_PATH="${BUILD_ROOT}/Boundless Translator-0.2.0.dmg"
readonly BUILD_STUB="${TEMP_ROOT}/step-build-dmg"
readonly NOTARIZE_STUB="${TEMP_ROOT}/step-notarize"
readonly MV_STUB="${TEMP_ROOT}/step-mv"

function clean_up {
    rm -rf "${TEMP_ROOT}"
}
trap clean_up EXIT

function create_info_plist_fixture {
    plutil -create xml1 "${INFO_PLIST}"
    plutil -insert CFBundleShortVersionString -string "0.1.0" "${INFO_PLIST}"
    plutil -insert CFBundleVersion -string "1" "${INFO_PLIST}"
}

function create_build_stub {
    cat > "${BUILD_STUB}" <<'EOF'
#!/bin/zsh
set -eu
print -r -- "${0:t} $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
print -r -- "info ${BOUNDLESS_TRANSLATOR_BUILD_INFO_PLIST:-missing}" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
[[ "$(plutil -extract CFBundleShortVersionString raw "${BOUNDLESS_TRANSLATOR_INFO_PLIST}")" == '0.1.0' ]]
[[ "$(plutil -extract CFBundleVersion raw "${BOUNDLESS_TRANSLATOR_INFO_PLIST}")" == '1' ]]
mkdir -p "${1:h}"
print -n "$(plutil -extract CFBundleShortVersionString raw "${BOUNDLESS_TRANSLATOR_BUILD_INFO_PLIST}"):$(plutil -extract CFBundleVersion raw "${BOUNDLESS_TRANSLATOR_BUILD_INFO_PLIST}")" > "$1"
EOF
    chmod +x "${BUILD_STUB}"
}

function create_failing_build_stub {
    cat > "${BUILD_STUB}" <<'EOF'
#!/bin/zsh
set -eu
print -r -- "${0:t} $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
exit 1
EOF
    chmod +x "${BUILD_STUB}"
}

function create_notarize_stub {
    cat > "${NOTARIZE_STUB}" <<'EOF'
#!/bin/zsh
set -eu
print -r -- "${0:t} $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
print -n " notarized" >> "$1"
EOF
    chmod +x "${NOTARIZE_STUB}"
}

function create_failing_notarize_stub {
    cat > "${NOTARIZE_STUB}" <<'EOF'
#!/bin/zsh
set -eu
print -r -- "${0:t} $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
exit 1
EOF
    chmod +x "${NOTARIZE_STUB}"
}

function create_mv_stub {
    cat > "${MV_STUB}" <<'EOF'
#!/bin/zsh
set -eu
destination="${@: -1}"
if [[ "${destination}" == "${BOUNDLESS_TRANSLATOR_INFO_PLIST}" ]]; then
    plutil -lint "${BOUNDLESS_TRANSLATOR_INFO_PLIST}" >/dev/null
    print -r -- "before $(plutil -extract CFBundleShortVersionString raw "${BOUNDLESS_TRANSLATOR_INFO_PLIST}")" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
    /bin/mv "$@"
    plutil -lint "${BOUNDLESS_TRANSLATOR_INFO_PLIST}" >/dev/null
    print -r -- "after $(plutil -extract CFBundleShortVersionString raw "${BOUNDLESS_TRANSLATOR_INFO_PLIST}")" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
    exit 0
fi
if [[ "${TEST_FAIL_DMG_PUBLISH:-false}" == true && "${destination}" == *'Boundless Translator-0.2.0.dmg' ]]; then
    exit 1
fi
/bin/mv "$@"
EOF
    chmod +x "${MV_STUB}"
}

function run_releaser {
    BOUNDLESS_TRANSLATOR_BUILD_DMG_EXECUTABLE="${BUILD_STUB}" \
    BOUNDLESS_TRANSLATOR_NOTARIZE_EXECUTABLE="${NOTARIZE_STUB}" \
    BOUNDLESS_TRANSLATOR_MV_EXECUTABLE="${MV_STUB}" \
    BOUNDLESS_TRANSLATOR_INFO_PLIST="${INFO_PLIST}" \
    BOUNDLESS_TRANSLATOR_RELEASE_BUILD_ROOT="${BUILD_ROOT}" \
    BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
        zsh "${RELEASER}" "$@"
}

function test_release_dmg_when_source_is_missing_then_releases_lock_for_next_attempt {
    # Arrange
    create_build_stub
    create_notarize_stub
    create_mv_stub
    rm -f "${INFO_PLIST}"
    : > "${CALL_LOG}"

    # Act & Assert
    if run_releaser 0.2.0 >/dev/null 2>&1; then
        print -u2 'Expected a missing source plist to fail.'
        return 1
    fi
    [[ ! -e "${BUILD_ROOT}/.release-lock" ]]
    create_info_plist_fixture
    run_releaser 0.2.0
}

function test_release_dmg_build_fixture_when_source_changes_early_then_fails_fast {
    # Arrange
    create_info_plist_fixture
    create_build_stub
    local staged_info="${TEMP_ROOT}/premature-staged.plist"
    cp "${INFO_PLIST}" "${staged_info}"
    plutil -replace CFBundleShortVersionString -string '0.2.0' "${INFO_PLIST}"
    : > "${CALL_LOG}"

    # Act & Assert
    if BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
        BOUNDLESS_TRANSLATOR_INFO_PLIST="${INFO_PLIST}" \
        BOUNDLESS_TRANSLATOR_BUILD_INFO_PLIST="${staged_info}" \
        "${BUILD_STUB}" "${TEMP_ROOT}/premature.dmg" >/dev/null 2>&1; then
        print -u2 'Expected the build fixture to reject premature source mutation.'
        return 1
    fi
    [[ ! -e "${TEMP_ROOT}/premature.dmg" ]]
}

function test_release_dmg_when_artifact_publish_fails_then_atomically_restores_source {
    # Arrange
    create_info_plist_fixture
    create_build_stub
    create_notarize_stub
    create_mv_stub
    : > "${CALL_LOG}"

    # Act & Assert
    if TEST_FAIL_DMG_PUBLISH=true run_releaser 0.2.0 >/dev/null 2>&1; then
        print -u2 'Expected final DMG publication to fail.'
        return 1
    fi
    [[ "$(plutil -extract CFBundleShortVersionString raw "${INFO_PLIST}")" == '0.1.0' ]]
    [[ "$(tail -n 4 "${CALL_LOG}")" == $'before 0.1.0\nafter 0.2.0\nbefore 0.2.0\nafter 0.1.0' ]]
}

function test_release_dmg_when_version_is_valid_then_builds_and_notarizes_versioned_dmg {
    # Arrange
    create_info_plist_fixture
    create_build_stub
    create_notarize_stub
    : > "${CALL_LOG}"

    # Act
    run_releaser 0.2.0

    # Assert
    local build_call="$(sed -n '1p' "${CALL_LOG}")"
    local metadata_call="$(sed -n '2p' "${CALL_LOG}")"
    local notarize_call="$(sed -n '3p' "${CALL_LOG}")"
    local temporary_dmg_path="${build_call#step-build-dmg }"
    [[ "${notarize_call}" == "step-notarize ${temporary_dmg_path}" ]]
    [[ "${temporary_dmg_path}" != "${RELEASE_DMG_PATH}" ]]
    [[ "${temporary_dmg_path:t}" == "Boundless Translator-0.2.0.dmg" ]]
    [[ "${metadata_call}" == info\ * ]]
    [[ "$(<"${RELEASE_DMG_PATH}")" == "0.2.0:2 notarized" ]]
    [[ "$(plutil -extract CFBundleShortVersionString raw "${INFO_PLIST}")" == "0.2.0" ]]
    [[ "$(plutil -extract CFBundleVersion raw "${INFO_PLIST}")" == "2" ]]
}

function test_release_dmg_when_version_is_invalid_then_preserves_version_and_skips_release {
    # Arrange
    create_info_plist_fixture
    create_build_stub
    create_notarize_stub
    : > "${CALL_LOG}"

    # Act & Assert
    if run_releaser version-two >/dev/null 2>&1; then
        print -u2 "Expected an invalid release version to fail."
        return 1
    fi
    [[ "$(plutil -extract CFBundleShortVersionString raw "${INFO_PLIST}")" == "0.1.0" ]]
    [[ "$(plutil -extract CFBundleVersion raw "${INFO_PLIST}")" == "1" ]]
    [[ ! -s "${CALL_LOG}" ]]
}

function test_release_dmg_when_release_lock_exists_then_preserves_version_and_skips_release {
    # Arrange
    create_info_plist_fixture
    create_build_stub
    create_notarize_stub
    mkdir -p "${BUILD_ROOT}/.release-lock"
    : > "${CALL_LOG}"

    # Act & Assert
    if run_releaser 0.2.0 >/dev/null 2>&1; then
        print -u2 'Expected a concurrent versioned release to fail.'
        return 1
    fi
    [[ "$(plutil -extract CFBundleShortVersionString raw "${INFO_PLIST}")" == '0.1.0' ]]
    [[ "$(plutil -extract CFBundleVersion raw "${INFO_PLIST}")" == '1' ]]
    [[ ! -s "${CALL_LOG}" ]]
    rmdir "${BUILD_ROOT}/.release-lock"
}

function test_release_dmg_when_build_fails_then_restores_version_and_preserves_previous_release {
    # Arrange
    create_info_plist_fixture
    create_failing_build_stub
    create_notarize_stub
    mkdir -p "${BUILD_ROOT}"
    print -n "previous release" > "${RELEASE_DMG_PATH}"
    : > "${CALL_LOG}"

    # Act & Assert
    if run_releaser 0.2.0 >/dev/null 2>&1; then
        print -u2 "Expected a build failure to fail the release."
        return 1
    fi
    [[ "$(plutil -extract CFBundleShortVersionString raw "${INFO_PLIST}")" == "0.1.0" ]]
    [[ "$(plutil -extract CFBundleVersion raw "${INFO_PLIST}")" == "1" ]]
    [[ "$(<"${RELEASE_DMG_PATH}")" == "previous release" ]]
}

function test_release_dmg_when_notarization_fails_then_restores_version_and_preserves_previous_release {
    # Arrange
    create_info_plist_fixture
    create_build_stub
    create_failing_notarize_stub
    mkdir -p "${BUILD_ROOT}"
    print -n "previous release" > "${RELEASE_DMG_PATH}"
    : > "${CALL_LOG}"

    # Act & Assert
    if run_releaser 0.2.0 >/dev/null 2>&1; then
        print -u2 "Expected a notarization failure to fail the release."
        return 1
    fi
    [[ "$(plutil -extract CFBundleShortVersionString raw "${INFO_PLIST}")" == "0.1.0" ]]
    [[ "$(plutil -extract CFBundleVersion raw "${INFO_PLIST}")" == "1" ]]
    [[ "$(<"${RELEASE_DMG_PATH}")" == "previous release" ]]
}

function test_release_dmg_when_test_requested_then_skips_notarization_and_preserves_versions_and_release {
    # Arrange
    create_info_plist_fixture
    create_build_stub
    create_failing_notarize_stub
    mkdir -p "${BUILD_ROOT}"
    print -n 'previous release' > "${RELEASE_DMG_PATH}"
    : > "${CALL_LOG}"
    local original_info="$(shasum "${INFO_PLIST}")"

    # Act
    run_releaser --test

    # Assert
    [[ "$(<"${BUILD_ROOT}/Boundless Translator-test.dmg")" == '0.1.0:1' ]]
    [[ "$(<"${RELEASE_DMG_PATH}")" == 'previous release' ]]
    [[ "$(shasum "${INFO_PLIST}")" == "${original_info}" ]]
    [[ "$(wc -l < "${CALL_LOG}" | tr -d ' ')" == 2 ]]
}

function test_release_dmg_when_test_build_fails_then_preserves_previous_test_dmg {
    # Arrange
    create_info_plist_fixture
    create_failing_build_stub
    print -n 'previous test' > "${BUILD_ROOT}/Boundless Translator-test.dmg"
    local original_info="$(shasum "${INFO_PLIST}")"

    # Act & Assert
    if run_releaser --test >/dev/null 2>&1; then
        print -u2 'Expected test build failure to stop packaging.'
        return 1
    fi
    [[ "$(<"${BUILD_ROOT}/Boundless Translator-test.dmg")" == 'previous test' ]]
    [[ "$(shasum "${INFO_PLIST}")" == "${original_info}" ]]
}

create_mv_stub
test_release_dmg_when_test_requested_then_skips_notarization_and_preserves_versions_and_release
test_release_dmg_when_test_build_fails_then_preserves_previous_test_dmg
test_release_dmg_when_source_is_missing_then_releases_lock_for_next_attempt
test_release_dmg_build_fixture_when_source_changes_early_then_fails_fast
test_release_dmg_when_artifact_publish_fails_then_atomically_restores_source
test_release_dmg_when_version_is_valid_then_builds_and_notarizes_versioned_dmg
test_release_dmg_when_version_is_invalid_then_preserves_version_and_skips_release
test_release_dmg_when_release_lock_exists_then_preserves_version_and_skips_release
test_release_dmg_when_build_fails_then_restores_version_and_preserves_previous_release
test_release_dmg_when_notarization_fails_then_restores_version_and_preserves_previous_release

print "DMG release tests passed."
