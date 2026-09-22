# Boundless Translator Spec

## Product

Boundless Translator is a macOS 15 menu bar app for translating selected text and text recognized in screenshots. It presents translations in a compact floating window and provides configurable shortcuts for translation and direct screenshot capture.

## Shortcut Flow

When the user presses the translation shortcut (default `Command-Shift-1`):

1. If text is selected in the active image workspace, translate it.
2. Otherwise, read selected text from the active app through Accessibility. Use the clipboard fallback only when Accessibility cannot read the selection.
3. Translate the selected text. No selection or cancellation stops quietly. Missing Accessibility permission opens permission guidance; unexpected errors are reported without starting screenshot capture.

The screenshot shortcut (default `Command-Shift-2`) starts native region capture directly, without checking selected text. Open the captured image in the image workspace for Live Text selection; the user can then select text and press the translation shortcut. Only one shortcut request runs at a time. Pause each global shortcut while it is being recorded.

## Translation

- Translate with Apple's Translation framework.
- Use the configured source language or detect it automatically.
- Ask the user to choose a source language when detection confidence is insufficient.
- Use the configured target language by default.
- Allow the source and target languages to change for the current translation without changing saved defaults.
- Preserve the current request for retry after a recoverable failure.

## Translation Window

- Show source and translated text in two equal, selectable panels.
- Grow the initial window height with content up to 440 points, then scroll overflowing text. The translation window remains resizable.
- Keep language menus and speech controls aligned with their respective panels when resized.
- Read the source or translated text with a system voice that supports its language.
- Selecting source text reveals the book action. Activating it opens the macOS Lookup overlay for that exact selection.
- Position the window on the screen containing the pointer.
- Close an unpinned translation when the user clicks outside it, activates another app, or presses Escape.
- Keep a pinned translation visible until the user closes or unpins it.
- Preserve the window's top-left position when its content-driven size changes.
- When a shortcut presents a translation-related window, make that window Boundless Translator's main and key window before activating the app so other open windows remain behind it.

## Screenshot Workspace

- Open the captured image in a standard, resizable macOS window titled Screenshot.
- Fit the initial window to the image and the active screen while preserving the image aspect ratio.
- Use VisionKit Live Text for native text recognition and selection.
- Keep the workspace open across app deactivation and translation-window presentation.
- Replace the displayed image after a successful capture; keep the existing image when capture is cancelled or fails.
- After every successful capture, make the workspace Boundless Translator's main and key window before activating the app so other open windows remain behind it, including when the workspace was closed, covered, or minimized.
- Close the focused workspace with Escape or Command-W, including while image text is selected.
- Clear its active selection when the window closes so stale text cannot override later selections.
- Update the workspace background when macOS appearance changes without replacing the image or resetting its selection.
- Use native macOS interactive capture through `screencapture`.
- Control-modified capture is not supported: macOS redirects its result to the clipboard instead of the capture file.
- Request Screen Recording permission when needed. If it is unavailable, explain how to allow it in System Settings > Privacy & Security and that reopening the app may be necessary.
- Pressing Escape during capture cancels it without an error window.
- Present a localized error when capture fails.
- Do not add paste or image-import entry points, custom OCR regions, translation overlays, or image history.

## Preferences

- Open Preferences on first launch and whenever the running app is opened again through Spotlight or Finder.
- Present Preferences on the screen containing the pointer, make it Boundless Translator's main and key window before activating the app so other open windows remain behind it and Command-W closes it immediately.
- Present Preferences as one level of labeled rows without section headings.
- Order Preferences as Translate From, Translate To, Keyboard Shortcut, Screenshot, Language, then Usage.
- Group Translate From and Translate To in the first settings card, then both shortcuts and Language in the second.
- Use the macOS window background and native grouped-form cards in light and dark appearances, including when appearance changes while Preferences is open.
- Fit all settings without scrolling or unused vertical space. Size the window to accommodate localized labels.
- Configure the interface language independently from translation languages.
- Follow the current macOS interface language by default.
- Allow the user to override the interface with any language localized by macOS, and keep that choice when the macOS language changes.
- Display each interface-language option as its native name followed by its name in the current interface language.
- Show the effective macOS interface language beside System Default.
- Apply interface-language changes immediately to open Preferences and translation windows.
- Configure the default source and target languages.
- Configure the translation shortcut, defaulting to `Command-Shift-1`, and the direct screenshot shortcut, defaulting to `Command-Shift-2`.
- Preserve saved shortcuts when defaults change; use the defaults only when a saved shortcut is missing or invalid.
- Cancel unfinished shortcut recording when Preferences closes or loses focus, restoring the saved shortcut.
- Open the compact Usage popover from a standard macOS Help button at the bottom right.
- Provide a low-emphasis Quit action at the bottom left when the menu bar item is unavailable.
- Subscription-required builds expose Subscription from Preferences and the menu bar, including when feature access has expired. Free-testing builds do not show purchase controls.

