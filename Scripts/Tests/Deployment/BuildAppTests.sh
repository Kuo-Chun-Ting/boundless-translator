#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-build-app-tests.XXXXXX)"
trap 'rm -rf "${TEMP_ROOT}"' EXIT
readonly FIXTURE="${TEMP_ROOT}/project"
readonly MOCK_BIN="${TEMP_ROOT}/bin"

mkdir -p "${FIXTURE}/Scripts/Tools" "${FIXTURE}/Resources" "${MOCK_BIN}"
cp "${PROJECT_ROOT}/Scripts/Tools/build_app.sh" "${FIXTURE}/Scripts/Tools/"
cp "${PROJECT_ROOT}/Scripts/Tools/code_signing.conf" "${FIXTURE}/Scripts/Tools/"
cp "${PROJECT_ROOT}/Resources/Info.plist" "${FIXTURE}/Resources/"
touch "${FIXTURE}/Resources/AppIcon.icns"
if [[ -f "${PROJECT_ROOT}/Resources/Sandbox.entitlements" ]]; then
    cp "${PROJECT_ROOT}/Resources/Sandbox.entitlements" "${FIXTURE}/Resources/"
fi

cat > "${MOCK_BIN}/swift" <<'EOF'
#!/bin/zsh
set -eu
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

function run_builder {
    PATH="${MOCK_BIN}:${PATH}" TEST_SIGNING_LOG="${TEMP_ROOT}/signing.log" \
        zsh "${FIXTURE}/Scripts/Tools/build_app.sh" "$@"
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

function test_build_app_when_sandbox_requested_then_isolates_output_and_signs_entitlements {
    # Arrange
    local app_path="${FIXTURE}/Build/Sandbox/Boundless Translator.app"
    local original_info="$(shasum "${FIXTURE}/Resources/Info.plist")"
    mkdir -p "${FIXTURE}/Build/Boundless Translator.app"
    print 'existing app' > "${FIXTURE}/Build/Boundless Translator.app/marker"
    : > "${TEMP_ROOT}/signing.log"

    # Act
    run_builder --sandbox

    # Assert
    [[ -f "${app_path}/Contents/MacOS/BoundlessTranslator" ]]
    [[ -d "${app_path}/Contents/Resources/en.lproj" ]]
    [[ "$(plutil -extract CFBundleIdentifier raw "${app_path}/Contents/Info.plist")" == com.lillard.BoundlessTranslator.Sandbox ]]
    [[ "$(plutil -extract CFBundleDisplayName raw "${app_path}/Contents/Info.plist")" == 'Boundless Translator Sandbox' ]]
    [[ "$(<"${TEMP_ROOT}/signing.log")" == *"--entitlements ${FIXTURE}/Resources/Sandbox.entitlements"* ]]
    [[ "$(<"${FIXTURE}/Build/Boundless Translator.app/marker")" == 'existing app' ]]
    [[ "$(shasum "${FIXTURE}/Resources/Info.plist")" == "${original_info}" ]]
}

function test_build_app_when_signing_fails_then_preserves_previous_sandbox_app {
    # Arrange
    local app_path="${FIXTURE}/Build/Sandbox/Boundless Translator.app"
    mkdir -p "${app_path}"
    print 'previous sandbox' > "${app_path}/marker"

    # Act & Assert
    if TEST_SIGNING_FAIL=true run_builder --sandbox > "${TEMP_ROOT}/failure.log" 2>&1; then
        print -u2 'Expected signing failure to stop the build.'
        return 1
    fi
    [[ "$(<"${app_path}/marker")" == 'previous sandbox' ]]
}

function test_build_app_when_no_mode_given_then_preserves_developer_id_build_contract {
    # Arrange
    local app_path="${FIXTURE}/Build/Boundless Translator.app"
    : > "${TEMP_ROOT}/signing.log"

    # Act
    run_builder

    # Assert
    [[ "$(plutil -extract CFBundleIdentifier raw "${app_path}/Contents/Info.plist")" == com.lillard.BoundlessTranslator ]]
    [[ "$(<"${TEMP_ROOT}/signing.log")" != *--entitlements* ]]
    [[ "$(<"${TEMP_ROOT}/signing.log")" == *"--options runtime --timestamp --sign"* ]]
}

test_build_app_when_argument_is_invalid_then_preserves_existing_app
test_build_app_when_sandbox_requested_then_isolates_output_and_signs_entitlements
test_build_app_when_signing_fails_then_preserves_previous_sandbox_app
test_build_app_when_no_mode_given_then_preserves_developer_id_build_contract

print 'App build tests passed.'
