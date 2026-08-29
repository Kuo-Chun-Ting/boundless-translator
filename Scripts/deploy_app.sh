#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h}"
readonly BUILD_APP="${PROJECT_ROOT}/Build/Boundless Translator.app"
readonly INSTALLED_APP="/Applications/Boundless Translator.app"
readonly APP_VERIFIER="${PROJECT_ROOT}/Scripts/verify_app.sh"
readonly DEPLOYMENT_RESTORER="${PROJECT_ROOT}/Scripts/restore_deployment.sh"
readonly PROCESS_NAME="BoundlessTranslator"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-deploy.XXXXXX)"
readonly STAGED_APP="${TEMP_ROOT}/Boundless Translator.app"
readonly BACKUP_APP="${TEMP_ROOT}/Previous Boundless Translator.app"
readonly FAILED_APP="${TEMP_ROOT}/Failed Boundless Translator.app"

previous_app_staged=false
new_app_installed=false
deployment_complete=false

function restore_if_needed {
    readonly exit_status="$?"
    local cleanup_allowed=true

    if [[ "${deployment_complete}" != true ]]; then
        if ! zsh "${DEPLOYMENT_RESTORER}" \
            "${INSTALLED_APP}" \
            "${BACKUP_APP}" \
            "${FAILED_APP}" \
            "${previous_app_staged}" \
            "${new_app_installed}"; then
            print -u2 "Deployment rollback failed. Recovery files preserved in ${TEMP_ROOT}."
            cleanup_allowed=false
        fi
    fi

    if [[ "${cleanup_allowed}" == true ]]; then
        rm -rf "${TEMP_ROOT}"
    fi

    return "${exit_status}"
}
trap restore_if_needed EXIT

function verify_app {
    local app_path="$1"

    zsh "${APP_VERIFIER}" "${app_path}"
}

function stop_running_app {
    if ! pgrep -x "${PROCESS_NAME}" >/dev/null; then
        return
    fi

    pkill -x "${PROCESS_NAME}"
    for _ in {1..50}; do
        if ! pgrep -x "${PROCESS_NAME}" >/dev/null; then
            return
        fi
        sleep 0.1
    done

    print -u2 "${PROCESS_NAME} did not stop."
    exit 1
}

function stage_new_app {
    ditto "${BUILD_APP}" "${STAGED_APP}"
    verify_app "${STAGED_APP}"
}

function install_staged_app {
    if [[ -e "${INSTALLED_APP}" ]]; then
        mv "${INSTALLED_APP}" "${BACKUP_APP}"
        previous_app_staged=true
    fi

    mv "${STAGED_APP}" "${INSTALLED_APP}"
    new_app_installed=true
}

function verify_installation {
    verify_app "${INSTALLED_APP}"
    cmp \
        "${BUILD_APP}/Contents/MacOS/BoundlessTranslator" \
        "${INSTALLED_APP}/Contents/MacOS/BoundlessTranslator"
    cmp \
        "${BUILD_APP}/Contents/Resources/AppIcon.icns" \
        "${INSTALLED_APP}/Contents/Resources/AppIcon.icns"
}

if [[ ! -d "${BUILD_APP}" ]]; then
    print -u2 "Missing build: ${BUILD_APP}"
    print -u2 "Run Scripts/build_app.sh first."
    exit 1
fi

verify_app "${BUILD_APP}"
stop_running_app
stage_new_app
install_staged_app
verify_installation
deployment_complete=true

print "Deployed and left closed: ${INSTALLED_APP}"
