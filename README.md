# Boundless Translator

Boundless Translator is a macOS translation companion for understanding text across apps and, eventually, anywhere on your screen.

The app runs from the menu bar. Select text in a compatible app, press `Command-Shift-T`, and review the translation in a compact floating window.

## Current Features

- Translate selected text with a global keyboard shortcut.
- Open clipboard images and select recognized text with macOS Live Text.
- Read selections through macOS Accessibility, with a clipboard fallback for compatible apps.
- Detect the source language and request confirmation when confidence is low.
- Translate with Apple's Translation framework.
- Change the source or target language for the current translation without changing the defaults.
- Read the source text or translation aloud with supported macOS voices.
- Keep a translation visible with a pinnable, resizable result window.
- Select a word or phrase in the source text and open Apple's Dictionary overlay.
- Configure default languages and the global shortcut from Preferences.

## How It Works

```text
Selected text
    ↓
Selection readers
    ↓
Source language identification
    ↓
Apple Translation framework
    ↓
Floating translation window
```

The code is divided by responsibility:

- `Selection` reads text through Accessibility and clipboard-based fallback strategies.
- `LanguageIdentification` resolves automatic detection and low-confidence cases.
- `Translation` owns translation requests, configuration, state, and failures.
- `Presentation` manages the translation window, layout, language controls, and pin behavior.
- `Settings`, `Shortcut`, and `Application` handle preferences, the global shortcut, and app lifecycle.

These boundaries keep platform integrations separate from translation and UI logic, so each layer can be tested independently.

## Requirements

- macOS 15 or later
- Xcode with Swift 6.2
- Accessibility permission for reading or copying selected text from other apps
- Downloaded translation languages when required by macOS

## Usage

1. Launch Boundless Translator.
2. Allow it under **System Settings → Privacy & Security → Accessibility**.
3. Choose default languages from the menu bar under **Preferences…**.
4. Select text in another app.
5. Press `Command-Shift-T`.

Use the language menus in the result window to retry that translation with a different language pair. Select source text and click the book button to open Apple's Dictionary overlay. Pin the window when you want the result to remain visible while working elsewhere.

To translate text in an image, copy the image and press the shortcut with no text selected. Select text in the Live Text window, then press the shortcut again.

## Development

Clone the repository and run the tests:

```bash
git clone https://github.com/Kuo-Chun-Ting/boundless-translator.git
cd boundless-translator
swift test
```

### App icon

Regenerate the ICNS after changing its source PNG, then select the icon used by the app:

```bash
Scripts/generate_brand_icons.swift .
Scripts/replace_app_icon.sh Design/BoundlessTranslator-Ghost-AppIcon-Transparent.icns
```

### Build and deploy

Build the release app, verify it, then deploy it to `/Applications`:

```bash
Scripts/build_app.sh
Scripts/deploy_app.sh
```

The release app is created at `Build/Boundless Translator.app`.

Package the latest release app as a compressed disk image:

```bash
brew install create-dmg
Scripts/package_dmg.sh
```

The disk image is created at `Build/Boundless Translator.dmg`. It contains the App and an `Applications` shortcut for drag-to-install distribution. The first styled build may ask for permission to let `osascript` control Finder. Packaging preserves the App's existing signature; it does not sign or notarize the App.


## Current Limitations

- Selected-text access depends on what the active app exposes through macOS Accessibility or its response to the Copy command.
- Very short or ambiguous text may require manual source-language confirmation.
- Translation quality and language availability depend on Apple's Translation framework and installed language resources.
