#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-build-app-tests.XXXXXX)"
trap 'rm -rf "${TEMP_ROOT}"' EXIT
readonly FIXTURE="${TEMP_ROOT}/project"
readonly MOCK_BIN="${TEMP_ROOT}/bin"
readonly MV_STUB="${TEMP_ROOT}/mv"

mkdir -p "${FIXTURE}/Scripts/Tools" "${FIXTURE}/Resources" "${MOCK_BIN}"
cp "${PROJECT_ROOT}/Scripts/Tools/build_app.sh" "${FIXTURE}/Scripts/Tools/"
cp "${PROJECT_ROOT}/Scripts/Tools/code_signing.conf" "${FIXTURE}/Scripts/Tools/"
cp "${PROJECT_ROOT}/Resources/Info.plist" "${FIXTURE}/Resources/"
if [[ -f "${PROJECT_ROOT}/Resources/PrivacyInfo.xcprivacy" ]]; then
    cp "${PROJECT_ROOT}/Resources/PrivacyInfo.xcprivacy" "${FIXTURE}/Resources/"
fi
touch "${FIXTURE}/Resources/AppIcon.icns"
if [[ -f "${PROJECT_ROOT}/Resources/Sandbox.entitlements" ]]; then
    cp "${PROJECT_ROOT}/Resources/Sandbox.entitlements" "${FIXTURE}/Resources/"
fi

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
print 'test executable' > "${scratch_path}/release/BoundlessTranslator"
EOF

cat > "${MOCK_BIN}/codesign" <<'EOF'
#!/bin/zsh
set -eu
print -r -- "$*" >> "${TEST_SIGNING_LOG}"
if [[ "${TEST_SIGNING_FAIL:-false}" == true ]]; then
    exit 1