## Architecture

- `Application` composes dependencies and routes the translation and screenshot shortcuts to their separate features. `Application/Shortcut` owns independent shortcut registration and persistence. Settings pauses and restores each shortcut during recording.
- `Application` owns one foreground-window presenter. It makes the latest requested interactive window main and key before activating the accessory app, then confirms that same window after activation completes.
- `Selection` reads external text through Accessibility and clipboard fallback strategies.
- `ImageViewer` owns native interactive capture, its permission and failure handling, captured-image input, Live Text selection, and the persistent image window. Application coordinates capture and routes selected image text into the same translation flow as external text.
- `Translation` owns requests, state, failures, and the supported-language catalog. Its subdirectories group the complete translation feature:
  - `UI` owns translation-window layout, lifecycle, dismissal, pinning, and language controls.
  - `Engines` defines the runner contract and the engine composition value. `Engines/Apple` owns Apple configuration, session hosting, language availability, execution, and error conversion.
  - `LanguageDetection` resolves automatic source-language detection and confirmation.
  - `Speech` owns language support and source or target playback state.
  - `Lookup` owns dictionary selection and Lookup presentation.
- Application selects the engine and supplies its language loader to the catalog and its task host to the translation window. The window recreates the task host for each request, including retries and language changes.
- Runners report shared translation failures. Apple errors are normalized inside the Apple adapter; the coordinator preserves normalized failures and ignores stale results and errors.
- `Settings` owns Preferences composition, persisted translation defaults, and the interface-language preference. It receives the composed language catalog instead of choosing an engine.
- `Localization` resolves interface strings from `Resources`, independently of the translation engine.
- `Subscription` owns verified StoreKit access state and the native subscription window. Application injects an authorization callback into translation coordination and checks access before reading a selection or capturing a screenshot; retry, language changes, and delayed engine execution use the same gate.
- Interface localization covers every language localized by macOS and remains independent from Translation framework language availability.
- Usage explains that interface-language coverage and translation-language availability follow macOS support.

These directories belong to one executable target, not separate Swift packages. Platform adapters remain behind focused protocols or injected operations so application flow, state, and UI behavior can be tested without invoking external apps or Apple framework internals. The only production translation engine is Apple. Purchase access is an application-level concern and remains independent from the translation engine.

## App Store Distribution

- Maintain the App Store and Developer ID distributions in the same repository and branch.
- Share product code between distributions. Keep signing, entitlements, packaging, upload, and purchase integration specific to each distribution.
- Build verification confirms the signed App Sandbox entitlement before distribution. Runtime behavior is covered by normal DMG acceptance and by testing the exact TestFlight build; there is no separate Sandbox build or Sandbox checklist.
- Every packaged App enables App Sandbox and outgoing-network access. The production test DMG is subscription-free; the App Store build enables subscription access control. Both production editions use the same sources and bundle identifier, not a separate Sandbox test edition. The automated E2E build uses a separate product name, bundle identifier, data container, and permission records so it cannot alter an installed production App. A successful build does not prove runtime compatibility or App Review eligibility.
- `Resources/Sandbox.entitlements` is the shared source for both distributions. Xcode signing adds the matching application and team identifiers to the signed App; the project does not maintain a separate App Store entitlements file.
- Cross-app selection uses `AXUIElement`. An unavailable Accessibility selection uses the clipboard fallback; a confirmed empty selection stops quietly. It has been exercised in a sandboxed local build; the exact App Store-signed build remains part of normal TestFlight acceptance.
- Preserve the Developer ID DMG workflow for development and direct testing. Direct distribution currently produces only the unrestricted test edition.
- Use Xcode Organizer for the App Store Archive, validation, package creation and upload. Uploading a build to App Store Connect does not submit it for review or publish it.

## App Store Subscription

