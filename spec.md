# Boundless Translator Spec

## Product

Boundless Translator is a macOS 15 menu bar app for translating selected text and text recognized in screenshots. It uses one configurable global shortcut to choose the appropriate input and presents translations in a compact floating window.

## Shortcut Flow

When the user presses the translation shortcut (default `Command-Shift-T`):

1. If text is selected in the active image workspace, translate it.
2. Otherwise, try to read selected text from the active app through Accessibility, then through the clipboard fallback.
3. If there is no selection or the clipboard-copy attempt times out, start native macOS interactive region capture. Missing Accessibility permission instead opens permission guidance; cancellation and unexpected errors do not trigger capture.
4. Open the captured image in the image workspace for Live Text selection.
5. The user selects text and presses the same shortcut to translate it.

Only one shortcut request runs at a time. Pause the global shortcut while it is being recorded.

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

## Screenshot Workspace

- Open the captured image in a standard, resizable macOS window titled Screenshot.
- Fit the initial window to the image and the active screen while preserving the image aspect ratio.
- Use VisionKit Live Text for native text recognition and selection.
- Keep the workspace open across app deactivation and translation-window presentation.
- Replace the displayed image after a successful capture; keep the existing image when capture is cancelled or fails.
- Bring the same workspace window to the front after every successful capture, including when it was closed, covered, or minimized.
- Close the focused workspace with Escape or Command-W, including while image text is selected.
- Clear its active selection when the window closes so stale text cannot override later selections.
- Update the workspace background when macOS appearance changes without replacing the image or resetting its selection.
- Use native macOS interactive capture through `screencapture`.
- Control-modified capture is not supported: macOS redirects its result to the clipboard instead of the capture file.
- Request Screen Recording permission when needed. If it is unavailable, explain how to allow it in System Settings > Privacy & Security and that reopening the app may be necessary.
- Present a localized error when capture fails.
- Do not add paste or image-import entry points, custom OCR regions, translation overlays, or image history.

## Preferences

- Open Preferences on first launch and whenever the running app is opened again through Spotlight or Finder.
- Present Preferences on the active screen.
- Present Preferences as one level of labeled rows without section headings.
- Order Preferences as Translate From, Translate To, Keyboard Shortcut, Language, then Usage.
- Group Translate From and Translate To in the first settings card, then the shortcut and Language in the second.
- Use the macOS window background and native grouped-form cards in light and dark appearances, including when appearance changes while Preferences is open.
- Fit all settings without scrolling or unused vertical space. Size the window to accommodate localized labels.
- Configure the interface language independently from translation languages.
- Follow the current macOS interface language by default.
- Allow the user to override the interface with any language localized by macOS, and keep that choice when the macOS language changes.
- Display each interface-language option as its native name followed by its name in the current interface language.
- Show the effective macOS interface language beside System Default.
- Apply interface-language changes immediately to open Preferences and translation windows.
- Configure the default source and target languages.
- Configure one translation shortcut, defaulting to `Command-Shift-T`.
- Preserve saved shortcuts when defaults change; use the defaults only when a saved shortcut is missing or invalid.
- Cancel unfinished shortcut recording when Preferences closes or loses focus, restoring the saved shortcut.
- Open the compact Usage popover from a standard macOS Help button at the bottom right.
- Provide a low-emphasis Quit action at the bottom left when the menu bar item is unavailable.
- Subscription-required builds expose Subscription from Preferences and the menu bar, including when feature access has expired. Free-testing builds do not show purchase controls.

## Architecture

