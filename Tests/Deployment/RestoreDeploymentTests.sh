#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"
readonly RESTORER="${PROJECT_ROOT}/Scripts/restore_deployment.sh"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-rollback-tests.XXXXXX)"

function clean_up {
    rm -rf "${TEMP_ROOT}"
}
trap clean_up EXIT

function test_restore_deployment_when_new_and_previous_apps_exist_then_restores_previous_app {
    # Arrange
    local case_root="${TEMP_ROOT}/Success"
    local installed_app="${case_root}/Applications/Boundless Translator.app"
    local backup_app="${case_root}/Previous Boundless Translator.app"
    local failed_app="${case_root}/Failed Boundless Translator.app"
    mkdir -p "${installed_app}" "${backup_app}"
    print "new" > "${installed_app}/version"
    print "previous" > "${backup_app}/version"

    # Act
    zsh "${RESTORER}" \
        "${installed_app}" \
        "${backup_app}" \
        "${failed_app}" \
        true \
        true

    # Assert
    [[ "$(<"${installed_app}/version")" == "previous" ]]
    [[ "$(<"${failed_app}/version")" == "new" ]]
    [[ ! -e "${backup_app}" ]]
}

function test_restore_deployment_when_failed_app_cannot_be_moved_then_preserves_backup {
    # Arrange
    local case_root="${TEMP_ROOT}/Failure"
    local installed_app="${case_root}/Applications/Boundless Translator.app"
    local backup_app="${case_root}/Previous Boundless Translator.app"
    local failed_app="${case_root}/Missing Parent/Failed Boundless Translator.app"
    mkdir -p "${installed_app}" "${backup_app}"
    print "new" > "${installed_app}/version"
    print "previous" > "${backup_app}/version"

    # Act & Assert
    if zsh "${RESTORER}" \
        "${installed_app}" \
        "${backup_app}" \
        "${failed_app}" \
        true \
        true \
        >/dev/null 2>&1; then
        print -u2 "Expected rollback to fail when the failed App cannot be staged."
        return 1
    fi

    [[ "$(<"${installed_app}/version")" == "new" ]]
    [[ "$(<"${backup_app}/version")" == "previous" ]]
}

test_restore_deployment_when_new_and_previous_apps_exist_then_restores_previous_app
test_restore_deployment_when_failed_app_cannot_be_moved_then_preserves_backup

print "Deployment rollback tests passed."
