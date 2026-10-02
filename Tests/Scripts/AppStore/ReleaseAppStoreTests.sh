#!/bin/zsh
set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-app-store-release-tests.XXXXXX)"
readonly CALL_LOG="${TEMP_ROOT}/calls.log"
trap 'rm -rf "${TEMP_ROOT}"' EXIT

function test_release_app_store_when_run_from_another_directory_then_archives_validates_and_uploads {
    # Arrange
    mkdir -p "${TEMP_ROOT}/Scripts/AppStore" "${TEMP_ROOT}/bin"
    cp "${PROJECT_ROOT}/Scripts/release_app_store.sh" "${TEMP_ROOT}/Scripts/"
    cp "${PROJECT_ROOT}/Scripts/AppStore/"*.sh "${TEMP_ROOT}/Scripts/AppStore/"
    cat > "${TEMP_ROOT}/bin/xcodebuild" <<'MOCK'
#!/bin/zsh
print -r -- "$PWD|$*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
MOCK
    chmod +x "${TEMP_ROOT}/bin/xcodebuild"

    # Act
    (cd /private/tmp && PATH="${TEMP_ROOT}/bin:${PATH}" \
        BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
        zsh "${TEMP_ROOT}/Scripts/release_app_store.sh")

    # Assert
    [[ "$(wc -l < "${CALL_LOG}" | tr -d ' ')" == 3 ]]
    [[ "$(sed -n '1p' "${CALL_LOG}")" == "${TEMP_ROOT}|archive "* ]]
    [[ "$(sed -n '2p' "${CALL_LOG}")" == "${TEMP_ROOT}|-exportArchive "*'-exportOptionsPlist Scripts/AppStore/ValidationOptions.plist '* ]]
    [[ "$(sed -n '3p' "${CALL_LOG}")" == "${TEMP_ROOT}|-exportArchive "*'-exportOptionsPlist Scripts/AppStore/UploadOptions.plist '* ]]
}

test_release_app_store_when_run_from_another_directory_then_archives_validates_and_uploads
print 'App Store release entry point tests passed.'
