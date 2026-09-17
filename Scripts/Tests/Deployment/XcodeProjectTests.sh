#!/bin/zsh

set -euo pipefail

readonly PROJECT_ROOT="${0:A:h:h:h:h}"
readonly XCODE_PROJECT="${PROJECT_ROOT}/BoundlessTranslator.xcodeproj"
readonly PROJECT_FILE="${XCODE_PROJECT}/project.pbxproj"
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
    grep -Eq '^ *CODE_SIGN_STYLE = Automatic$' "${app_store_settings}"
    ! grep -Eq '^ *CODE_SIGN_IDENTITY = Apple Distribution$' "${app_store_settings}"
    grep -Eq '^ *SWIFT_ACTIVE_COMPILATION_CONDITIONS = .*SUBSCRIPTION_REQUIRED' "${app_store_settings}"
}

test_xcode_project_when_listed_then_exposes_release_schemes_and_configurations
test_xcode_project_when_sources_or_dependencies_change_then_configuration_stays_in_sync
test_xcode_project_when_release_configuration_changes_then_subscription_flag_stays_separated
print 'Xcode project tests passed.'
