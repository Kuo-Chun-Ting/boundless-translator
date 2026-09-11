#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-app-store-build-tests.XXXXXX)"
readonly FIXTURE="${TEMP_ROOT}/project"
readonly MOCK_BIN="${TEMP_ROOT}/bin"
readonly PROFILE_PLIST="${TEMP_ROOT}/profile.plist"
readonly PROFILE_PATH="${TEMP_ROOT}/distribution.provisionprofile"
readonly TEAM_ID="ABCDE12345"
readonly BUNDLE_ID="com.lillard.BoundlessTranslator"
readonly APP_PATH="${FIXTURE}/Build/AppStore/Boundless Translator.app"

function clean_up {
    rm -rf "${TEMP_ROOT}"
}
trap clean_up EXIT

function create_fixture {
    mkdir -p "${FIXTURE}/Scripts/Tools" "${FIXTURE}/Resources" "${MOCK_BIN}"
    cp "${PROJECT_ROOT}/Scripts/Tools/build_app.sh" "${FIXTURE}/Scripts/Tools/"
    cp "${PROJECT_ROOT}/Scripts/Tools/code_signing.conf" "${FIXTURE}/Scripts/Tools/"
    cp "${PROJECT_ROOT}/Resources/Info.plist" "${FIXTURE}/Resources/"
    cp "${PROJECT_ROOT}/Resources/PrivacyInfo.xcprivacy" "${FIXTURE}/Resources/"
    cp "${PROJECT_ROOT}/Resources/Sandbox.entitlements" "${FIXTURE}/Resources/"
    touch "${FIXTURE}/Resources/AppIcon.icns"
}

function create_distribution_profile {
    local application_identifier="${1:-${TEAM_ID}.${BUNDLE_ID}}"
    local expiry="${2:-2099-12-31T23:59:59Z}"
    local allows_debugging="${3:-false}"
    local certificate_data="${4:-dGVzdCBjZXJ0aWZpY2F0ZSBkZXI=}"

    plutil -create xml1 "${PROFILE_PLIST}"
    plutil -insert TeamIdentifier -json "[\"${TEAM_ID}\"]" "${PROFILE_PLIST}"
    plutil -insert ExpirationDate -date "${expiry}" "${PROFILE_PLIST}"
    plutil -insert DeveloperCertificates -xml "<array><data>${certificate_data}</data></array>" "${PROFILE_PLIST}"
    /usr/libexec/PlistBuddy -c 'Add :Entitlements dict' "${PROFILE_PLIST}"
    /usr/libexec/PlistBuddy -c "Add :Entitlements:com.apple.application-identifier string ${application_identifier}" "${PROFILE_PLIST}"
    /usr/libexec/PlistBuddy -c "Add :Entitlements:com.apple.developer.team-identifier string ${TEAM_ID}" "${PROFILE_PLIST}"
    if [[ "${allows_debugging}" != absent ]]; then
        /usr/libexec/PlistBuddy -c "Add :Entitlements:get-task-allow bool ${allows_debugging}" "${PROFILE_PLIST}"
    fi
    cp "${PROFILE_PLIST}" "${PROFILE_PATH}"
}