- Distribute the App Store build as a free download with one auto-renewable annual subscription.
- Set the subscription price to NT$199 per year in App Store Connect.
- Offer eligible users a one-month introductory free trial. Downloading or launching the App does not start the trial; the user must confirm the subscription through StoreKit.
- Allow the current product features while the introductory trial or subscription entitlement is active.
- When access expires, keep Preferences, subscription purchase, subscription management, and restore-purchases available. Require active access before starting translation or screenshot capture.
- Use StoreKit verified transactions as the source of App Store access. Do not require an account, database, or custom purchase server for the initial release.
- Translation and screenshot capture share the configured basic annual product ID. Await the initial entitlement load before deciding access and continue the original action after a successful load. Concurrent requests share that load; a superseded refresh must not cause an early denial. Once loaded, recheck access at each feature entry, including translation retries and language changes.
- Handle purchase cancellation, pending approval, renewal failure, expiration, refund or revocation, restored purchases, and reinstall. Do not revoke an already verified, unexpired entitlement solely because StoreKit refresh is temporarily unavailable.
- Do not define pricing or access rules for unplanned future features.
- The `SUBSCRIPTION_REQUIRED` compile condition controls access policy independently of packaging format. The App Store build enables it; the test DMG does not. Missing Store configuration fails closed. Product ID and the public HTTPS privacy-policy URL are injected into the App Store bundle, not hard-coded in Swift. Free-testing builds skip subscription checks and StoreKit observation. A paid website edition needs its own purchase provider and is not implemented.
- Use a compact SwiftUI subscription window with the app icon above both states and native Light/Dark appearance and the selected interface language. Unsubscribed users see the translation purpose, annual plan, StoreKit-localized price, eligible free-trial duration, purchase button and automatic-renewal disclosure. Subscribed users see the annual plan, active status, verified renewal price when available, renewal or access-expiration date, and subscription management. Both states provide secondary restore-purchases, terms and privacy links; omit the redundant subscription heading, status paragraphs and permanent refresh button.
- Load product details through StoreKit's `storeProductTask` and use `SubscriptionStoreView` with a custom `SubscriptionStoreControlStyle` to preserve this hierarchy. Read trial eligibility from its active offer and invoke its native subscribe action; do not maintain a separate `Product.purchase()` flow. Restore only on explicit user request through `AppStore.sync()`. Keep product-loading errors separate from verified access so unavailable product details never hide an active subscription. Offer retry when product loading fails; report cancellation quietly, pending approval without granting access, and purchase or restore errors inline. Continue observing native transaction and subscription-status updates.
- Size the subscription window to its content. Let translated text wrap naturally; place details and footer actions vertically when they do not fit horizontally. Use the same layout rules across languages, including right-to-left layout, and localize durations and dates without hard-coded line breaks or prices.
- Check expiration whenever a feature starts. Honor a verified billing grace period through its expiration date; do not treat billing retry without grace as active access. Ignore stale refresh responses so an older result cannot restore access after a newer revocation snapshot.
- Keep previously displayed content available after expiration; block new translation and capture work, not Preferences, Quit, purchase, restore, privacy links, or subscription management.

## App Store Metadata and Privacy

- Provide an in-App privacy-policy entry and matching privacy-policy URL in App Store Connect.
- Describe how selected text, screenshots, translations, settings, and purchase state are processed.
- Declare applicable required-reason APIs in the privacy manifest and keep App Store privacy answers consistent with the shipped build.
- Bundle `Resources/PrivacyInfo.xcprivacy` in the App's `Contents/Resources` before signing for every build mode. The current implementation declares no tracking or collected data and uses UserDefaults reason `CA92.1` for its own language and shortcut preferences. Reassess these declarations when data practices change; this manifest does not replace the privacy policy or App Store Connect disclosures.
- Explain Accessibility and Screen Recording permissions before or when they are requested.
- Request each permission only when the shortcut first reaches the feature that needs it. The translation shortcut requests Accessibility when needed; only the screenshot shortcut reaches Screen Recording. Closing the guide leaves permissions untouched. Accessibility copy fallback may replace the clipboard.
- Show a compact guide with the App icon, the permission icon, one short purpose statement, and one primary button. Do not show file paths or technical details.
- For Accessibility, Continue opens the System Settings permission pane. The user enables or manually adds the installed App there; opening Settings does not grant permission.
- Accessibility guidance tells the user to click +, choose Boundless Translator, and enable it. Raw command-line executables do not show permission guidance.
- A missing Accessibility grant opens Accessibility guidance. No selection, clipboard-copy timeout, and cancellation stop quietly. Unexpected selection errors are reported. None of these cases enter screenshot capture.
- Screen Recording requests access after the user continues from its guide. The macOS prompt offers to open the Screen Recording settings pane when needed; the App does not open the pane separately or cover the prompt with another panel.
- Provide localized product metadata, screenshots, support contact information, age rating, review notes, and instructions for testing the shortcut, screenshot flow, and subscription.
- Validate the complete permission, translation, screenshot, trial, purchase, expiration, and restore flows with an App Store-signed TestFlight build before submission.

