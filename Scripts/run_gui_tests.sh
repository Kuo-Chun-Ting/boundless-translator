#!/bin/zsh
set -euo pipefail
readonly PROJECT_ROOT="${0:A:h:h}"
readonly GUI_ROOT="${BOUNDLESS_TRANSLATOR_GUI_ROOT:-${PROJECT_ROOT}/Build/GUI}"
readonly E2E_ROOT="${BOUNDLESS_TRANSLATOR_E2E_ROOT:-${PROJECT_ROOT}/Build/E2E}"
typeset -a local_cases=() image_cases=()
for name in "$@"; do
    case "${name%%/*}" in
        HintPresentationGUITests)
            local_cases+=("-only-testing:BoundlessTranslatorGUITests/${name}") ;;
        ImageTextFocusGUITests|ImageTextSelectionGUITests)
            image_cases+=("-only-testing:BoundlessTranslatorE2ETests/${name}") ;;
        *) print -u2 "Unknown GUI test: ${name}"; exit 2 ;;
    esac
done
if (( $# == 0 )); then
    local_cases=(
        -only-testing:BoundlessTranslatorGUITests/HintPresentationGUITests
    )
    image_cases=(
        -only-testing:BoundlessTranslatorE2ETests/ImageTextSelectionGUITests
        -only-testing:BoundlessTranslatorE2ETests/ImageTextFocusGUITests
    )
fi
mkdir -p "${GUI_ROOT}"
readonly RESULT_ROOT="$(mktemp -d "${GUI_ROOT}/Results.XXXXXX")"
cd "${PROJECT_ROOT}"
if (( ${#local_cases} )); then
    readonly LOCAL_DERIVED_DATA_PATH="$(mktemp -d /private/tmp/boundless-translator-gui.XXXXXX)"
    trap 'rm -rf "${LOCAL_DERIVED_DATA_PATH}"' EXIT
    xcodebuild test \
        -project Tests/Infrastructure/BoundlessTranslatorTests.xcodeproj \
        -scheme BoundlessTranslatorGUITests \
        -destination 'platform=macOS' \
        -derivedDataPath "${LOCAL_DERIVED_DATA_PATH}" \
        -jobs 1 \
        CC=/usr/bin/true \
        CODE_SIGN_IDENTITY=- \
        CODE_SIGN_STYLE=Manual \
        -resultBundlePath "${RESULT_ROOT}/Local.xcresult" "${local_cases[@]}"
    "${PROJECT_ROOT}/Scripts/Shared/check_xcode_test_results.sh" "${RESULT_ROOT}/Local.xcresult"
fi
if (( ${#image_cases} )); then
    # Preserve the original runner and permissions; only the shell grouping changes.
    xcodebuild test \
        -project Tests/Infrastructure/BoundlessTranslatorTests.xcodeproj \
        -scheme BoundlessTranslatorE2ETests -testPlan BoundlessTranslatorE2ETests \
        -destination 'platform=macOS' -derivedDataPath "${E2E_ROOT}/DerivedData" \
        -resultBundlePath "${RESULT_ROOT}/ImageText.xcresult" \
        -parallel-testing-enabled NO -jobs 1 "${image_cases[@]}"
    "${PROJECT_ROOT}/Scripts/Shared/check_xcode_test_results.sh" "${RESULT_ROOT}/ImageText.xcresult"
fi
print "GUI tests passed. Results: ${RESULT_ROOT}"
