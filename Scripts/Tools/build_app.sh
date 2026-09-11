#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"
if [[ "$#" -gt 1 ]] || [[ "$#" -eq 1 && "$1" != --app-store ]]; then
    print -u2 'Usage: build_app.sh [--app-store]'
    exit 1
fi
readonly BUILD_MODE="${1:-developer-id}"
if [[ "${BUILD_MODE}" == --app-store ]]; then
    readonly BUILD_ROOT="${BOUNDLESS_TRANSLATOR_APP_STORE_BUILD_ROOT:-${PROJECT_ROOT}/Build/AppStore}"
else
    readonly BUILD_ROOT="${BOUNDLESS_TRANSLATOR_BUILD_ROOT:-${PROJECT_ROOT}/Build}"
fi
readonly APP_PATH="${BUILD_ROOT}/Boundless Translator.app"
readonly SOURCE_INFO_PLIST="${BOUNDLESS_TRANSLATOR_BUILD_INFO_PLIST:-${PROJECT_ROOT}/Resources/Info.plist}"
readonly DEVELOPER_PATH="/Applications/Xcode.app/Contents/Developer"
source "${PROJECT_ROOT}/Scripts/Tools/code_signing.conf"
readonly SIGNING_IDENTITY="${BOUNDLESS_TRANSLATOR_SIGNING_IDENTITY:-${DEFAULT_SIGNING_IDENTITY}}"
readonly SECURITY_EXECUTABLE="${BOUNDLESS_TRANSLATOR_SECURITY_EXECUTABLE:-security}"
readonly OPENSSL_EXECUTABLE="${BOUNDLESS_TRANSLATOR_OPENSSL_EXECUTABLE:-openssl}"
readonly MV_EXECUTABLE="${BOUNDLESS_TRANSLATOR_MV_EXECUTABLE:-mv}"
readonly APP_STORE_CATEGORY='public.app-category.productivity'
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-build.XXXXXX)"
readonly SCRATCH_PATH="${TEMP_ROOT}/spm"
readonly STAGED_APP_PATH="${TEMP_ROOT}/Boundless Translator.app"
readonly CONTENTS_PATH="${STAGED_APP_PATH}/Contents"
readonly MACOS_PATH="${CONTENTS_PATH}/MacOS"
readonly RESOURCES_PATH="${CONTENTS_PATH}/Resources"
readonly APP_STORE_ENTITLEMENTS_PATH="${TEMP_ROOT}/AppStore.entitlements"
readonly PREVIOUS_APP_PATH="${TEMP_ROOT}/Previous Boundless Translator.app"
readonly PUBLISH_LOCK="${BUILD_ROOT}/.publish-lock"
publish_lock_acquired=false
rollback_failed=false

function clean_up {
    if [[ "${publish_lock_acquired}" == true ]]; then
        rmdir "${PUBLISH_LOCK}" 2>/dev/null || true
    fi
    if [[ "${rollback_failed}" == true ]]; then
        print -u2 "Publish rollback incomplete. Recovery artifacts preserved at: ${TEMP_ROOT}"
        return
    fi
    rm -rf "${TEMP_ROOT}"
}
trap clean_up EXIT

function fail {
    print -u2 "$1"
    exit 1
}

