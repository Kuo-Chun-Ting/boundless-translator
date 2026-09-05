#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly GUI_TESTER="${PROJECT_ROOT}/Scripts/Tests/test_gui.sh"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-test-gui-script-tests.XXXXXX)"
readonly CALL_LOG="${TEMP_ROOT}/calls.log"
readonly XCODEBUILD_STUB="${TEMP_ROOT}/xcodebuild"

function clean_up {
    rm -rf "${TEMP_ROOT}"
}
trap clean_up EXIT

function create_xcodebuild_stub {
    cat > "${XCODEBUILD_STUB}" <<'EOF'
#!/bin/zsh
print -r -- "$*" > "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
EOF
    chmod +x "${XCODEBUILD_STUB}"
}

function test_test_gui_when_started_then_uses_fresh_temporary_derived_data {
    # Arrange
    create_xcodebuild_stub

    # Act
    PATH="${TEMP_ROOT}:${PATH}" \
    BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
        zsh "${GUI_TESTER}"

    # Assert
    local call_arguments="$(<"${CALL_LOG}")"
    local derived_data_path="${call_arguments##* -derivedDataPath }"
    derived_data_path="${derived_data_path%% -jobs *}"
    if [[ "${derived_data_path}" != /private/tmp/boundless-translator-gui.* ]]; then
        print -u2 "Expected a fresh temporary Derived Data path, got: ${derived_data_path}"
        return 1
    fi
    if [[ -e "${derived_data_path}" ]]; then
        print -u2 "Expected temporary Derived Data to be removed: ${derived_data_path}"
        return 1
    fi
}

test_test_gui_when_started_then_uses_fresh_temporary_derived_data

print "GUI test script tests passed."