fi
while [[ "$#" -gt 0 ]]; do
    if [[ "$1" == --entitlements ]]; then
        [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.app-sandbox' "$2")" == true ]]
        [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.network.client' "$2")" == true ]]
        break
    fi
    shift
done
EOF
chmod +x "${MOCK_BIN}/swift" "${MOCK_BIN}/codesign"

cat > "${MV_STUB}" <<'EOF'
#!/bin/zsh
set -eu
if [[ "$1" == */boundless-translator-build.*'/Boundless Translator.app' && "$2" == "${TEST_FINAL_APP_PATH}" ]]; then
    exit 1
fi
if [[ "$1" == */'Previous Boundless Translator.app' && "$2" == "${TEST_FINAL_APP_PATH}" ]]; then
    exit 1
fi
/bin/mv "$@"
EOF
chmod +x "${MV_STUB}"

function run_builder {
    PATH="${MOCK_BIN}:${PATH}" TEST_SIGNING_LOG="${TEMP_ROOT}/signing.log" \
        TEST_SWIFT_LOG="${TEMP_ROOT}/swift.log" \
        zsh "${FIXTURE}/Scripts/Tools/build_app.sh" "$@"
}

function test_build_app_when_output_root_is_overridden_then_only_publishes_staged_app {
    # Arrange
    local staged_root="${TEMP_ROOT}/isolated-build"
    local shared_app="${FIXTURE}/Build/Boundless Translator.app"
    mkdir -p "${shared_app}"
    print 'shared app' > "${shared_app}/marker"
    : > "${TEMP_ROOT}/signing.log"

    # Act
    BOUNDLESS_TRANSLATOR_BUILD_ROOT="${staged_root}" run_builder

    # Assert
    [[ -f "${staged_root}/Boundless Translator.app/Contents/MacOS/BoundlessTranslator" ]]
    [[ "$(<"${shared_app}/marker")" == 'shared app' ]]
}

function assert_privacy_manifest {
    local manifest="$1/Contents/Resources/PrivacyInfo.xcprivacy"
    plutil -lint "${manifest}"
    [[ "$(plutil -extract NSPrivacyTracking raw -expect bool "${manifest}")" == false ]]
    [[ "$(plutil -extract NSPrivacyTrackingDomains raw -expect array "${manifest}")" == 0 ]]
    [[ "$(plutil -extract NSPrivacyCollectedDataTypes raw -expect array "${manifest}")" == 0 ]]
    [[ "$(plutil -extract NSPrivacyAccessedAPITypes raw -expect array "${manifest}")" == 1 ]]
    [[ "$(plutil -extract NSPrivacyAccessedAPITypes.0.NSPrivacyAccessedAPIType raw "${manifest}")" == NSPrivacyAccessedAPICategoryUserDefaults ]]
    [[ "$(plutil -extract NSPrivacyAccessedAPITypes.0.NSPrivacyAccessedAPITypeReasons.0 raw "${manifest}")" == CA92.1 ]]
}

function test_build_app_when_argument_is_invalid_then_preserves_existing_app {
    # Arrange
    : > "${TEMP_ROOT}/signing.log"
    mkdir -p "${FIXTURE}/Build/Boundless Translator.app"
    print 'existing app' > "${FIXTURE}/Build/Boundless Translator.app/marker"

    # Act & Assert
    if run_builder --invalid > "${TEMP_ROOT}/invalid.log" 2>&1; then
        print -u2 'Expected an unsupported build mode to fail.'
        return 1
    fi
    [[ "$(<"${FIXTURE}/Build/Boundless Translator.app/marker")" == 'existing app' ]]
    [[ ! -s "${TEMP_ROOT}/signing.log" ]]
}

function test_build_app_when_built_then_enables_sandbox_without_changing_source_info {
    # Arrange
    local app_path="${FIXTURE}/Build/Boundless Translator.app"
    local original_info="$(shasum "${FIXTURE}/Resources/Info.plist")"
    mkdir -p "${FIXTURE}/Build/Boundless Translator.app"
    print 'existing app' > "${FIXTURE}/Build/Boundless Translator.app/marker"
    : > "${TEMP_ROOT}/signing.log"

    # Act
    run_builder

    # Assert
    assert_privacy_manifest "${app_path}"
    [[ -f "${app_path}/Contents/MacOS/BoundlessTranslator" ]]
    [[ -d "${app_path}/Contents/Resources/en.lproj" ]]
    [[ "$(plutil -extract CFBundleIdentifier raw "${app_path}/Contents/Info.plist")" == com.lillard.BoundlessTranslator ]]
    [[ "$(<"${TEMP_ROOT}/signing.log")" == *"--entitlements ${FIXTURE}/Resources/Sandbox.entitlements"* ]]
    [[ "$(shasum "${FIXTURE}/Resources/Info.plist")" == "${original_info}" ]]
}

function test_build_app_when_signing_fails_then_preserves_previous_app {
    # Arrange
    local app_path="${FIXTURE}/Build/Boundless Translator.app"
    mkdir -p "${app_path}"
    print 'previous sandbox' > "${app_path}/marker"

    # Act & Assert
    if TEST_SIGNING_FAIL=true run_builder > "${TEMP_ROOT}/failure.log" 2>&1; then
        print -u2 'Expected signing failure to stop the build.'
        return 1
    fi
    [[ "$(<"${app_path}/marker")" == 'previous sandbox' ]]
}

function test_build_app_when_publish_and_rollback_fail_then_preserves_recovery_directory {
    # Arrange
    local app_path="${FIXTURE}/Build/Boundless Translator.app"
    mkdir -p "${app_path}"
    print 'previous app' > "${app_path}/marker"

    # Act & Assert
    if TEST_FINAL_APP_PATH="${app_path}" BOUNDLESS_TRANSLATOR_MV_EXECUTABLE="${MV_STUB}" \
        run_builder > "${TEMP_ROOT}/rollback-failure.log" 2>&1; then
        print -u2 'Expected publish and rollback failure to fail the build.'
        return 1
    fi
    local recovery_path="$(sed -n 's/^Publish rollback incomplete. Recovery artifacts preserved at: //p' "${TEMP_ROOT}/rollback-failure.log")"
    [[ -n "${recovery_path}" ]]
    [[ "$(<"${recovery_path}/Previous Boundless Translator.app/marker")" == 'previous app' ]]
    rm -rf "${recovery_path}"
}

function test_build_app_when_no_mode_given_then_preserves_developer_id_build_contract {
    # Arrange
    local app_path="${FIXTURE}/Build/Boundless Translator.app"
    : > "${TEMP_ROOT}/signing.log"

    # Act
    run_builder

    # Assert
    assert_privacy_manifest "${app_path}"
    [[ "$(plutil -extract CFBundleIdentifier raw "${app_path}/Contents/Info.plist")" == com.lillard.BoundlessTranslator ]]
    [[ "$(<"${TEMP_ROOT}/signing.log")" == *--entitlements* ]]
    [[ "$(<"${TEMP_ROOT}/signing.log")" == *"--options runtime --timestamp --sign"* ]]
    [[ "$(<"${TEMP_ROOT}/swift.log")" != *SUBSCRIPTION_REQUIRED* ]]
    if plutil -extract BoundlessSubscriptionProductID raw "${app_path}/Contents/Info.plist" >/dev/null 2>&1; then
        print -u2 'Free test builds must not contain subscription product configuration.'
        return 1
    fi
}

test_build_app_when_argument_is_invalid_then_preserves_existing_app
test_build_app_when_output_root_is_overridden_then_only_publishes_staged_app
test_build_app_when_built_then_enables_sandbox_without_changing_source_info
test_build_app_when_signing_fails_then_preserves_previous_app
test_build_app_when_publish_and_rollback_fail_then_preserves_recovery_directory
test_build_app_when_no_mode_given_then_preserves_developer_id_build_contract

print 'App build tests passed.'
