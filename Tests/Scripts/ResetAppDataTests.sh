#!/bin/zsh
set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"
readonly RESETTER="${PROJECT_ROOT}/Scripts/reset_app_data.sh"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-data-reset-tests.XXXXXX)"
readonly MOCK_BIN="${TEMP_ROOT}/bin"
readonly CALL_LOG="${TEMP_ROOT}/calls.log"
trap '/bin/rm -rf "${TEMP_ROOT}"' EXIT
mkdir -p "${MOCK_BIN}"
for command_name in osascript defaults rm; do
    cat > "${MOCK_BIN}/${command_name}" <<'MOCK'
#!/bin/zsh
print -r -- "${0:t} $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
MOCK
    chmod +x "${MOCK_BIN}/${command_name}"
done

function run_resetter {
    PATH="${MOCK_BIN}:${PATH}" \
    BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
        zsh "${RESETTER}" "$@"
}

function test_reset_app_data_when_edition_is_selected_then_only_clears_its_container {
    local edition identifier
    for edition in dmg app-store e2e; do
        # Arrange
        case "${edition}" in
            dmg) identifier='com.lillard.BoundlessTranslator.dmgtest' ;;
            app-store) identifier='com.lillard.BoundlessTranslator' ;;
            e2e) identifier='com.lillard.BoundlessTranslator.e2e' ;;
        esac
        local data_path="${HOME}/Library/Containers/${identifier}/Data"
        : > "${CALL_LOG}"

        # Act
        run_resetter "${edition}" >/dev/null

        # Assert
        [[ "$(<"${CALL_LOG}")" == "osascript - ${identifier}"$'\n'"defaults delete ${data_path}/Library/Preferences/${identifier}.plist"$'\n'"rm -rf ${data_path}" ]]
    done
}


test_reset_app_data_when_edition_is_selected_then_only_clears_its_container
print 'App data reset tests passed.'
