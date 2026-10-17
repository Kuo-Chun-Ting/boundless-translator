#!/bin/zsh
set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-ocr-cache-reset-tests.XXXXXX)"
readonly MOCK_BIN="${TEMP_ROOT}/bin"
readonly CALL_LOG="${TEMP_ROOT}/calls.log"
trap '/bin/rm -rf "${TEMP_ROOT}"' EXIT
mkdir -p "${MOCK_BIN}"
for command_name in osascript rm; do
    cat > "${MOCK_BIN}/${command_name}" <<'MOCK'
#!/bin/zsh
print -r -- "${0:t} $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
MOCK
    chmod +x "${MOCK_BIN}/${command_name}"
done

function test_reset_ocr_cache_when_edition_is_selected_then_quits_app_and_only_removes_its_model_cache {
    local edition identifier script_path
    for edition in dmg app-store e2e; do
        # Arrange
        case "${edition}" in
            dmg)
                identifier='com.lillard.BoundlessTranslator.dmgtest'
                script_path="${PROJECT_ROOT}/Scripts/reset_ocr_cache_dmg.sh"
                ;;
            app-store)
                identifier='com.lillard.BoundlessTranslator'
                script_path="${PROJECT_ROOT}/Scripts/reset_ocr_cache_app_store.sh"
                ;;
            e2e)
                identifier='com.lillard.BoundlessTranslator.e2e'
                script_path="${PROJECT_ROOT}/Scripts/Shared/reset_ocr_cache.sh"
                ;;
        esac
        local cache_path="${HOME}/Library/Containers/${identifier}/Data/Library/Caches/${identifier}/com.apple.e5rt.e5bundlecache"
        local -a arguments=()
        [[ "${edition}" != e2e ]] || arguments=(e2e)
        : > "${CALL_LOG}"

        # Act
        PATH="${MOCK_BIN}:${PATH}" \
        BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
            zsh "${script_path}" "${arguments[@]}" >/dev/null

        # Assert
        [[ "$(<"${CALL_LOG}")" == "osascript - ${identifier}"$'\n'"rm -rf ${cache_path}" ]]
    done
}

test_reset_ocr_cache_when_edition_is_selected_then_quits_app_and_only_removes_its_model_cache
print 'OCR cache reset tests passed.'
