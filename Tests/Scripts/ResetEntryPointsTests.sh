#!/bin/zsh
set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-reset-entry-tests.XXXXXX)"
readonly CALL_LOG="${TEMP_ROOT}/calls.log"
trap 'rm -rf "${TEMP_ROOT}"' EXIT

function test_reset_entry_points_when_run_without_arguments_then_forward_edition_to_core {
    # Arrange
    local core suffix edition
    for core in reset_app_data reset_permissions; do
        cat > "${TEMP_ROOT}/${core}.sh" <<'MOCK'
#!/bin/zsh
print -r -- "$*" > "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
MOCK
        chmod +x "${TEMP_ROOT}/${core}.sh"
        for suffix in dmg app_store; do
            case "${suffix}" in
                dmg) edition=dmg ;;
                app_store) edition=app-store ;;
            esac
            cp "${PROJECT_ROOT}/Scripts/${core}_${suffix}.sh" "${TEMP_ROOT}/"

            # Act
            BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
                "${TEMP_ROOT}/${core}_${suffix}.sh"

            # Assert
            [[ "$(<"${CALL_LOG}")" == "${edition}" ]]
        done
    done
}

test_reset_entry_points_when_run_without_arguments_then_forward_edition_to_core
print 'Reset entry point tests passed.'
