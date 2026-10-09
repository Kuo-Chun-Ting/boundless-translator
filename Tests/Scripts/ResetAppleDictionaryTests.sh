#!/bin/zsh
set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"
readonly RESETTER="${PROJECT_ROOT}/Scripts/reset_apple_dictionary.sh"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-lookup-reset-tests.XXXXXX)"
readonly PREFERENCES_PATH="${TEMP_ROOT}/com.apple.lookup.plist"
readonly CALL_LOG="${TEMP_ROOT}/calls.log"
mkdir -p "${TEMP_ROOT}/bin"
trap '/bin/rm -rf "${TEMP_ROOT}"' EXIT

for command_name in killall plutil defaults; do
cat > "${TEMP_ROOT}/bin/${command_name}" <<'MOCK'
#!/bin/zsh
set -euo pipefail
print -r -- "${0:t} $*" >> "${BOUNDLESS_TRANSLATOR_TEST_CALL_LOG}"
case "${0:t}" in
    killall) exit 1 ;;
    plutil) /usr/bin/plutil -convert xml1 -o - "${BOUNDLESS_TRANSLATOR_TEST_PLIST}" ;;
    defaults) /usr/bin/plutil -remove "$3" "${BOUNDLESS_TRANSLATOR_TEST_PLIST}" ;;
esac
MOCK
chmod +x "${TEMP_ROOT}/bin/${command_name}"
done

function run_resetter {
    PATH="${TEMP_ROOT}/bin:${PATH}" \
    BOUNDLESS_TRANSLATOR_TEST_PLIST="${PREFERENCES_PATH}" \
    BOUNDLESS_TRANSLATOR_TEST_CALL_LOG="${CALL_LOG}" \
        zsh "${RESETTER}" "$@"
}

function test_reset_when_firstUseRecordsExist_then_clearsOnlyFirstUseRecords {
    # Arrange
    cat > "${PREFERENCES_PATH}" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>FTE/Lookup</key><string>Acknowledged:312</string>
<key>FTE/Lookup:en_TW</key><string>Acknowledged:example</string>
<key>OtherPreference</key><string>keep</string>
</dict></plist>
PLIST
    # Act
    run_resetter
    # Assert
    [[ "$(plutil -extract OtherPreference raw "${PREFERENCES_PATH}")" == keep ]]
    ! plutil -extract 'FTE/Lookup' raw "${PREFERENCES_PATH}" >/dev/null 2>&1
    ! plutil -extract 'FTE/Lookup:en_TW' raw "${PREFERENCES_PATH}" >/dev/null 2>&1
    local real_preferences="${HOME}/Library/Containers/com.apple.LookupViewService/Data/Library/Preferences/com.apple.lookup.plist"
    [[ "$(sed -n '1p' "${CALL_LOG}")" == 'killall LookupViewService' ]]
    [[ "$(sed -n '3p' "${CALL_LOG}")" == "defaults delete ${real_preferences} FTE/Lookup" ]]
    [[ "$(sed -n '4p' "${CALL_LOG}")" == "defaults delete ${real_preferences} FTE/Lookup:en_TW" ]]
    [[ "$(wc -l < "${CALL_LOG}" | tr -d ' ')" == 4 ]]
}

test_reset_when_firstUseRecordsExist_then_clearsOnlyFirstUseRecords
print 'Apple dictionary reset tests passed.'
