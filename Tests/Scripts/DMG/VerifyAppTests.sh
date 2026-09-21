#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly VERIFIER="${PROJECT_ROOT}/Scripts/DMG/verify_app.sh"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-verify-tests.XXXXXX)"
readonly APP_PATH="${TEMP_ROOT}/Boundless Translator.app"
readonly MOCK_BIN="${TEMP_ROOT}/bin"
trap 'rm -rf "${TEMP_ROOT}"' EXIT

function create_app_fixture {
    local resources_path="${APP_PATH}/Contents/Resources"
    local executable_path="${APP_PATH}/Contents/MacOS/Boundless Translator"
    local info_plist="${APP_PATH}/Contents/Info.plist"

    mkdir -p "${APP_PATH}/Contents/MacOS"
    local localization_path
    for localization_path in "${PROJECT_ROOT}"/Sources/BoundlessTranslator/Resources/*.lproj; do
        mkdir -p "${resources_path}/${localization_path:t}"
    done
    plutil -create xml1 "${info_plist}"
    plutil -insert CFBundleExecutable -string 'Boundless Translator' "${info_plist}"
    plutil -insert LSMinimumSystemVersion -string 15.0 "${info_plist}"
    cp "${PROJECT_ROOT}/Resources/PrivacyInfo.xcprivacy" "${resources_path}/PrivacyInfo.xcprivacy"
    cat > "${executable_path}" <<'EOF'
#!/bin/zsh
sleep 10
EOF
    chmod +x "${executable_path}"
}

function create_tool_stubs {
    mkdir -p "${MOCK_BIN}"
    cat > "${MOCK_BIN}/codesign" <<'EOF'
#!/bin/zsh
print -r -- "codesign $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
if [[ "$*" == *--verify* && "${TEST_CODESIGN_VERIFY_FAIL:-false}" == true ]]; then
    exit 1
fi
if [[ "$*" == *--entitlements* ]]; then
    sandbox_value='<true/>'
    network_value='<true/>'
    [[ "${TEST_SANDBOX_ENABLED:-true}" == true ]] || sandbox_value='<false/>'
    [[ "${TEST_NETWORK_ENABLED:-true}" == true ]] || network_value='<false/>'
    print "<plist version=\"1.0\"><dict><key>com.apple.security.app-sandbox</key>${sandbox_value}<key>com.apple.security.network.client</key>${network_value}</dict></plist>"
elif [[ "$*" == *--display* ]]; then
    print 'flags=0x10000(runtime) Timestamp=verified-test-timestamp TeamIdentifier=3S9ZKKJ6PW'
fi
EOF
    cat > "${MOCK_BIN}/vtool" <<'EOF'
#!/bin/zsh
print "minos ${TEST_MINIMUM_OS_VERSION:-15.0}"
EOF
    cat > "${MOCK_BIN}/otool" <<'EOF'
#!/bin/zsh
print "$2:"
[[ "${TEST_INCLUDE_TRANSLATION_FRAMEWORK:-true}" != true ]] || print '/System/Library/Frameworks/Translation.framework/Versions/A/Translation'
[[ "${TEST_INCLUDE_VISIONKIT_FRAMEWORK:-true}" != true ]] || print '/System/Library/Frameworks/VisionKit.framework/Versions/A/VisionKit'
EOF
    chmod +x "${MOCK_BIN}/codesign" "${MOCK_BIN}/vtool" "${MOCK_BIN}/otool"
}

function run_verifier {
    PATH="${MOCK_BIN}:${PATH}" \
    BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${TEMP_ROOT}/calls.log" \
    BOUNDLESS_TRANSLATOR_APP_LAUNCH_WAIT_SECONDS=0.05 \
        zsh "${VERIFIER}" "${APP_PATH}"
}

function test_verify_app_when_app_contract_is_complete_then_succeeds {
    # Arrange

    # Act & Assert
    run_verifier
}

function test_verify_app_when_privacy_manifest_is_missing_then_fails {
    # Arrange
    rm "${APP_PATH}/Contents/Resources/PrivacyInfo.xcprivacy"

    # Act & Assert
    if run_verifier >/dev/null 2>&1; then
        print -u2 'Expected a missing privacy manifest to fail verification.'
        return 1
    fi
    cp "${PROJECT_ROOT}/Resources/PrivacyInfo.xcprivacy" "${APP_PATH}/Contents/Resources/PrivacyInfo.xcprivacy"
}

function test_verify_app_when_binary_targets_wrong_macos_version_then_fails {
    # Arrange

    # Act & Assert
    if TEST_MINIMUM_OS_VERSION=14.0 run_verifier >/dev/null 2>&1; then
        print -u2 'Expected an incorrect binary deployment target to fail verification.'
        return 1
    fi
}

function test_verify_app_when_required_framework_is_missing_then_fails {
    # Arrange

    # Act & Assert
    if TEST_INCLUDE_TRANSLATION_FRAMEWORK=false run_verifier >/dev/null 2>&1; then
        print -u2 'Expected a missing Translation framework dependency to fail verification.'
        return 1
    fi
}

function test_verify_app_when_executable_exits_immediately_then_fails {
    # Arrange
    local executable_path="${APP_PATH}/Contents/MacOS/Boundless Translator"
    cat > "${executable_path}" <<'EOF'
#!/bin/zsh
exit 0
EOF
    chmod +x "${executable_path}"

    # Act & Assert
    if run_verifier >/dev/null 2>&1; then
        print -u2 'Expected an App that exits immediately to fail verification.'
        return 1
    fi
    cat > "${executable_path}" <<'EOF'
#!/bin/zsh
sleep 10
EOF
    chmod +x "${executable_path}"
}

function test_verify_app_when_signature_lacks_sandbox_then_fails {
    # Arrange

    # Act & Assert
    if TEST_SANDBOX_ENABLED=false run_verifier >/dev/null 2>&1; then
        print -u2 'Expected a non-sandboxed signature to fail verification.'
        return 1
    fi
}

function test_verify_app_when_signature_lacks_network_access_then_fails {
    # Arrange

    # Act & Assert
    if TEST_NETWORK_ENABLED=false run_verifier >/dev/null 2>&1; then
        print -u2 'Expected a signature without outgoing network access to fail verification.'
        return 1
    fi
}

function test_verify_app_when_signature_is_invalid_then_fails {
    # Arrange

    # Act & Assert
    if TEST_CODESIGN_VERIFY_FAIL=true run_verifier >/dev/null 2>&1; then
        print -u2 'Expected an invalid signature to fail verification.'
        return 1
    fi
}

function test_verify_app_when_e2e_identity_is_expected_then_verifies_e2e_bundle {
    # Arrange
    : > "${TEMP_ROOT}/calls.log"

    # Act
    BOUNDLESS_TRANSLATOR_BUNDLE_IDENTIFIER='com.lillard.BoundlessTranslator.e2e' \
        run_verifier

    # Assert
    grep -Fq 'identifier "com.lillard.BoundlessTranslator.e2e"' "${TEMP_ROOT}/calls.log"
}

create_app_fixture
create_tool_stubs
test_verify_app_when_privacy_manifest_is_missing_then_fails
test_verify_app_when_binary_targets_wrong_macos_version_then_fails
test_verify_app_when_required_framework_is_missing_then_fails
test_verify_app_when_executable_exits_immediately_then_fails
test_verify_app_when_signature_lacks_sandbox_then_fails
test_verify_app_when_signature_lacks_network_access_then_fails
test_verify_app_when_signature_is_invalid_then_fails
test_verify_app_when_e2e_identity_is_expected_then_verifies_e2e_bundle
test_verify_app_when_app_contract_is_complete_then_succeeds

print 'App verification tests passed.'
