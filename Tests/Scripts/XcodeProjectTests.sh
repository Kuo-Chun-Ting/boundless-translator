#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h}"
readonly XCODE_PROJECT="${PROJECT_ROOT}/BoundlessTranslator.xcodeproj"
readonly PROJECT_FILE="${XCODE_PROJECT}/project.pbxproj"
readonly APP_IDENTITY_CONFIGURATION="${PROJECT_ROOT}/Configurations/BoundlessTranslator.xcconfig"
readonly GUI_TEST_PROJECT="${PROJECT_ROOT}/Tests/GUIProject/BoundlessTranslatorGUITests.xcodeproj"
readonly E2E_TEST_PLAN="${PROJECT_ROOT}/Tests/GUIProject/BoundlessTranslatorE2ETests.xctestplan"
readonly PACKAGE_RESOLVED="${PROJECT_ROOT}/Package.resolved"
readonly XCODE_PACKAGE_RESOLVED="${XCODE_PROJECT}/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
readonly TEMP_ROOT="$(mktemp -d /private/tmp/boundless-translator-xcode-project-tests.XXXXXX)"
trap 'rm -rf "${TEMP_ROOT}"' EXIT

function test_xcode_project_when_listed_then_exposes_release_schemes_and_configurations {
    # Arrange
    local output_path="${TEMP_ROOT}/xcode-list.txt"

    # Act
    xcodebuild -list -project "${XCODE_PROJECT}" > "${output_path}"

    # Assert
    local output="$(<"${output_path}")"
    [[ "${output}" == *BoundlessTranslator-Direct* ]]
    [[ "${output}" == *BoundlessTranslator-AppStore* ]]
    [[ "${output}" == *DirectRelease* ]]
    [[ "${output}" == *AppStoreRelease* ]]
}

function test_xcode_project_when_sources_or_dependencies_change_then_configuration_stays_in_sync {
    # Arrange
    local source_path

    # Act & Assert
    cmp "${PACKAGE_RESOLVED}" "${XCODE_PACKAGE_RESOLVED}"
    while IFS= read -r source_path; do
        local relative_path="${source_path#${PROJECT_ROOT}/}"
        grep -Fq "path = \"${relative_path}\";" "${PROJECT_FILE}"
    done < <(find "${PROJECT_ROOT}/Sources/BoundlessTranslator" -type f -name '*.swift' | sort)
    while IFS= read -r localization_path; do
        local relative_path="${localization_path#${PROJECT_ROOT}/}"
        grep -Fq "path = \"${relative_path}/Localizable.strings\";" "${PROJECT_FILE}"
    done < <(find "${PROJECT_ROOT}/Sources/BoundlessTranslator/Resources" -type d -name '*.lproj' | sort)
}

