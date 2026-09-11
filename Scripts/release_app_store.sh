#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h}"
readonly BUILD_APP_EXECUTABLE="${BOUNDLESS_TRANSLATOR_BUILD_APP_EXECUTABLE:-${PROJECT_ROOT}/Scripts/Tools/build_app.sh}"
readonly PRODUCTBUILD_EXECUTABLE="${BOUNDLESS_TRANSLATOR_PRODUCTBUILD_EXECUTABLE:-productbuild}"
readonly PKGUTIL_EXECUTABLE="${BOUNDLESS_TRANSLATOR_PKGUTIL_EXECUTABLE:-pkgutil}"
readonly XCRUN_EXECUTABLE="${BOUNDLESS_TRANSLATOR_XCRUN_EXECUTABLE:-xcrun}"
readonly MV_EXECUTABLE="${BOUNDLESS_TRANSLATOR_MV_EXECUTABLE:-mv}"
readonly RELEASE_ROOT="${BOUNDLESS_TRANSLATOR_APP_STORE_RELEASE_ROOT:-${PROJECT_ROOT}/Build/AppStore}"

function fail {
    print -u2 "$1"
    exit 1
}

function print_usage {
    print -u2 'Usage: release_app_store.sh <version> <build-number> [--upload]'
    print -u2 'Example: Scripts/release_app_store.sh 1.0.0 12'
}

if [[ "$#" -lt 2 ]]; then
    print_usage
    exit 1
fi

readonly VERSION="$1"
readonly BUILD_NUMBER="$2"
shift 2

upload_requested=false
for argument in "$@"; do
    case "${argument}" in
        --upload)
            [[ "${upload_requested}" == false ]] || fail 'Duplicate --upload option.'
            upload_requested=true
            ;;
        *)
            print_usage
            exit 1
            ;;
    esac
done

[[ "${VERSION}" =~ '^[0-9]+\.[0-9]+(\.[0-9]+)?$' ]] || fail 'Version must use major.minor or major.minor.patch.'
[[ "${BUILD_NUMBER}" =~ '^[1-9][0-9]*$' ]] || fail 'Build number must be a positive integer.'

required_configuration=(
    BOUNDLESS_TRANSLATOR_APP_STORE_SIGNING_IDENTITY
    BOUNDLESS_TRANSLATOR_INSTALLER_SIGNING_IDENTITY
    BOUNDLESS_TRANSLATOR_APP_STORE_PROVISIONING_PROFILE
    BOUNDLESS_TRANSLATOR_APP_STORE_TEAM_ID
    BOUNDLESS_TRANSLATOR_SUBSCRIPTION_PRODUCT_ID
    BOUNDLESS_TRANSLATOR_PRIVACY_POLICY_URL
    BOUNDLESS_TRANSLATOR_APP_STORE_COPYRIGHT
)
for variable_name in "${required_configuration[@]}"; do
    [[ -n "${(P)variable_name:-}" ]] || fail "${variable_name} is required."
done

if [[ "${upload_requested}" == true ]]; then
    [[ -n "${BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_KEY_ID:-}" ]] || fail 'BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_KEY_ID is required for upload.'
    [[ -n "${BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_ISSUER_ID:-}" ]] || fail 'BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_ISSUER_ID is required for upload.'
fi

mkdir -p "${RELEASE_ROOT}"
readonly TEMP_ROOT="$(mktemp -d "${RELEASE_ROOT}/.boundless-translator-app-store-release.XXXXXX")"
readonly STAGED_BUILD_ROOT="${TEMP_ROOT}/staged"
readonly STAGED_APP_PATH="${STAGED_BUILD_ROOT}/Boundless Translator.app"
readonly PACKAGE_NAME="BoundlessTranslator-${VERSION}-${BUILD_NUMBER}.pkg"
readonly STAGED_PACKAGE_PATH="${TEMP_ROOT}/${PACKAGE_NAME}"
readonly APP_PATH="${RELEASE_ROOT}/Boundless Translator.app"
readonly PACKAGE_PATH="${RELEASE_ROOT}/${PACKAGE_NAME}"
readonly PREVIOUS_APP_PATH="${TEMP_ROOT}/previous.app"
readonly PREVIOUS_PACKAGE_PATH="${TEMP_ROOT}/previous.pkg"
readonly FAILED_APP_PATH="${TEMP_ROOT}/failed.app"
readonly FAILED_PACKAGE_PATH="${TEMP_ROOT}/failed.pkg"
readonly PUBLISH_LOCK="${RELEASE_ROOT}/.publish-lock"
publish_started=false
publish_succeeded=false
publish_lock_acquired=false
rollback_failed=false
previous_app_moved=false
previous_package_moved=false
new_app_published=false
new_package_published=false

