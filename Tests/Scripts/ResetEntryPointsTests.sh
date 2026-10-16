#!/bin/zsh
set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-reset-entry-tests.XXXXXX)"
readonly CALL_LOG="${TEMP_ROOT}/calls.log"
trap 'rm -rf "${TEMP_ROOT}"' EXIT

function test_reset_entry_points_when_run_without_arguments_then_forward_edition_to_core {
    # Arrange
    mkdir -p "${TEMP_ROOT}/Reset"
    local core suffix edition
    for core in reset_app_data reset_permissions; do
        cat > "${TEMP_ROOT}/Reset/${core}.sh" <<'MOCK'
#!/bin/zsh
print -r -- "$*" > "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
MOCK
        chmod +x "${TEMP_ROOT}/Reset/${core}.sh"
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

function test_reset_all_when_edition_is_selected_then_resets_data_permissions_and_lookup_in_order {
    # Arrange
    local fixture_root="${TEMP_ROOT}/All Reset"
    mkdir -p "${fixture_root}"
    local script_name suffix expected_calls
    for script_name in reset_app_data_dmg reset_permissions_dmg reset_app_data_app_store reset_permissions_app_store reset_lookup_dictionary; do
        cat > "${fixture_root}/${script_name}.sh" <<'MOCK'
#!/bin/zsh
print -r -- "${0:t}" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
[[ $# == 0 ]]
MOCK
        chmod +x "${fixture_root}/${script_name}.sh"
    done
    for suffix in dmg app_store; do
        case "${suffix}" in
            dmg) expected_calls=$'reset_app_data_dmg.sh\nreset_permissions_dmg.sh\nreset_lookup_dictionary.sh' ;;
            app_store) expected_calls=$'reset_app_data_app_store.sh\nreset_permissions_app_store.sh\nreset_lookup_dictionary.sh' ;;
        esac
        cp "${PROJECT_ROOT}/Scripts/reset_all_${suffix}.sh" "${fixture_root}/"
        : > "${CALL_LOG}"

        # Act
        BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
            "${fixture_root}/reset_all_${suffix}.sh"

        # Assert
        [[ "$(<"${CALL_LOG}")" == "${expected_calls}" ]]
    done
}

test_reset_entry_points_when_run_without_arguments_then_forward_edition_to_core
test_reset_all_when_edition_is_selected_then_resets_data_permissions_and_lookup_in_order
print 'Reset entry point tests passed.'