function require_app_store_configuration {
    [[ -n "${BOUNDLESS_TRANSLATOR_APP_STORE_SIGNING_IDENTITY:-}" ]] || fail 'BOUNDLESS_TRANSLATOR_APP_STORE_SIGNING_IDENTITY is required.'
    [[ -n "${BOUNDLESS_TRANSLATOR_INSTALLER_SIGNING_IDENTITY:-}" ]] || fail 'BOUNDLESS_TRANSLATOR_INSTALLER_SIGNING_IDENTITY is required.'
    [[ -n "${BOUNDLESS_TRANSLATOR_APP_STORE_PROVISIONING_PROFILE:-}" ]] || fail 'BOUNDLESS_TRANSLATOR_APP_STORE_PROVISIONING_PROFILE is required.'
    [[ -n "${BOUNDLESS_TRANSLATOR_APP_STORE_TEAM_ID:-}" ]] || fail 'BOUNDLESS_TRANSLATOR_APP_STORE_TEAM_ID is required.'
    [[ -n "${BOUNDLESS_TRANSLATOR_SUBSCRIPTION_PRODUCT_ID:-}" ]] || fail 'BOUNDLESS_TRANSLATOR_SUBSCRIPTION_PRODUCT_ID is required.'
    [[ -n "${BOUNDLESS_TRANSLATOR_PRIVACY_POLICY_URL:-}" ]] || fail 'BOUNDLESS_TRANSLATOR_PRIVACY_POLICY_URL is required.'
    [[ "${BOUNDLESS_TRANSLATOR_APP_STORE_COPYRIGHT:-}" == *[![:space:]]* ]] || fail 'BOUNDLESS_TRANSLATOR_APP_STORE_COPYRIGHT is required.'
    [[ "${BOUNDLESS_TRANSLATOR_APP_STORE_VERSION:-}" =~ '^[0-9]+\.[0-9]+(\.[0-9]+)?$' ]] || fail 'App Store version must use major.minor or major.minor.patch.'
    [[ "${BOUNDLESS_TRANSLATOR_APP_STORE_BUILD_NUMBER:-}" =~ '^[1-9][0-9]*$' ]] || fail 'App Store build number must be a positive integer.'
    [[ "${BOUNDLESS_TRANSLATOR_SUBSCRIPTION_PRODUCT_ID}" != *[[:space:]]* ]] || fail 'Subscription product ID must not contain whitespace.'
    validate_privacy_policy_url "${BOUNDLESS_TRANSLATOR_PRIVACY_POLICY_URL}"
    [[ -f "${BOUNDLESS_TRANSLATOR_APP_STORE_PROVISIONING_PROFILE}" ]] || fail 'App Store provisioning profile does not exist.'
}

function validate_privacy_policy_url {
    local url="$1"
    [[ "${url}" =~ '^https://[^[:space:]/?#]+([/?#][^[:space:]]*)?$' ]] || fail 'Privacy policy URL must use HTTPS and include a host.'

    local authority="${url#https://}"
    authority="${authority%%[/?#]*}"
    [[ "${authority}" != *@* ]] || fail 'Privacy policy URL must not contain user credentials.'
    [[ "${authority}" != :* ]] || fail 'Privacy policy URL must include a host.'
}

function validate_signing_identity {
    local identity="$1"
    local identity_kind="$2"
    local identity_output

    if [[ "${identity_kind}" == app ]]; then
        if [[ "${identity}" != 'Apple Distribution: '* && "${identity}" != '3rd Party Mac Developer Application: '* ]]; then
            fail 'App Store app signing identity must be an Apple Distribution or Mac App Distribution identity.'
        fi
        identity_output="$("${SECURITY_EXECUTABLE}" find-identity -v -p codesigning)"
    else
        if [[ "${identity}" != 'Mac Installer Distribution: '* && "${identity}" != '3rd Party Mac Developer Installer: '* ]]; then
            fail 'App Store installer signing identity must be a Mac Installer Distribution identity.'
        fi
        identity_output="$("${SECURITY_EXECUTABLE}" find-identity -v)"
    fi
    [[ "${identity_output}" == *"\"${identity}\""* ]] || fail "App Store ${identity_kind} signing identity is unavailable or expired."

    local certificate
    certificate="$("${SECURITY_EXECUTABLE}" find-certificate -c "${identity}" -p)" || fail "Could not read App Store ${identity_kind} signing certificate."
    print -r -- "${certificate}" | "${OPENSSL_EXECUTABLE}" x509 -checkend 0 -noout >/dev/null || fail "App Store ${identity_kind} signing certificate is expired."

    local subject
    subject="$(print -r -- "${certificate}" | "${OPENSSL_EXECUTABLE}" x509 -subject -noout)" || fail "Could not inspect App Store ${identity_kind} signing certificate."
    if [[ "${subject}" != *"OU = ${BOUNDLESS_TRANSLATOR_APP_STORE_TEAM_ID}"* && "${subject}" != *"OU=${BOUNDLESS_TRANSLATOR_APP_STORE_TEAM_ID}"* ]]; then
        fail "App Store ${identity_kind} signing certificate does not match the configured team."
    fi
}

