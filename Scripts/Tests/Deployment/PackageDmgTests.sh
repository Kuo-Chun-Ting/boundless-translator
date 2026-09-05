#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly PACKAGER="${PROJECT_ROOT}/Scripts/Tools/package_dmg.sh"
readonly BUILD_APP="${PROJECT_ROOT}/Build/Boundless Translator.app"
readonly VERIFIER="${PROJECT_ROOT}/Scripts/Tools/verify_app.sh"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-dmg-tests.XXXXXX)"
active_mount_point=""

function clean_up {
    if [[ -n "${active_mount_point}" ]]; then
        hdiutil detach "${active_mount_point}" >/dev/null 2>&1 || true
    fi
    rm -rf "${TEMP_ROOT}"
}
trap clean_up EXIT

function test_package_dmg_when_paths_are_missing_then_fails_before_creating_image {
    # Arrange
    local call_log="${TEMP_ROOT}/create-dmg-calls.log"
    local create_dmg_stub="${TEMP_ROOT}/create-dmg"
    cat > "${create_dmg_stub}" <<'EOF'
#!/bin/zsh
print -r -- "$*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
EOF
    chmod +x "${create_dmg_stub}"
    : > "${call_log}"

    # Act & Assert
    if BOUNDLESS_TRANSLATOR_CREATE_DMG_EXECUTABLE="${create_dmg_stub}" \
        BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${call_log}" \
        zsh "${PACKAGER}" >/dev/null 2>&1; then
        print -u2 "Expected packaging without App and DMG paths to fail."
        return 1
    fi
    [[ ! -s "${call_log}" ]]
}

function test_package_dmg_when_source_app_is_missing_then_preserves_existing_image {
    # Arrange
    local missing_app="${TEMP_ROOT}/Missing.app"
    local output_dmg="${TEMP_ROOT}/Existing.dmg"
    print -n "existing image" > "${output_dmg}"

    # Act & Assert
    if zsh "${PACKAGER}" "${missing_app}" "${output_dmg}" >/dev/null 2>&1; then
        print -u2 "Expected packaging to fail when the source App is missing."
        return 1
    fi

    [[ "$(<"${output_dmg}")" == "existing image" ]]
}

function test_package_dmg_when_release_app_exists_then_creates_installable_image {
    # Arrange
    local output_dmg="${TEMP_ROOT}/Boundless Translator.dmg"
    local mount_point="${TEMP_ROOT}/Mounted"
    mkdir -p "${mount_point}"

    # Act
    zsh "${PACKAGER}" "${BUILD_APP}" "${output_dmg}"
    hdiutil attach \
        -readonly \
        -nobrowse \
        -mountpoint "${mount_point}" \
        "${output_dmg}" \
        >/dev/null
    active_mount_point="${mount_point}"

    # Assert
    hdiutil verify "${output_dmg}" >/dev/null
    codesign --verify --strict --verbose=2 "${output_dmg}"
    local signature_details
    signature_details="$(codesign --display --verbose=4 "${output_dmg}" 2>&1)"
    [[ "${signature_details}" == *"Authority=Developer ID Application: Chun Ting Kuo (3S9ZKKJ6PW)"* ]]
    [[ "${signature_details}" == *"TeamIdentifier=3S9ZKKJ6PW"* ]]
    [[ "${signature_details}" == *"Timestamp="* ]]
    [[ -d "${mount_point}/Boundless Translator.app" ]]
    [[ -L "${mount_point}/Applications" ]]
    [[ "$(readlink "${mount_point}/Applications")" == "/Applications" ]]
    [[ -f "${mount_point}/.DS_Store" ]]
    [[ -f "${mount_point}/.background/DMGBackground.png" ]]
    zsh "${VERIFIER}" "${mount_point}/Boundless Translator.app"

    hdiutil detach "${mount_point}" >/dev/null
    active_mount_point=""
}

test_package_dmg_when_paths_are_missing_then_fails_before_creating_image
test_package_dmg_when_source_app_is_missing_then_preserves_existing_image
test_package_dmg_when_release_app_exists_then_creates_installable_image

print "DMG packaging tests passed."
