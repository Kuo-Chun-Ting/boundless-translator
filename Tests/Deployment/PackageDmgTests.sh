#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"
readonly PACKAGER="${PROJECT_ROOT}/Scripts/package_dmg.sh"
readonly BUILD_APP="${PROJECT_ROOT}/Build/Boundless Translator.app"
readonly VERIFIER="${PROJECT_ROOT}/Scripts/verify_app.sh"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-dmg-tests.XXXXXX)"
active_mount_point=""

function clean_up {
    if [[ -n "${active_mount_point}" ]]; then
        hdiutil detach "${active_mount_point}" >/dev/null 2>&1 || true
    fi
    rm -rf "${TEMP_ROOT}"
}
trap clean_up EXIT

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
    [[ -d "${mount_point}/Boundless Translator.app" ]]
    [[ -L "${mount_point}/Applications" ]]
    [[ "$(readlink "${mount_point}/Applications")" == "/Applications" ]]
    zsh "${VERIFIER}" "${mount_point}/Boundless Translator.app"

    hdiutil detach "${mount_point}" >/dev/null
    active_mount_point=""
}

function test_package_dmg_when_release_app_exists_then_embeds_finder_layout {
    # Arrange
    local output_dmg="${TEMP_ROOT}/Styled Boundless Translator.dmg"
    local mount_point="${TEMP_ROOT}/Styled Mounted"
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
    [[ -f "${mount_point}/.DS_Store" ]]
    [[ -f "${mount_point}/.background/DMGBackground.png" ]]

    hdiutil detach "${mount_point}" >/dev/null
    active_mount_point=""
}

test_package_dmg_when_source_app_is_missing_then_preserves_existing_image
test_package_dmg_when_release_app_exists_then_creates_installable_image
test_package_dmg_when_release_app_exists_then_embeds_finder_layout

print "DMG packaging tests passed."
