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
- Downloaded translation languages

## Usage

### First Use

1. Launch Boundless Translator.
2. Open **System Settings → Privacy & Security → Accessibility**.
3. Allow Boundless Translator.

### Settings

1. Open **Preferences…** from the menu bar.
2. Set **Translate From**, **Translate To**, and the keyboard shortcut.
3. Set **Language** for the app interface.

**Language** uses **System Default** by default. It changes the app interface only. It does not change **Translate From** or **Translate To**.

The app interface supports the same languages as macOS. macOS provides translation languages and downloads.

### Translate Text

1. Select text in another app.
2. Press the keyboard shortcut. The default is `Command-Shift-T`.

### Translate Screenshot

1. Copy a screenshot.
2. Make sure no text is selected.
3. Press the keyboard shortcut.
4. Select text in the screenshot window.
5. Press the keyboard shortcut again.

## Build and Deploy

### Development

Xcode with Swift 6.2 is required.

```bash
git clone https://github.com/Kuo-Chun-Ting/boundless-translator.git
cd boundless-translator
swift test
swift build
```

### Release

Release scripts require the maintainer's signing certificate.

```bash
Scripts/build_app.sh
Scripts/verify_app.sh "Build/Boundless Translator.app"
Scripts/deploy_app.sh
```

### DMG

```bash
brew install create-dmg
Scripts/package_dmg.sh
```

The app is created at `Build/Boundless Translator.app`. The DMG is created at `Build/Boundless Translator.dmg`.

Users may see a macOS warning when they open this DMG.