- `Application` composes dependencies and routes the single shortcut to translation or screenshot capture. `Application/Shortcut` owns shortcut registration and persistence. Settings pauses and restores the shortcut during recording.
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
- Every packaged App enables App Sandbox and outgoing-network access. The default Developer ID build is subscription-free; the App Store build requires a subscription. Both use the same sources and bundle identifier, not a separate Sandbox test edition. A successful build does not prove runtime compatibility or App Review eligibility.
- `Resources/Sandbox.entitlements` is the shared source for both distributions. App Store signing adds the matching application and team identifiers to a temporary copy before signing; it does not maintain a separate Sandbox configuration.
- Cross-app selection uses `AXUIElement` with the existing clipboard fallback. It has been exercised in a sandboxed local build; the exact App Store-signed build remains part of normal TestFlight acceptance.
- Preserve the existing Developer ID DMG workflow for development and direct testing. Do not sell the DMG or add a separate DMG payment system in the initial release.
- Add a separate App Store release entry point that produces an App Store-signed archive and uploads it to App Store Connect. Uploading a build does not publish it.

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
- The `SUBSCRIPTION_REQUIRED` compile condition controls access policy independently of packaging format; the App Store build enables it. Missing Store configuration fails closed. Product ID and the public HTTPS privacy-policy URL are injected into the signed bundle, not hard-coded in Swift. Free-testing builds skip subscription checks and StoreKit observation. A paid website edition needs its own purchase provider and is not implemented.
- Use `SubscriptionStoreView` for product display, localized pricing, trial eligibility, purchase confirmation and restore. Use the native transaction and subscription-status updates to refresh verified access; cancellation or a pending purchase does not grant new access.
- Check expiration whenever a feature starts. Honor a verified billing grace period through its expiration date; do not treat billing retry without grace as active access. Ignore stale refresh responses so an older result cannot restore access after a newer revocation snapshot.
- Keep previously displayed content available after expiration; block new translation and capture work, not Preferences, Quit, purchase, restore, privacy links, or subscription management.

## App Store Metadata and Privacy

- Provide an in-App privacy-policy entry and matching privacy-policy URL in App Store Connect.
- Describe how selected text, screenshots, translations, settings, and purchase state are processed.
- Declare applicable required-reason APIs in the privacy manifest and keep App Store privacy answers consistent with the shipped build.
- Bundle `Resources/PrivacyInfo.xcprivacy` in the App's `Contents/Resources` before signing for every build mode. The current implementation declares no tracking or collected data and uses UserDefaults reason `CA92.1` for its own language and shortcut preferences. Reassess these declarations when data practices change; this manifest does not replace the privacy policy or App Store Connect disclosures.
- Explain Accessibility and Screen Recording permissions before or when they are requested.
- Request each permission only when the shortcut first reaches the feature that needs it. Missing Accessibility stops external selection before deciding whether to capture; only no-selection or copy timeout enters capture and checks Screen Recording. Closing the guide leaves permissions untouched. Accessibility copy fallback may replace the clipboard.
- Show a compact guide with the App icon, the permission icon, one short purpose statement, and one primary button. Do not show file paths or technical details.
- For Accessibility, Continue opens the System Settings permission pane. The user enables or manually adds the installed App there; opening Settings does not grant permission.
- Accessibility guidance tells the user to click +, choose Boundless Translator, and enable it. Raw command-line executables do not show permission guidance.
- A missing Accessibility grant must not be treated as absent selected text: the shortcut opens Accessibility guidance and never enters screenshot capture. Cancellation stops the action; other unexpected selection errors are reported. No-selection and clipboard-copy timeouts retain the screenshot fallback.
- Screen Recording requests access after the user continues from its guide. The macOS prompt offers to open the Screen Recording settings pane when needed; the App does not open the pane separately or cover the prompt with another panel.
- Provide localized product metadata, screenshots, support contact information, age rating, review notes, and instructions for testing the shortcut, screenshot flow, and subscription.
- Validate the complete permission, translation, screenshot, trial, purchase, expiration, and restore flows with an App Store-signed TestFlight build before submission.

## Build and Release

