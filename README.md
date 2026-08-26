# Boundless Translator

Boundless Translator is a macOS translation companion for understanding text across apps and, eventually, anywhere on your screen.

The app runs from the menu bar. Select text in a compatible app, press `Command-Shift-T`, and review the translation in a compact floating window.

## Current Features

- Translate selected text with a global keyboard shortcut.
- Read selections through macOS Accessibility, with a clipboard fallback for compatible apps.
- Detect the source language and request confirmation when confidence is low.
- Translate with Apple's Translation framework.
- Change the source or target language for the current translation without changing the defaults.
- Keep a translation visible with a pinnable, resizable result window.
- Configure default source and target languages from the menu bar.

## Roadmap

- Dictionary results with definitions, pronunciation, multiple meanings, and examples.
- Screenshot and OCR translation for text that cannot be selected or copied.

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

Use the language menus in the result window to retry that translation with a different language pair. Pin the window when you want the result to remain visible while working elsewhere.

## Development

Clone the repository and run the test suite:

```bash
git clone https://github.com/Kuo-Chun-Ting/boundless-translator.git
cd boundless-translator
swift test
```

Build the release app with a code-signing identity available in your Keychain:

```bash
BOUNDLESS_TRANSLATOR_SIGNING_IDENTITY="Your Signing Identity" Scripts/build_app.sh
```

The app is created at:

```text
Build/Boundless Translator.app
```

## Current Limitations

- Selected-text access depends on what the active app exposes through macOS Accessibility or its response to the Copy command.
- Very short or ambiguous text may require manual source-language confirmation.
- Translation quality and language availability depend on Apple's Translation framework and installed language resources.