function test_xcode_project_when_release_configuration_changes_then_subscription_flag_stays_separated {
    # Arrange
    local direct_settings="${TEMP_ROOT}/direct-build-settings.txt"
    local app_store_settings="${TEMP_ROOT}/app-store-build-settings.txt"

    # Act
    xcodebuild -showBuildSettings \
        -project "${XCODE_PROJECT}" \
        -scheme BoundlessTranslator-Direct \
        -configuration DirectRelease \
        > "${direct_settings}"
    xcodebuild -showBuildSettings \
        -project "${XCODE_PROJECT}" \
        -scheme BoundlessTranslator-AppStore \
        -configuration AppStoreRelease \
        > "${app_store_settings}"

    # Assert
    ! grep -Eq '^ *SWIFT_ACTIVE_COMPILATION_CONDITIONS = .*SUBSCRIPTION_REQUIRED' "${direct_settings}"
    grep -Eq '^ *CODE_SIGN_INJECT_BASE_ENTITLEMENTS = NO$' "${direct_settings}"
    grep -Eq '^ *OTHER_CODE_SIGN_FLAGS = --timestamp$' "${direct_settings}"
    grep -Eq '^ *INFOPLIST_FILE = Resources/Info.plist$' "${direct_settings}"
    grep -Eq '^ *EXECUTABLE_NAME = Boundless Translator$' "${direct_settings}"
    [[ ! -e "${PROJECT_ROOT}/Resources/AppInfo.plist" ]]
    grep -Eq '^ *CODE_SIGN_STYLE = Automatic$' "${app_store_settings}"
    grep -Eq '^ *DEBUG_INFORMATION_FORMAT = dwarf-with-dsym$' "${app_store_settings}"
    grep -Eq '^ *EXECUTABLE_NAME = Boundless Translator$' "${app_store_settings}"
    ! grep -Eq '^ *CODE_SIGN_IDENTITY = Apple Distribution$' "${app_store_settings}"
    grep -Eq '^ *SWIFT_ACTIVE_COMPILATION_CONDITIONS = .*SUBSCRIPTION_REQUIRED' "${app_store_settings}"
    grep -Eq '^ *DEVELOPMENT_TEAM = 3S9ZKKJ6PW$' "${app_store_settings}"
    grep -Eq '^ *BOUNDLESS_TRANSLATOR_APP_STORE_TEAM_ID = 3S9ZKKJ6PW$' "${app_store_settings}"
    grep -Eq '^ *BOUNDLESS_TRANSLATOR_SUBSCRIPTION_PRODUCT_ID = com\.lillard\.boundless\.annual$' "${app_store_settings}"
    grep -Fq 'BOUNDLESS_TRANSLATOR_PRIVACY_POLICY_URL = https://kuo-chun-ting.github.io/boundless-translator/en/privacy/' "${app_store_settings}"
    grep -Fq 'BOUNDLESS_TRANSLATOR_APP_STORE_COPYRIGHT = Copyright © 2026 Chun Ting Kuo. All rights reserved.' "${app_store_settings}"
}

function test_xcode_project_when_app_identity_is_configured_then_keeps_production_defaults {
    # Arrange

    # Act & Assert
    grep -Fxq 'BOUNDLESS_TRANSLATOR_PRODUCT_NAME = Boundless Translator' "${APP_IDENTITY_CONFIGURATION}"
    grep -Fxq 'BOUNDLESS_TRANSLATOR_BUNDLE_IDENTIFIER = com.lillard.BoundlessTranslator' "${APP_IDENTITY_CONFIGURATION}"
    grep -Fxq 'PRODUCT_NAME = $(BOUNDLESS_TRANSLATOR_PRODUCT_NAME)' "${APP_IDENTITY_CONFIGURATION}"
    grep -Fxq 'PRODUCT_BUNDLE_IDENTIFIER = $(BOUNDLESS_TRANSLATOR_BUNDLE_IDENTIFIER)' "${APP_IDENTITY_CONFIGURATION}"
    [[ "$(grep -Fc 'baseConfigurationReference = ' "${PROJECT_FILE}")" == 3 ]]
    grep -Fq 'path = BoundlessTranslator.xcconfig;' "${PROJECT_FILE}"
    ! grep -Fq 'BOUNDLESS_TRANSLATOR_PRODUCT_NAME =' "${PROJECT_FILE}"
    ! grep -Fq 'BOUNDLESS_TRANSLATOR_BUNDLE_IDENTIFIER =' "${PROJECT_FILE}"
    ! grep -Fq 'PRODUCT_NAME =' "${PROJECT_FILE}"
    ! grep -Fq 'PRODUCT_BUNDLE_IDENTIFIER =' "${PROJECT_FILE}"
    ! grep -Fq 'EXECUTABLE_NAME =' "${PROJECT_FILE}"
    ! grep -Fq 'BOUNDLESS_TRANSLATOR_DISPLAY_NAME' "${PROJECT_FILE}"
    ! grep -Fq 'BOUNDLESS_TRANSLATOR_EXECUTABLE_NAME' "${PROJECT_FILE}"
}