## Build and Release

- `BoundlessTranslator.xcodeproj` owns the macOS App target, resource membership, build configurations, signing inputs, and archives. `Configurations/BoundlessTranslator.xcconfig` provides the shared App name and bundle identifier for every Boundless Translator target configuration while allowing the E2E build to override that identity without renaming dependency targets. `DirectRelease` builds the subscription-free Developer ID edition for test DMGs; `AppStoreRelease` enables `SUBSCRIPTION_REQUIRED` and builds the App Store edition. `Package.swift` remains the source of SwiftPM unit and component tests.
- Xcode places `Localizable.strings` directly in each root `*.lproj` directory in the App bundle. Both configurations include the App icon, privacy manifest, Sandbox entitlements, and `ITSAppUsesNonExemptEncryption = false`. Only the App Store configuration injects the App Store product ID, privacy-policy URL, category, and copyright.
- `Resources/Info.plist` is the single Xcode App metadata template for both editions. Xcode resolves its build-setting placeholders when it builds the App. Version, build number, developer team, subscription product ID, privacy-policy URL and copyright live in the Xcode project settings.
- `Scripts/DMG/build_app.sh` builds the Developer ID App through Xcode for the test DMG. Its identity settings can be overridden by the E2E runner while the production defaults remain unchanged. The remaining scripts in `Scripts/DMG/` package, verify and notarize either identity through the same DirectRelease workflow; they do not archive, export or upload an App Store build.
- `Scripts/DMG/verify_dmg.sh` mounts the packaged DMG and verifies its signature, layout, Applications shortcut, background, and contained App. It calls `Scripts/DMG/verify_app.sh` once for the contained App, covering resources, linked system frameworks, minimum macOS version, Sandbox entitlements, Developer ID signature, Hardened Runtime, secure timestamp and launch behavior. These checks are not part of the App Store flow.
- `Scripts/Assets/` contains manual App icon and DMG artwork regeneration tools. Release scripts consume the committed files under `Resources/`; they do not regenerate artwork during a release.
- `Scripts/verify.sh` runs free-mode unit and component tests, GUI tests, subscription-mode unit and component tests, app-hosted local StoreKit integration tests, Xcode project configuration checks, and shell workflow tests before code review. Its optional `features` and `subscription` arguments limit a diagnostic run; the normal workflow runs all checks. Local StoreKit uses a test-only product, so it does not charge money or require production credentials.
- On macOS 26.5.2 (25F84) with Xcode 26.6 (17F113), skip the five local StoreKit integration tests before launch and report the reproduced entitlement-query failure. Keep their test code; any different OS or Xcode build executes them again. `Scripts/TestRunners/run_storekit_tests.sh --force` bypasses this environment exception for diagnosis.
- The test runners in `Scripts/TestRunners/` are called by `Scripts/verify.sh`; their shell workflow tests live under `Tests/Scripts/`. Each Swift mode has an isolated build directory and report. Verification builds only test targets and test hosts; it does not build the production App, archive, DMG, or PKG. Failed checks or missing, incomplete, empty, or failing reports stop the workflow. The explicit StoreKit environment skip permits remaining checks and a zero exit status, with a warning that subscription integration remains unverified. A skip is not a passing integration test or release approval.
- Verify the real Apple purchase UI and transactions separately with TestFlight, using the subscription-enabled edition. The free test DMG remains unrestricted for ongoing feature testing; its distribution does not reduce subscription test coverage.
- App signature verification also requires the signed App Sandbox entitlement to be true.
- `Scripts/release_dmg.sh` creates `Build/Boundless Translator-test.dmg` for feature testing. The App has App Sandbox enabled and requires no subscription.
  - Build the real Developer ID App in a private directory.
  - Package and sign the real DMG.
  - Mount the packaged DMG and verify its signature, layout, Applications shortcut, background, and contained App. The contained App checks cover its Developer ID signature, Sandbox entitlement, resources, linked system frameworks, minimum macOS version, and launch behavior.
  - Submit the DMG to Apple for notarization. Attach and validate the ticket, then check Gatekeeper approval.
  - Replace the previous test DMG only after all checks pass. A failure keeps the previous DMG.
  - Keep source version numbers unchanged.
