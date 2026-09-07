# Boundless Translator

Most translation apps make you copy text into another app. Boundless Translator translates selected text in other Mac apps with one global shortcut.

## Features

- Translate selected text from other apps.
- Translate text in screenshots.
- Look up selected words and phrases.
- Read text aloud.
- Use the app in different languages.

## Prerequisites

- macOS 15 or later
- Accessibility permission
- Screen Recording permission for screenshots
- Downloaded translation languages

## Usage

### First Use

1. Launch Boundless Translator.
2. Open **System Settings → Privacy & Security → Accessibility**.
3. Allow Boundless Translator.

### Settings

1. Open **Preferences…** from the menu bar.
2. Set **Translate From**, **Translate To**, and the **Translate Selected Text** and **Capture Screen Region** shortcuts.
3. Set **Language** for the app interface.

**Language** uses **System Default** by default. It changes the app interface only. It does not change **Translate From** or **Translate To**.

The app interface supports the same languages as macOS. macOS provides translation languages and downloads.

### Translate Text

1. Select text in another app.
2. Press the **Translate Selected Text** shortcut. The default is `Option-Shift-E`.

### Translate Screenshot

1. Press the **Capture Screen Region** shortcut. The default is `Option-Shift-R`.
2. Select a screen region.
3. Select text in the screenshot window.
4. Press the **Translate Selected Text** shortcut. The default is `Option-Shift-E`.

Both shortcuts can be changed in Settings. Existing saved shortcuts are preserved when the defaults change.

If prompted, allow Screen Recording for Boundless Translator in **System Settings → Privacy & Security**, then try again. You may need to quit and reopen the app.

Release Control before finishing the selection: macOS uses it to send the capture to the clipboard instead of opening it in the app.

## Build and Release

### Build the App

Building requires:

- Xcode with Swift 6.2
- The signing certificate and matching private key in your Mac's Keychain, as configured in `Scripts/Tools/code_signing.conf`

```bash
git clone https://github.com/Kuo-Chun-Ting/boundless-translator.git
cd boundless-translator
Scripts/Tools/build_app.sh
```

This builds and signs `Build/Boundless Translator.app`. Open it to run the app.

### Release a DMG

Release builds the App and packages it as a DMG for sharing. Apple notarization checks the software before distribution.

#### One-time Setup

Install the DMG packaging tool:

```bash
brew install create-dmg
```

Save the Apple account credentials used to submit the DMG to Apple. Replace the placeholders with your Apple Account email and Developer Team ID. Enter an app-specific password when prompted:

```bash
xcrun notarytool store-credentials "BoundlessTranslatorNotary" \
  --apple-id "<apple-id>" \
  --team-id "<team-id>"
```

#### Create a Release

Run from the project directory with the version you want to release:

```bash
Scripts/release_dmg.sh 0.2.0
```

The finished DMG is saved at `Build/Boundless Translator-0.2.0.dmg` after Apple notarization and Gatekeeper checks pass. Install this DMG to test it before sharing.