function validate_distribution_profile {
    local bundle_identifier="$1"
    local decoded_profile="${TEMP_ROOT}/provisioning-profile.plist"
    "${SECURITY_EXECUTABLE}" cms -D -i "${BOUNDLESS_TRANSLATOR_APP_STORE_PROVISIONING_PROFILE}" > "${decoded_profile}" || fail 'Could not decode App Store provisioning profile.'
    plutil -lint "${decoded_profile}" >/dev/null || fail 'App Store provisioning profile is not a valid plist.'

    local profile_team
    local entitlement_team
    local application_identifier
    local expiration_date
    profile_team="$(/usr/libexec/PlistBuddy -c 'Print :TeamIdentifier:0' "${decoded_profile}")" || fail 'App Store provisioning profile has no team identifier.'
    entitlement_team="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:com.apple.developer.team-identifier' "${decoded_profile}")" || fail 'App Store provisioning profile has no entitlement team identifier.'
    application_identifier="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:com.apple.application-identifier' "${decoded_profile}")" || fail 'App Store provisioning profile has no application identifier.'
    expiration_date="$(plutil -extract ExpirationDate raw "${decoded_profile}")" || fail 'App Store provisioning profile has no expiration date.'

    [[ "${profile_team}" == "${BOUNDLESS_TRANSLATOR_APP_STORE_TEAM_ID}" ]] || fail 'App Store provisioning profile does not match the configured team.'
    [[ "${entitlement_team}" == "${profile_team}" ]] || fail 'App Store provisioning profile team identifiers do not match.'
    [[ "${application_identifier}" == "${profile_team}.${bundle_identifier}" ]] || fail 'App Store provisioning profile does not match the app bundle identifier.'
    [[ "${expiration_date}" =~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}T' && "${expiration_date}" > "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" ]] || fail 'App Store provisioning profile is expired or has an invalid expiration date.'
    local debugging_entitlement
    debugging_entitlement="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:get-task-allow' "${decoded_profile}" 2>/dev/null || true)"
    [[ "${debugging_entitlement}" != true ]] || fail 'App Store provisioning profile allows debugging.'
    debugging_entitlement="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:com.apple.security.get-task-allow' "${decoded_profile}" 2>/dev/null || true)"
    [[ "${debugging_entitlement}" != true ]] || fail 'App Store provisioning profile allows macOS task debugging.'
    if plutil -extract ProvisionedDevices raw "${decoded_profile}" >/dev/null 2>&1; then
        fail 'App Store provisioning profile is device-scoped, not a distribution profile.'
    fi
    if [[ "$(plutil -extract ProvisionsAllDevices raw "${decoded_profile}" 2>/dev/null || true)" == true ]]; then
        fail 'App Store provisioning profile is an all-device profile, not an App Store distribution profile.'
    fi
}

function create_app_store_entitlements {
    local bundle_identifier="$1"
    cp "${PROJECT_ROOT}/Resources/Sandbox.entitlements" "${APP_STORE_ENTITLEMENTS_PATH}"
    /usr/libexec/PlistBuddy -c "Add :com.apple.application-identifier string ${BOUNDLESS_TRANSLATOR_APP_STORE_TEAM_ID}.${bundle_identifier}" "${APP_STORE_ENTITLEMENTS_PATH}"
    /usr/libexec/PlistBuddy -c "Add :com.apple.developer.team-identifier string ${BOUNDLESS_TRANSLATOR_APP_STORE_TEAM_ID}" "${APP_STORE_ENTITLEMENTS_PATH}"
    plutil -lint "${APP_STORE_ENTITLEMENTS_PATH}" >/dev/null || fail 'Generated App Store entitlements are invalid.'
}

function validate_profile_signing_certificate {
    local certificate
    certificate="$("${SECURITY_EXECUTABLE}" find-certificate -c "${BOUNDLESS_TRANSLATOR_APP_STORE_SIGNING_IDENTITY}" -p)" || fail 'Could not read the App Store app signing certificate.'

    local actual_digest
    actual_digest="$(print -r -- "${certificate}" | "${OPENSSL_EXECUTABLE}" x509 -outform DER | /usr/bin/shasum -a 256)" || fail 'Could not fingerprint the App Store app signing certificate.'
    actual_digest="${actual_digest%% *}"

    local certificate_count
    certificate_count="$(plutil -extract DeveloperCertificates raw -expect array "${TEMP_ROOT}/provisioning-profile.plist")" || fail 'App Store provisioning profile has no signing certificates.'
    [[ "${certificate_count}" =~ '^[1-9][0-9]*$' ]] || fail 'App Store provisioning profile has no signing certificates.'

    local index
    local profile_digest
    for (( index = 0; index < certificate_count; index++ )); do
        profile_digest="$(plutil -extract "DeveloperCertificates.${index}" raw "${TEMP_ROOT}/provisioning-profile.plist" | /usr/bin/base64 -D | /usr/bin/shasum -a 256)" || fail 'Could not fingerprint a provisioning profile certificate.'
        profile_digest="${profile_digest%% *}"
        if [[ "${profile_digest}" == "${actual_digest}" ]]; then
            return
        fi
    done
    fail 'App Store app signing certificate is not authorized by the provisioning profile.'
}

if [[ "${BUILD_MODE}" == --app-store ]]; then
    require_app_store_configuration
    readonly SOURCE_BUNDLE_IDENTIFIER="$(plutil -extract CFBundleIdentifier raw "${SOURCE_INFO_PLIST}")"
    validate_signing_identity "${BOUNDLESS_TRANSLATOR_APP_STORE_SIGNING_IDENTITY}" app
    validate_signing_identity "${BOUNDLESS_TRANSLATOR_INSTALLER_SIGNING_IDENTITY}" installer
    validate_distribution_profile "${SOURCE_BUNDLE_IDENTIFIER}"
    validate_profile_signing_certificate
    create_app_store_entitlements "${SOURCE_BUNDLE_IDENTIFIER}"
fi

mkdir -p "${MACOS_PATH}" "${RESOURCES_PATH}"

swift_arguments=(
    build
    --configuration release
    --disable-sandbox
    --package-path "${PROJECT_ROOT}"
    --scratch-path "${SCRATCH_PATH}"
    --cache-path "${TEMP_ROOT}/cache"
    --config-path "${TEMP_ROOT}/config"
    --security-path "${TEMP_ROOT}/security"
)
if [[ "${BUILD_MODE}" == --app-store ]]; then
    swift_arguments+=( --arch arm64 -Xswiftc -D -Xswiftc SUBSCRIPTION_REQUIRED )
fi

CLANG_MODULE_CACHE_PATH="${TEMP_ROOT}/clang-cache" \
SWIFTPM_MODULECACHE_OVERRIDE="${TEMP_ROOT}/module-cache" \
DEVELOPER_DIR="${DEVELOPER_PATH}" \
swift "${swift_arguments[@]}"

cp "${SCRATCH_PATH}/release/BoundlessTranslator" "${MACOS_PATH}/BoundlessTranslator"
cp -R \
    "${SCRATCH_PATH}/release/BoundlessTranslator_BoundlessTranslator.bundle/"*.lproj \
    "${RESOURCES_PATH}/"
cp "${SOURCE_INFO_PLIST}" "${CONTENTS_PATH}/Info.plist"
cp "${PROJECT_ROOT}/Resources/AppIcon.icns" "${RESOURCES_PATH}/AppIcon.icns"
cp "${PROJECT_ROOT}/Resources/PrivacyInfo.xcprivacy" "${RESOURCES_PATH}/PrivacyInfo.xcprivacy"
plutil -lint "${RESOURCES_PATH}/PrivacyInfo.xcprivacy"

signing_arguments=(--entitlements "${PROJECT_ROOT}/Resources/Sandbox.entitlements")
if [[ "${BUILD_MODE}" == --app-store ]]; then
    plutil -replace CFBundleShortVersionString -string "${BOUNDLESS_TRANSLATOR_APP_STORE_VERSION}" "${CONTENTS_PATH}/Info.plist"
    plutil -replace CFBundleVersion -string "${BOUNDLESS_TRANSLATOR_APP_STORE_BUILD_NUMBER}" "${CONTENTS_PATH}/Info.plist"
    plutil -insert BoundlessSubscriptionProductID -string "${BOUNDLESS_TRANSLATOR_SUBSCRIPTION_PRODUCT_ID}" "${CONTENTS_PATH}/Info.plist"
    plutil -insert BoundlessPrivacyPolicyURL -string "${BOUNDLESS_TRANSLATOR_PRIVACY_POLICY_URL}" "${CONTENTS_PATH}/Info.plist"
    plutil -insert NSHumanReadableCopyright -string "${BOUNDLESS_TRANSLATOR_APP_STORE_COPYRIGHT}" "${CONTENTS_PATH}/Info.plist"
    plutil -insert LSApplicationCategoryType -string "${APP_STORE_CATEGORY}" "${CONTENTS_PATH}/Info.plist"
    cp "${BOUNDLESS_TRANSLATOR_APP_STORE_PROVISIONING_PROFILE}" "${CONTENTS_PATH}/embedded.provisionprofile"
    signing_arguments=(--entitlements "${APP_STORE_ENTITLEMENTS_PATH}")
fi

plutil -lint "${CONTENTS_PATH}/Info.plist"
if [[ "${BUILD_MODE}" == --app-store ]]; then
    codesign \
        --force \
        --timestamp \
        --sign "${BOUNDLESS_TRANSLATOR_APP_STORE_SIGNING_IDENTITY}" \
        "${signing_arguments[@]}" \
        "${STAGED_APP_PATH}"
else
    codesign \
        --force \
        --options runtime \
        --timestamp \
        --sign "${SIGNING_IDENTITY}" \
        "${signing_arguments[@]}" \
        "${STAGED_APP_PATH}"
fi
codesign --verify --strict --verbose=2 "${STAGED_APP_PATH}"

mkdir -p "${BUILD_ROOT}"
if ! mkdir "${PUBLISH_LOCK}" 2>/dev/null; then
    print -u2 "Another build is publishing Boundless Translator."
    exit 1
fi
publish_lock_acquired=true

if [[ -e "${APP_PATH}" ]]; then
    "${MV_EXECUTABLE}" "${APP_PATH}" "${PREVIOUS_APP_PATH}"
fi

if ! "${MV_EXECUTABLE}" "${STAGED_APP_PATH}" "${APP_PATH}"; then
    if [[ -e "${PREVIOUS_APP_PATH}" ]]; then
        if ! "${MV_EXECUTABLE}" "${PREVIOUS_APP_PATH}" "${APP_PATH}"; then
            rollback_failed=true
        fi
    fi
    exit 1
fi

rm -rf "${PREVIOUS_APP_PATH}"

print "Built ${APP_PATH}"