- Fixes before public distribution can reuse the public version. Fixes after distribution use a new public version.
- The App Store release uses the `BoundlessTranslator-AppStore` scheme and `AppStoreRelease` configuration. It does not produce or notarize a DMG.
- Use Xcode Organizer to create the Archive, validate it, create the App Store package and upload it to App Store Connect. Xcode automatic signing uses the configured developer team and the Apple Account signed in under Xcode Settings. The repository contains no separate App Store archive, package, verification or upload shell workflow.
- Set the intended version and a build number higher than every previously uploaded build before archiving. Validate the uploaded build through TestFlight before submitting it for App Review.

## Test Layers

- Unit tests cover deterministic logic without visible windows or system input.
- Component tests cover production components in memory, including state, layout, view hierarchy, and hit testing.
- GUI tests launch the dedicated test host and validate behavior that depends on real AppKit event routing, such as the final pointer cursor.
- End-to-end tests build and notarize `Boundless Translator E2E` through the same DirectRelease signing, DMG packaging, verification, notarization, stapling, and Gatekeeper workflow as the production test DMG. The E2E App is installed at `Build/E2E/Installed` and uses bundle identifier `com.lillard.BoundlessTranslator.e2e`, keeping its settings and macOS permission records separate from the production App. Each test launch configures `Control-Option-Shift-Command-7` and `Control-Option-Shift-Command-8` through preferences so the E2E App can run beside the production App without shortcut conflicts.
- The E2E fixture is a small native editor with two explicit modes. One exposes selected text through Accessibility. The other hides Accessibility selected text while retaining Copy, forcing the production clipboard fallback. The fixture also provides a stable screenshot sample.
- The normal E2E run covers only three core product journeys: Accessibility selected-text translation, clipboard-fallback translation, and screenshot capture followed by Live Text selection and translation. After the fixture is ready, the test process posts the configured shortcuts as CGEvents so each journey enters through the App's registered global shortcuts. Preferences, foreground-window behavior, shortcut registration, and corner cases remain covered by the unit, component, and GUI layers run by `Scripts/verify.sh`.
- `Scripts/run_e2e_tests.sh` is the single entry point for the release-DMG E2E workflow. With no argument, it preserves the E2E App's existing Accessibility and Screen Recording permissions and runs the three core feature tests without manual intervention. With `--from-permission-setup`, it resets only the E2E App's permissions, triggers each shortcut, continues through the App's permission guide so the App opens the corresponding macOS permission flow, and pauses for the tester to approve each protected permission before running the same feature tests. Permission reset is otherwise an on-demand operation.
- Keep `Scripts/run_e2e_tests.sh` separate from `Scripts/verify.sh`. The normal code-change workflow runs verification first and the no-argument E2E workflow second before code review; use `--from-permission-setup` only when the permission-onboarding flow needs coverage.
- Deployment tests cover Xcode project configuration, DMG release-script orchestration, validation failures, and verification workflow ordering without creating production artifacts. The real test-DMG release validates its built App and mounted DMG. Xcode validates the App Store archive before upload.
- Notarization flow tests replace Apple network tools with controlled test executables. A real release performs the final Apple notarization and Gatekeeper checks.
- TestFlight remains the acceptance environment for subscription purchase, restore, expiration, and subscription-management behavior. The subscription-free production and E2E test DMGs cannot cover those StoreKit production flows.

Do not test Apple Translation results, Dictionary contents, OCR accuracy, or other framework-owned behavior.

## Constraints

- macOS 15 or later.
- External text selection depends on the active app's Accessibility or Copy support.
- Screen capture requires Screen Recording permission and the macOS `screencapture` utility.
- Image text recognition depends on VisionKit Live Text.
- Translation languages and quality depend on Apple's Translation framework and installed language resources.
- Speech availability depends on installed macOS voices.