function clean_up {
    if [[ "${publish_started}" == true && "${publish_succeeded}" != true ]]; then
        if [[ "${new_app_published}" == true && -e "${APP_PATH}" ]]; then
            if ! "${MV_EXECUTABLE}" "${APP_PATH}" "${FAILED_APP_PATH}" 2>/dev/null; then
                rollback_failed=true
            fi
        fi
        if [[ "${new_package_published}" == true && -e "${PACKAGE_PATH}" ]]; then
            if ! "${MV_EXECUTABLE}" "${PACKAGE_PATH}" "${FAILED_PACKAGE_PATH}" 2>/dev/null; then
                rollback_failed=true
            fi
        fi
        if [[ "${previous_app_moved}" == true && -e "${PREVIOUS_APP_PATH}" ]]; then
            if [[ -e "${APP_PATH}" ]]; then
                rollback_failed=true
            elif ! "${MV_EXECUTABLE}" "${PREVIOUS_APP_PATH}" "${APP_PATH}" 2>/dev/null; then
                rollback_failed=true
            fi
        fi
        if [[ "${previous_package_moved}" == true && -e "${PREVIOUS_PACKAGE_PATH}" ]]; then
            if [[ -e "${PACKAGE_PATH}" ]]; then
                rollback_failed=true
            elif ! "${MV_EXECUTABLE}" "${PREVIOUS_PACKAGE_PATH}" "${PACKAGE_PATH}" 2>/dev/null; then
                rollback_failed=true
            fi
        fi
    fi
    if [[ "${publish_lock_acquired}" == true ]]; then
        rmdir "${PUBLISH_LOCK}" 2>/dev/null || true
    fi
    if [[ "${rollback_failed}" == true ]]; then
        print -u2 "Rollback incomplete. Recovery artifacts preserved at: ${TEMP_ROOT}"
        return
    fi
    rm -rf "${TEMP_ROOT}"
}
trap clean_up EXIT

function validate_and_upload_package {
    if ! "${XCRUN_EXECUTABLE}" altool \
        --validate-app \
        -f "${PACKAGE_PATH}" \
        -t macos \
        --apiKey "${BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_KEY_ID}" \
        --apiIssuer "${BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_ISSUER_ID}"; then
        return 1
    fi
    if ! "${XCRUN_EXECUTABLE}" altool \
        --upload-app \
        -f "${PACKAGE_PATH}" \
        -t macos \
        --apiKey "${BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_KEY_ID}" \
        --apiIssuer "${BOUNDLESS_TRANSLATOR_APP_STORE_CONNECT_API_ISSUER_ID}"; then
        return 1
    fi
}

function publish_artifacts {
    if ! mkdir "${PUBLISH_LOCK}" 2>/dev/null; then
        fail 'Another App Store release is publishing Boundless Translator.'
    fi
    publish_lock_acquired=true
    publish_started=true

    if [[ -e "${APP_PATH}" ]]; then
        if ! "${MV_EXECUTABLE}" "${APP_PATH}" "${PREVIOUS_APP_PATH}"; then
            return 1
        fi
        previous_app_moved=true
    fi
    if [[ -e "${PACKAGE_PATH}" ]]; then
        if ! "${MV_EXECUTABLE}" "${PACKAGE_PATH}" "${PREVIOUS_PACKAGE_PATH}"; then
            return 1
        fi
        previous_package_moved=true
    fi

    if ! "${MV_EXECUTABLE}" "${STAGED_APP_PATH}" "${APP_PATH}"; then
        return 1
    fi
    new_app_published=true
    if ! "${MV_EXECUTABLE}" "${STAGED_PACKAGE_PATH}" "${PACKAGE_PATH}"; then
        return 1
    fi
    new_package_published=true
    publish_succeeded=true
}

BOUNDLESS_TRANSLATOR_APP_STORE_BUILD_ROOT="${STAGED_BUILD_ROOT}" \
BOUNDLESS_TRANSLATOR_APP_STORE_VERSION="${VERSION}" \
BOUNDLESS_TRANSLATOR_APP_STORE_BUILD_NUMBER="${BUILD_NUMBER}" \
    "${BUILD_APP_EXECUTABLE}" --app-store

"${PRODUCTBUILD_EXECUTABLE}" \
    --sign "${BOUNDLESS_TRANSLATOR_INSTALLER_SIGNING_IDENTITY}" \
    --component "${STAGED_APP_PATH}" \
    /Applications \
    "${STAGED_PACKAGE_PATH}"
"${PKGUTIL_EXECUTABLE}" --check-signature "${STAGED_PACKAGE_PATH}"

if ! publish_artifacts; then
    exit 1
fi

if [[ "${upload_requested}" == true ]]; then
    if ! validate_and_upload_package; then
        print -u2 "App Store upload failed. Validated local artifacts remain at: ${APP_PATH} and ${PACKAGE_PATH}"
        exit 1
    fi
fi

if [[ "${upload_requested}" == true ]]; then
    print "App Store upload completed: ${PACKAGE_PATH}"
else
    print "App Store package ready: ${PACKAGE_PATH}"
fi
