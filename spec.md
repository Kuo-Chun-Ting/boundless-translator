# Boundless Translator Spec

## Product

Boundless Translator is a macOS 15 menu bar app for translating selected text and text recognized in screenshots. It has independently configurable global shortcuts for translating selected text and capturing a screen region, and presents translations in a compact floating window.

## Shortcut Flow

When the user presses Translate Selected Text (default `Option-Shift-E`):

1. If text is selected in the active image workspace, translate it.
2. Otherwise, try to read selected text from the active app through Accessibility, then through the clipboard fallback.
3. If no text is selected, do nothing.

When the user presses Capture Screen Region (default `Option-Shift-R`):

1. Start the native macOS interactive region capture.
2. Open the captured image in the image workspace for Live Text selection.
3. The user selects text and presses Translate Selected Text to translate it.

Only one shortcut request runs at a time. Pause both global shortcuts while either shortcut is being recorded.

## Translation

- Translate with Apple's Translation framework.
- Use the configured source language or detect it automatically.
- Ask the user to choose a source language when detection confidence is insufficient.
- Use the configured target language by default.
- Allow the source and target languages to change for the current translation without changing saved defaults.
- Preserve the current request for retry after a recoverable failure.

## Translation Window

- Show source and translated text in two equal, selectable panels.
- Grow the window for longer content up to the available screen size, then scroll overflowing text.
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
- Order Preferences as Translate From, Translate To, Translate Selected Text, Capture Screen Region, Language, then Usage.
- Group Translate From and Translate To in the first settings card, then both shortcuts and Language in the second.
- Use the macOS window background and native grouped-form cards in light and dark appearances, including when appearance changes while Preferences is open.
- Fit all settings, including both shortcut rows, without scrolling or unused vertical space. Size the window to accommodate localized labels.
- Configure the interface language independently from translation languages.
- Follow the current macOS interface language by default.
- Allow the user to override the interface with any language localized by macOS, and keep that choice when the macOS language changes.
- Display each interface-language option as its native name followed by its name in the current interface language.
- Show the effective macOS interface language beside System Default.
- Apply interface-language changes immediately to open Preferences and translation windows.
- Configure the default source and target languages.
- Configure the translation and capture shortcuts independently, defaulting to `Option-Shift-E` and `Option-Shift-R` respectively.
- Preserve saved shortcuts when defaults change; use the defaults only when a saved shortcut is missing or invalid.
- Reject a shortcut already assigned to the other action and keep the saved assignments.
- Cancel unfinished shortcut recording when Preferences closes or loses focus, restoring the saved shortcut.
- Open the compact Usage popover from a standard macOS Help button at the bottom right.
- Provide a low-emphasis Quit action at the bottom left when the menu bar item is unavailable.

## Architecture

- `Application` composes dependencies and routes translation and screenshot actions. `Application/Shortcut` owns both shortcut registrations, persistence, and duplicate validation. Settings pauses and restores both shortcuts during recording.
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
- Interface localization covers every language localized by macOS and remains independent from Translation framework language availability.
- Usage explains that interface-language coverage and translation-language availability follow macOS support.

These directories belong to one executable target, not separate Swift packages. Platform adapters remain behind focused protocols or injected operations so application flow, state, and UI behavior can be tested without invoking external apps or Apple framework internals. The only production translation engine is Apple; this architecture does not add billing or an engine-selection interface.

## Build and Release

- `Scripts/verify.sh` runs all automated tests, requires a complete passing Swift Testing report, builds the App, and verifies its signature. DMGs created by tests are temporary.
- `Scripts/release_dmg.sh <version>` sets the public version and increments the build number. It builds and verifies the App, then packages and signs the DMG.
- Release submits the DMG to Apple for notarization, attaches the returned ticket, and checks it with Gatekeeper.
- Only a successful release saves `Build/Boundless Translator-<version>.dmg`. A failed release restores the previous version metadata and preserves any existing release DMG.
- Fixes before public distribution can reuse the public version. Fixes after distribution use a new public version.

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
