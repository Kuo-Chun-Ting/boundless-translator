#!/bin/zsh

set -euo pipefail

if [[ "$#" -ne 5 ]]; then
    print -u2 "Usage: restore_deployment.sh <installed-app> <backup-app> <failed-app> <previous-staged> <new-installed>"
    exit 1
fi

readonly INSTALLED_APP="$1"
readonly BACKUP_APP="$2"
readonly FAILED_APP="$3"
readonly PREVIOUS_APP_STAGED="$4"
readonly NEW_APP_INSTALLED="$5"

if [[ "${NEW_APP_INSTALLED}" == true && -e "${INSTALLED_APP}" ]]; then
    mv "${INSTALLED_APP}" "${FAILED_APP}"
fi

if [[ "${PREVIOUS_APP_STAGED}" == true ]]; then
    if [[ ! -e "${BACKUP_APP}" ]]; then
        print -u2 "Missing deployment backup: ${BACKUP_APP}"
        exit 1
    fi

    mv "${BACKUP_APP}" "${INSTALLED_APP}"
fi