- `Scripts/verify_features.sh` runs free-mode unit and component tests, GUI tests, a subscription-free Sandbox App build, signature checks, and DMG deployment tests. Passing it is the gate before `Scripts/release_dmg.sh --test`; it does not create the test DMG.
- `Scripts/verify_subscription.sh` runs subscription-mode unit and component tests, app-hosted local StoreKit integration tests, and App Store build and release tests. Local StoreKit uses a test-only product and App Store release tests simulate signing and upload; they do not charge money, require production credentials, create a production PKG, or upload a build.
- On macOS 26.5.2 (25F84) with Xcode 26.6 (17F113), skip the three local StoreKit integration tests before launch and report the reproduced entitlement-query failure. Keep their test code; any different OS or Xcode build executes them again. `Scripts/Tests/test_storekit.sh --force` bypasses this environment exception for diagnosis.
- `Scripts/verify.sh` runs feature verification followed by subscription verification. Each Swift mode has an isolated build directory and report. Failed checks or missing, incomplete, empty, or failing reports stop the workflow. The explicit StoreKit environment skip permits remaining checks and a zero exit status, with a warning that subscription integration remains unverified. A skip is not a passing integration test or release approval.
- Verify the real Apple purchase UI and transactions separately with TestFlight, using the subscription-enabled edition. The free test DMG remains unrestricted for ongoing feature testing; its distribution does not reduce subscription test coverage.
- App signature verification also requires the signed App Sandbox entitlement to be true.
- `Scripts/release_dmg.sh --test` builds the subscription-free, sandboxed App and saves a signed but unnotarized `Build/Boundless Translator-test.dmg`. It leaves version metadata and versioned release DMGs unchanged; failure preserves the previous test DMG. Users install this DMG for local acceptance testing.
- `Scripts/release_dmg.sh <version>` stages the public version and incremented build number in private metadata, then builds, verifies, packages and signs its own App. Each DMG build uses a private output directory so another build cannot replace its input.
- Release submits the DMG to Apple for notarization, attaches the returned ticket, and checks it with Gatekeeper.
- Versioned DMG releases hold a release lock through version calculation and publication. After notarization succeeds, source metadata is replaced atomically and the versioned DMG is published. A later failure atomically restores the previous metadata and preserves any existing release DMG. Failed rollback retains and reports its recovery copy. Shared App building likewise preserves its recovery directory if restoring the previous App fails.
- Fixes before public distribution can reuse the public version. Fixes after distribution use a new public version.
- The App Store release uses its own signing, archive, validation, and upload workflow. It does not produce or notarize a DMG.
- `Scripts/release_app_store.sh <version> <build-number>` builds the arm64 Store edition and signs an installer package at `Build/AppStore/BoundlessTranslator-<version>-<build-number>.pkg`, leaving source version metadata unchanged. It requires the existing bundle ID, matching App Store certificates/profile, annual product ID, a public HTTPS privacy-policy URL, and the rights holder's copyright notice. The Store bundle uses the Productivity category.
- App Store upload is opt-in with `--upload` and App Store Connect API authentication. Upload does not submit for review or publish.
- Save the signed Store artifacts locally before upload. An upload failure retains them; an incomplete local rollback retains its recovery directory and reports its location.

## Test Layers

- Unit tests cover deterministic logic without visible windows or system input.
- Component tests cover production components in memory, including state, layout, view hierarchy, and hit testing.
- GUI tests launch the dedicated test host and validate behavior that depends on real AppKit event routing, such as the final pointer cursor.
- Deployment tests cover App construction, Developer ID requirements, secure timestamps, system frameworks, minimum macOS version, DMG signing, DMG contents and layout, version updates, and workflow ordering.
- Notarization flow tests replace Apple network tools with controlled test executables. A real release performs the final Apple notarization and Gatekeeper checks.

Do not test Apple Translation results, Dictionary contents, OCR accuracy, or other framework-owned behavior.

## Constraints

- macOS 15 or later.
- External text selection depends on the active app's Accessibility or Copy support.
- Screen capture requires Screen Recording permission and the macOS `screencapture` utility.
- Image text recognition depends on VisionKit Live Text.
- Translation languages and quality depend on Apple's Translation framework and installed language resources.
- Speech availability depends on installed macOS voices.
