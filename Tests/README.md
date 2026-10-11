# Test entry points

Run these commands from the repository root. Public entries live in `Scripts/`; each runs only its own level.

| Entry | Scope |
|---|---|
| `Scripts/run_unit_tests.sh` | All Unit tests once, without the subscription compile condition |
| `Scripts/run_component_tests.sh` | All Component tests once, sharing the Unit build directory |
| `Scripts/run_gui_tests.sh` | 14 default local UI cases: native event routing, translation/screenshot Lookup, resize, hint persistence and localized controls |
| `Scripts/run_e2e_tests.sh` | Build the signed E2E App and test its complete product flows; no DMG packaging or installation |
| `Scripts/run_storekit_tests.sh` | Local simulated purchases and subscription entitlements; no charges |
| `Scripts/run_language_support_tests.sh` | Real Apple Translation and OCR fixtures; requires ready translation models |
| `Scripts/run_script_tests.sh` | Shell orchestration and Xcode project checks, without real publishing |
| `Scripts/run_release_tests.sh` | Build/notarize a DMG, then verify the package and launch an installed copy |
| `Scripts/verify.sh` | Run all eight entries and report every failed or unavailable level |

Production code changes require Unit and Component before delivery. Test-only changes run only the changed levels; GUI/E2E run the changed cases. Shared test tools require affected groups, and script changes require their Shell tests. Other levels run on request. See [project workflow](../AGENTS.md). No entry uploads to App Store Connect.

Subscription tests construct subscribed and unsubscribed states directly. App Store archiving checks the resolved `SUBSCRIPTION_REQUIRED` setting before building; Unit and Component do not repeat under that compile condition.

## Coverage boundaries

| Level | Responsibility |
|---|---|
| Unit | Selection ranges, forward/reverse endpoints, row ordering, paragraph joining, preview targets and card positioning; declared interface languages, localization completeness and loading |
| Component | Production views/controllers: selection, copy/translation input, delayed OCR, image replacement, hints and empty-recognition Alerts; preview cancellation, stale results, chunk failures, retry, speech/Lookup input and scrolling. Fixed screenshot inputs use real Vision recognition without another App. |
| GUI (14 default cases) | First drag into an inactive window; translation closure restores cursor/selection; source click is delivered; selection and translation after returning from another App; hover-card actions, selection and native Lookup return; translation survives native Lookup and resumes outside-click dismissal; native border resize; dictionary/screenshot dismissal across restarts; localized Settings controls fit in light/dark mode |
| E2E (4 cases) | External-editor selection in both Accessibility-exposing and copy-only modes; screenshot translation; first drag and translation after returning from another App; Settings focus after reopening |

Esc and the close button are two inputs to one closure regression. Geometry variations stay in fast tests. SwiftUI control placement and persistent tip lifecycle retain GUI coverage; size/color measurements and controller cleanup remain Component tests.

The screenshot workflow ends after the shortcut opens the full translation window with the selected sentence. External-editor selection covers both editor modes in one launch. App switching and reopening Settings have independent cases, each preparing its own screenshot/translation state. Shared helpers reuse code, not runtime state between cases.

## Selecting cases

Unit and Component accept one optional test-name regular expression:

```sh
Scripts/run_unit_tests.sh test_layout_when_sameRowHasDifferentFontHeights
Scripts/run_component_tests.sh test_appearance_when_switchingLightDarkLight
```

GUI and E2E accept one or more `TestClass[/testMethod]` selectors:

```sh
Scripts/run_gui_tests.sh ImageTextFocusGUITests
Scripts/run_gui_tests.sh HintPresentationGUITests
Scripts/run_e2e_tests.sh SelectionTranslationE2ETests
Scripts/run_e2e_tests.sh ScreenshotE2ETests
```

GUI preview tests cover two combinations: light appearance with a white background and short translation; dark appearance with a colorful background and long translation.

To test Lookup's first-use Continue prompt, run `Scripts/reset_lookup_dictionary.sh` in your terminal before each case below. The Runner never resets dictionary preferences. Without a reset, these cases verify ordinary Lookup:

```sh
Scripts/run_gui_tests.sh ImageTextFocusGUITests/test_translationLookup_when_opened_then_keepsWindowAndRestoresDismissal
Scripts/run_gui_tests.sh ImageTextSelectionGUITests/test_previewLookup_when_closed_then_hoverCanContinue
```

Other entries run their entire level without selectors. Unknown/empty test selections fail result validation. Hints use the GUI runner; image GUI cases and product E2E cases keep the E2E runner. The GUI and E2E entries select disjoint sets of cases. Do not run overlapping desktop tests concurrently.

## Environment and artifacts

- GUI and E2E require an unlocked interactive Mac and XCTest automation permission. E2E also requires Accessibility, Screen Recording, translation models and the signing identity used by `Scripts/build_dmg_app.sh`.
- E2E builds directly to `Build/E2E/App/Boundless Translator E2E.app`, with bundle ID `com.lillard.BoundlessTranslator.e2e`. It does not install or notarize a DMG. Test launches use separate shortcuts and preferences.
- Permission setup is opt-in: `Scripts/run_e2e_tests.sh --from-permission-setup`. It resets only E2E permissions and pauses for macOS authorization. Neither normal E2E nor Verify resets permissions.
- GUI results are under `Build/GUI/Results.*`; E2E results are under `Build/E2E/Results`. GUI/E2E reject missing, empty, failed or skipped results.
- GUI assertions read accessibility values and frames through XCUITest, without shared state files. Fixture Apps keep their own TipKit stores; the Runner passes a session identifier rather than accessing those stores.
- Image GUI fixtures open on the primary screen: a narrow focus window on the left and the screenshot in the center. Setup does not drag windows; app-switching cases click the visible windows.
- StoreKit temporarily skips on every macOS/Xcode version and returns exit 78. Use `Scripts/run_storekit_tests.sh --force` for diagnostics. See [StoreKit testing](../app-store/storekit-testing.md).
- Release verification requires signing credentials, notarization credentials and network access. With no argument, it produces the current `Build/Boundless Translator DMG Test.dmg`. To check an existing artifact without rebuilding or submitting it again: `Scripts/run_release_tests.sh '/absolute/path/to/file.dmg'`. It copies the App to a temporary directory, detaches the image, verifies the installed copy and launches it. It does not replace `/Applications` or automate Finder drag-and-drop.
- `Scripts/release_dmg.sh` remains the independent command for producing an installable DMG. Packaging alone does not run the test suite.
- Verify has no partial mode. It attempts all entries and ends with each level's PASS/FAIL/SKIPPED result and totals. Any failure or skip returns nonzero. It does not certify TestFlight purchasing or App Store submission; those still require acceptance of the actual store build.

## Layout

`Unit/` and `Component/` contain fast tests. `GUI/` contains local UI fixtures and cases; `E2E/` contains product tests. `StoreKit/`, `LanguageSupport/` and `Scripts/` hold their respective checks. Public Shell entries live directly under `Scripts/`; shared test helpers live in `Scripts/Shared/`. Only `Tests/Scripts/` contains Shell tests. `Infrastructure/` contains Swift test support and Xcode configuration. `Fixtures/` contains shared data; feature-specific fixtures remain beside their tests.
