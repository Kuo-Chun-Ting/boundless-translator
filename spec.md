# Boundless Translator Spec

## Product

Boundless Translator is a macOS 15 menu bar app for translating selected text and text recognized in clipboard images. It uses one configurable global shortcut and presents results in a compact floating window.

## Shortcut Flow

When the user presses the configured shortcut:

1. If text is selected in the active image workspace, translate it.
2. Otherwise, try to read selected text from the active app through Accessibility, then through the clipboard fallback.
3. Otherwise, if the clipboard contains an image, open it in the image workspace.
4. If neither text nor an image is available, do nothing.

Only one shortcut request runs at a time.

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

## Clipboard Image Workspace

- Open the clipboard image in a standard, resizable macOS window when no text selection is available.
- Fit the initial window to the image and the active screen while preserving the image aspect ratio.
- Use VisionKit Live Text for native text recognition and selection.
- Keep the workspace open across app deactivation and translation-window presentation.
- Replace the displayed image when the shortcut is used with a newer clipboard image.
- Clear its active selection when the window closes so stale text cannot override later selections.
- Do not add custom OCR regions, translation overlays, screenshot capture, or image history.

## Preferences

- Open Preferences on first launch and whenever the running app is opened again through Spotlight or Finder.
- Present Preferences on the active screen.
- Present Preferences as one level of labeled rows without section headings.
- Order Preferences as Translate From, Translate To, Keyboard Shortcut, Language, then Usage.
- Group Translate From and Translate To in the first settings card, then Keyboard Shortcut and Language in the second.
- Use macOS semantic colors to distinguish the window background from settings cards in light and dark appearances.
- Fit all settings without scrolling or unused vertical space.
- Configure the interface language independently from translation languages.
- Follow the current macOS interface language by default.
- Allow the user to override the interface with any language localized by macOS, and keep that choice when the macOS language changes.
- Display each interface-language option as its native name followed by its name in the current interface language.
- Show the effective macOS interface language beside System Default.
- Apply interface-language changes immediately to open Preferences and translation windows.
- Configure the default source and target languages.
- Configure the single global translation shortcut, defaulting to `Command-Shift-T`.
- Open the compact Usage popover from a standard macOS Help button at the bottom right.
- Provide a low-emphasis Quit action at the bottom left when the menu bar item is unavailable.

## Architecture

- `Application` composes dependencies and routes shortcut actions.
- `Selection` reads external text through Accessibility and clipboard fallback strategies.
- `ImageWorkspace` owns clipboard image input, Live Text selection, and its persistent window.
- `LanguageIdentification` resolves automatic source-language detection and confirmation.
- `Translation` owns requests, configuration, execution, state, and failures.
- `Speech` owns language support and source or target playback state.
- `Presentation` owns translation-window layout, lifecycle, dismissal, pinning, language controls, and Lookup presentation.
- `Settings` owns Preferences composition and persisted translation defaults.
- `Settings` owns the persisted interface-language preference and resolves whether the interface follows macOS or uses an explicit language.
- Interface localization covers every language localized by macOS and remains independent from Translation framework language availability.
- Usage explains that interface-language coverage and translation-language availability follow macOS support.
- `Shortcut` owns shortcut recording, persistence, and global registration.

Platform adapters remain behind focused protocols so application flow, state, and UI behavior can be tested without invoking external apps or Apple framework internals.

## Build and Release

- `Scripts/verify.sh` runs all automated tests, builds the App, and verifies its signature. DMGs created by tests are temporary.
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
- Image text recognition depends on VisionKit Live Text.
- Translation languages and quality depend on Apple's Translation framework and installed language resources.
- Speech availability depends on installed macOS voices.
