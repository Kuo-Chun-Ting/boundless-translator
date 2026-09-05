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
print -r -- "${0:t} $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
mkdir -p "${1:h}"
print -n "built dmg" > "$1"
EOF
    chmod +x "${BUILD_STUB}"
}

function create_failing_build_stub {
    cat > "${BUILD_STUB}" <<'EOF'
#!/bin/zsh
print -r -- "${0:t} $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
exit 1
EOF
    chmod +x "${BUILD_STUB}"
}

function create_notarize_stub {
    cat > "${NOTARIZE_STUB}" <<'EOF'
#!/bin/zsh
print -r -- "${0:t} $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
print -n " notarized" >> "$1"
EOF
    chmod +x "${NOTARIZE_STUB}"
}

function create_failing_notarize_stub {
    cat > "${NOTARIZE_STUB}" <<'EOF'
#!/bin/zsh
print -r -- "${0:t} $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
exit 1
EOF
    chmod +x "${NOTARIZE_STUB}"
}

function run_releaser {
    BOUNDLESS_TRANSLATOR_BUILD_DMG_EXECUTABLE="${BUILD_STUB}" \
    BOUNDLESS_TRANSLATOR_NOTARIZE_EXECUTABLE="${NOTARIZE_STUB}" \
    BOUNDLESS_TRANSLATOR_INFO_PLIST="${INFO_PLIST}" \
    BOUNDLESS_TRANSLATOR_RELEASE_BUILD_ROOT="${BUILD_ROOT}" \
    BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
        zsh "${RELEASER}" "$@"
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
    local notarize_call="$(sed -n '2p' "${CALL_LOG}")"
    local temporary_dmg_path="${build_call#step-build-dmg }"
    [[ "${notarize_call}" == "step-notarize ${temporary_dmg_path}" ]]
    [[ "${temporary_dmg_path}" != "${RELEASE_DMG_PATH}" ]]
    [[ "${temporary_dmg_path:t}" == "Boundless Translator-0.2.0.dmg" ]]
    [[ "$(<"${RELEASE_DMG_PATH}")" == "built dmg notarized" ]]
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

test_release_dmg_when_version_is_valid_then_builds_and_notarizes_versioned_dmg
test_release_dmg_when_version_is_invalid_then_preserves_version_and_skips_release
test_release_dmg_when_build_fails_then_restores_version_and_preserves_previous_release
test_release_dmg_when_notarization_fails_then_restores_version_and_preserves_previous_release

print "DMG release tests passed."