function create_platform_stubs {
    cat > "${MOCK_BIN}/swift" <<'EOF'
#!/bin/zsh
set -eu
print -r -- "$*" > "${TEST_SWIFT_LOG}"
while [[ "$#" -gt 0 ]]; do
    if [[ "$1" == --scratch-path ]]; then
        scratch_path="$2"
        break
    fi
    shift
done
mkdir -p "${scratch_path}/release/BoundlessTranslator_BoundlessTranslator.bundle/en.lproj"
print 'store executable' > "${scratch_path}/release/BoundlessTranslator"
EOF

    cat > "${MOCK_BIN}/security" <<'EOF'
#!/bin/zsh
set -eu
if [[ "$1" == cms ]]; then
    cat "${TEST_PROFILE_PLIST}"
elif [[ "$1" == find-identity ]]; then
    print -r -- "1) APPHASH \"${BOUNDLESS_TRANSLATOR_APP_STORE_SIGNING_IDENTITY}\""
    print -r -- "2) PKGHASH \"${BOUNDLESS_TRANSLATOR_INSTALLER_SIGNING_IDENTITY}\""
    print '2 valid identities found'
elif [[ "$1" == find-certificate ]]; then
    print 'test certificate'
else
    exit 2
fi
EOF

    cat > "${MOCK_BIN}/openssl" <<'EOF'
#!/bin/zsh
set -eu
cat >/dev/null
if [[ "$*" == *-checkend* ]]; then
    [[ "${TEST_CERTIFICATE_EXPIRED:-false}" != true ]]
elif [[ "$*" == *'-outform DER'* ]]; then
    print -n 'test certificate der'
else
    print -r -- "subject=CN = Test, OU = ${TEST_CERTIFICATE_TEAM_ID}"
fi
EOF

    cat > "${MOCK_BIN}/codesign" <<'EOF'
#!/bin/zsh
set -eu
print -r -- "$*" >> "${TEST_SIGNING_LOG}"
while [[ "$#" -gt 0 ]]; do
    if [[ "$1" == --entitlements ]]; then
        [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.app-sandbox' "$2")" == true ]]
        [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.network.client' "$2")" == true ]]
        [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.application-identifier' "$2")" == "${BOUNDLESS_TRANSLATOR_APP_STORE_TEAM_ID}.${TEST_BUNDLE_ID}" ]]
        [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.developer.team-identifier' "$2")" == "${BOUNDLESS_TRANSLATOR_APP_STORE_TEAM_ID}" ]]
        break
    fi
    shift
done
EOF
    chmod +x "${MOCK_BIN}/swift" "${MOCK_BIN}/security" "${MOCK_BIN}/openssl" "${MOCK_BIN}/codesign"
}

function run_builder {
    local version="${TEST_APP_STORE_VERSION:-1.2.3}"
    local privacy_policy_url="${BOUNDLESS_TRANSLATOR_PRIVACY_POLICY_URL:-https://example.com/privacy}"
    local copyright="${BOUNDLESS_TRANSLATOR_APP_STORE_COPYRIGHT-© 2026 Example Company}"
    local app_signing_identity="${BOUNDLESS_TRANSLATOR_APP_STORE_SIGNING_IDENTITY:-Apple Distribution: Example (${TEAM_ID})}"
    local installer_signing_identity="${BOUNDLESS_TRANSLATOR_INSTALLER_SIGNING_IDENTITY:-Mac Installer Distribution: Example (${TEAM_ID})}"
    PATH="${MOCK_BIN}:${PATH}" \
    TEST_PROFILE_PLIST="${PROFILE_PLIST}" \
    TEST_CERTIFICATE_TEAM_ID="${TEAM_ID}" \
    TEST_BUNDLE_ID="${BUNDLE_ID}" \
    TEST_SWIFT_LOG="${TEMP_ROOT}/swift.log" \
    TEST_SIGNING_LOG="${TEMP_ROOT}/signing.log" \
    BOUNDLESS_TRANSLATOR_APP_STORE_SIGNING_IDENTITY="${app_signing_identity}" \
    BOUNDLESS_TRANSLATOR_INSTALLER_SIGNING_IDENTITY="${installer_signing_identity}" \
    BOUNDLESS_TRANSLATOR_APP_STORE_PROVISIONING_PROFILE="${PROFILE_PATH}" \
    BOUNDLESS_TRANSLATOR_APP_STORE_TEAM_ID="${TEAM_ID}" \
    BOUNDLESS_TRANSLATOR_APP_STORE_VERSION="${version}" \
    BOUNDLESS_TRANSLATOR_APP_STORE_BUILD_NUMBER="42" \
    BOUNDLESS_TRANSLATOR_SUBSCRIPTION_PRODUCT_ID="com.lillard.boundless.annual" \
    BOUNDLESS_TRANSLATOR_PRIVACY_POLICY_URL="${privacy_policy_url}" \
    BOUNDLESS_TRANSLATOR_APP_STORE_COPYRIGHT="${copyright}" \
        zsh "${FIXTURE}/Scripts/Tools/build_app.sh" --app-store
}

function test_build_app_when_version_has_two_components_then_uses_it {
    # Arrange
    create_distribution_profile
    : > "${TEMP_ROOT}/signing.log"

    # Act
    TEST_APP_STORE_VERSION='1.0' run_builder

    # Assert
    [[ "$(plutil -extract CFBundleShortVersionString raw "${APP_PATH}/Contents/Info.plist")" == 1.0 ]]
}

function test_build_app_when_app_store_requested_then_builds_store_variant_from_shared_sources {
    # Arrange
    create_distribution_profile
    : > "${TEMP_ROOT}/signing.log"
    : > "${TEMP_ROOT}/swift.log"
    local original_info="$(shasum "${FIXTURE}/Resources/Info.plist")"

    # Act
    run_builder

    # Assert
    [[ -f "${APP_PATH}/Contents/MacOS/BoundlessTranslator" ]]
    [[ -f "${APP_PATH}/Contents/embedded.provisionprofile" ]]
    cmp "${PROFILE_PATH}" "${APP_PATH}/Contents/embedded.provisionprofile"
    [[ "$(plutil -extract CFBundleShortVersionString raw "${APP_PATH}/Contents/Info.plist")" == 1.2.3 ]]
    [[ "$(plutil -extract CFBundleVersion raw "${APP_PATH}/Contents/Info.plist")" == 42 ]]
    [[ "$(plutil -extract BoundlessSubscriptionProductID raw "${APP_PATH}/Contents/Info.plist")" == com.lillard.boundless.annual ]]
    [[ "$(plutil -extract BoundlessPrivacyPolicyURL raw "${APP_PATH}/Contents/Info.plist")" == https://example.com/privacy ]]
    [[ "$(plutil -extract NSHumanReadableCopyright raw "${APP_PATH}/Contents/Info.plist")" == '© 2026 Example Company' ]]
    [[ "$(plutil -extract LSApplicationCategoryType raw "${APP_PATH}/Contents/Info.plist")" == public.app-category.productivity ]]
    [[ "$(<"${TEMP_ROOT}/swift.log")" == *'-Xswiftc -D -Xswiftc SUBSCRIPTION_REQUIRED'* ]]
    [[ "$(<"${TEMP_ROOT}/swift.log")" == *'--arch arm64'* ]]
    [[ "$(<"${TEMP_ROOT}/signing.log")" == *'--entitlements '*'/AppStore.entitlements'* ]]
    if /usr/libexec/PlistBuddy -c 'Print :com.apple.application-identifier' "${FIXTURE}/Resources/Sandbox.entitlements" >/dev/null 2>&1; then
        print -u2 'Shared Sandbox entitlements must not contain a fixed application identifier.'
        return 1
    fi
    [[ "$(shasum "${FIXTURE}/Resources/Info.plist")" == "${original_info}" ]]
}

function test_build_app_when_profile_does_not_match_bundle_then_preserves_existing_store_app {
    # Arrange
    create_distribution_profile "${TEAM_ID}.com.example.WrongApp"
    mkdir -p "${APP_PATH}"
    print 'existing store app' > "${APP_PATH}/marker"
    : > "${TEMP_ROOT}/signing.log"

    # Act & Assert
    if run_builder > "${TEMP_ROOT}/invalid-profile.log" 2>&1; then
        print -u2 'Expected a mismatched distribution profile to fail.'
        return 1
    fi
    [[ "$(<"${APP_PATH}/marker")" == 'existing store app' ]]
    [[ ! -s "${TEMP_ROOT}/signing.log" ]]
}

function test_build_app_when_privacy_url_is_not_https_then_stops_before_external_tools {
    # Arrange
    create_distribution_profile
    : > "${TEMP_ROOT}/swift.log"

    # Act & Assert
    if BOUNDLESS_TRANSLATOR_PRIVACY_POLICY_URL='http://example.com/privacy' run_builder > "${TEMP_ROOT}/invalid-url.log" 2>&1; then
        print -u2 'Expected a non-HTTPS privacy URL to fail.'
        return 1
    fi
    [[ ! -s "${TEMP_ROOT}/swift.log" ]]
}

function test_build_app_when_privacy_url_contains_credentials_then_stops_before_external_tools {
    # Arrange
    create_distribution_profile
    : > "${TEMP_ROOT}/swift.log"

    # Act & Assert
    if BOUNDLESS_TRANSLATOR_PRIVACY_POLICY_URL='https://user:secret@example.com/privacy' run_builder > "${TEMP_ROOT}/credential-url.log" 2>&1; then
        print -u2 'Expected a privacy URL with credentials to fail.'
        return 1
    fi
    [[ ! -s "${TEMP_ROOT}/swift.log" ]]
}

function test_build_app_when_copyright_is_empty_then_stops_before_external_tools {
    # Arrange
    create_distribution_profile
    : > "${TEMP_ROOT}/swift.log"

    # Act & Assert
    if BOUNDLESS_TRANSLATOR_APP_STORE_COPYRIGHT='' run_builder > "${TEMP_ROOT}/empty-copyright.log" 2>&1; then
        print -u2 'Expected an empty App Store copyright to fail.'
        return 1
    fi
    [[ ! -s "${TEMP_ROOT}/swift.log" ]]
}

function test_build_app_when_developer_id_identity_is_supplied_then_rejects_wrong_distribution_type {
    # Arrange
    create_distribution_profile
    : > "${TEMP_ROOT}/swift.log"

    # Act & Assert
    if BOUNDLESS_TRANSLATOR_APP_STORE_SIGNING_IDENTITY="Developer ID Application: Example (${TEAM_ID})" run_builder > "${TEMP_ROOT}/wrong-identity.log" 2>&1; then
        print -u2 'Expected a Developer ID identity to be rejected for the App Store build.'
        return 1
    fi
    [[ ! -s "${TEMP_ROOT}/swift.log" ]]
}

function test_build_app_when_profile_omits_get_task_allow_then_accepts_distribution_profile {
    # Arrange
    create_distribution_profile "${TEAM_ID}.${BUNDLE_ID}" '2099-12-31T23:59:59Z' absent
    : > "${TEMP_ROOT}/signing.log"

    # Act
    run_builder

    # Assert
    [[ -f "${APP_PATH}/Contents/MacOS/BoundlessTranslator" ]]
}

function test_build_app_when_signing_certificate_is_not_in_profile_then_stops_before_signing {
    # Arrange
    create_distribution_profile "${TEAM_ID}.${BUNDLE_ID}" '2099-12-31T23:59:59Z' false 'd3JvbmcgY2VydGlmaWNhdGU='
    : > "${TEMP_ROOT}/signing.log"

    # Act & Assert
    if run_builder > "${TEMP_ROOT}/certificate-mismatch.log" 2>&1; then
        print -u2 'Expected a signing certificate outside the profile to fail.'
        return 1
    fi
    [[ ! -s "${TEMP_ROOT}/signing.log" ]]
}

create_fixture
create_platform_stubs
test_build_app_when_app_store_requested_then_builds_store_variant_from_shared_sources
test_build_app_when_version_has_two_components_then_uses_it
test_build_app_when_profile_does_not_match_bundle_then_preserves_existing_store_app
test_build_app_when_privacy_url_is_not_https_then_stops_before_external_tools
test_build_app_when_privacy_url_contains_credentials_then_stops_before_external_tools
test_build_app_when_copyright_is_empty_then_stops_before_external_tools
test_build_app_when_developer_id_identity_is_supplied_then_rejects_wrong_distribution_type
test_build_app_when_profile_omits_get_task_allow_then_accepts_distribution_profile
test_build_app_when_signing_certificate_is_not_in_profile_then_stops_before_signing

print 'App Store build tests passed.'