function test_xcode_project_when_e2e_identity_is_overridden_then_changes_only_app_identity_settings {
    # Arrange
    local e2e_settings="${TEMP_ROOT}/e2e-app-build-settings.txt"

    # Act
    xcodebuild -showBuildSettings \
        -project "${XCODE_PROJECT}" \
        -scheme BoundlessTranslator-Direct \
        -configuration DirectRelease \
        'BOUNDLESS_TRANSLATOR_PRODUCT_NAME=Boundless Translator E2E' \
        'BOUNDLESS_TRANSLATOR_BUNDLE_IDENTIFIER=com.lillard.BoundlessTranslator.e2e' \
        > "${e2e_settings}"

    # Assert
    grep -Eq '^ *PRODUCT_NAME = Boundless Translator E2E$' "${e2e_settings}"
    grep -Eq '^ *PRODUCT_BUNDLE_IDENTIFIER = com\.lillard\.BoundlessTranslator\.e2e$' "${e2e_settings}"
    grep -Eq '^ *EXECUTABLE_NAME = Boundless Translator E2E$' "${e2e_settings}"
}

function test_xcode_project_when_app_store_release_is_configured_then_uses_xcode_instead_of_manual_scripts {
    # Arrange

    # Act & Assert
    [[ ! -e "${PROJECT_ROOT}/Scripts/release_app_store.sh" ]]
    [[ ! -e "${PROJECT_ROOT}/Scripts/upload_app_store.sh" ]]
}

function test_gui_test_project_when_listed_then_exposes_on_demand_e2e_scheme_and_targets {
    # Arrange
    local output_path="${TEMP_ROOT}/gui-test-xcode-list.txt"

    # Act
    xcodebuild -list -project "${GUI_TEST_PROJECT}" > "${output_path}"

    # Assert
    local output="$(<"${output_path}")"
    [[ "${output}" == *E2ETestHost* ]]
    [[ "${output}" == *BoundlessTranslatorE2ETests* ]]
    grep -Fq '"key" : "BOUNDLESS_TRANSLATOR_E2E_APP_PATH"' "${E2E_TEST_PLAN}"
    grep -Fq '"value" : "$(BOUNDLESS_TRANSLATOR_E2E_APP_PATH)"' "${E2E_TEST_PLAN}"
}

function test_gui_test_project_when_e2e_targets_are_built_then_uses_development_signing {
    # Arrange
    local host_settings="${TEMP_ROOT}/e2e-host-build-settings.txt"
    local test_settings="${TEMP_ROOT}/e2e-tests-build-settings.txt"

    # Act
    xcodebuild -showBuildSettings \
        -project "${GUI_TEST_PROJECT}" \
        -target E2ETestHost \
        -configuration Debug \
        > "${host_settings}"
    xcodebuild -showBuildSettings \
        -project "${GUI_TEST_PROJECT}" \
        -target BoundlessTranslatorE2ETests \
        -configuration Debug \
        > "${test_settings}"

    # Assert
    grep -Eq '^ *CODE_SIGN_IDENTITY = Apple Development$' "${host_settings}"
    grep -Eq '^ *CODE_SIGN_STYLE = Manual$' "${host_settings}"
    grep -Eq '^ *DEVELOPMENT_TEAM = 3S9ZKKJ6PW$' "${host_settings}"
    grep -Eq '^ *CODE_SIGN_IDENTITY = Apple Development$' "${test_settings}"
    grep -Eq '^ *CODE_SIGN_STYLE = Manual$' "${test_settings}"
    grep -Eq '^ *DEVELOPMENT_TEAM = 3S9ZKKJ6PW$' "${test_settings}"
}

test_xcode_project_when_listed_then_exposes_release_schemes_and_configurations
test_xcode_project_when_sources_or_dependencies_change_then_configuration_stays_in_sync
test_xcode_project_when_release_configuration_changes_then_subscription_flag_stays_separated
test_xcode_project_when_app_identity_is_configured_then_keeps_production_defaults
test_xcode_project_when_e2e_identity_is_overridden_then_changes_only_app_identity_settings
test_xcode_project_when_app_store_release_is_configured_then_uses_xcode_instead_of_manual_scripts
test_gui_test_project_when_listed_then_exposes_on_demand_e2e_scheme_and_targets
test_gui_test_project_when_e2e_targets_are_built_then_uses_development_signing
print 'Xcode project tests passed.'
