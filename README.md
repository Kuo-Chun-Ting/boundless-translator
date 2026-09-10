# Boundless Translator

Most translation apps make you copy text into another app. Boundless Translator translates selected text or screen content with one global shortcut.

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
2. Set **Translate From**, **Translate To**, and the keyboard shortcut.
3. Set **Language** for the app interface.

**Language** uses **System Default** by default. It changes the app interface only. It does not change **Translate From** or **Translate To**.

The app interface supports the same languages as macOS. macOS provides translation languages and downloads.

### Translate Text

1. Select text in another app.
2. Press the translation shortcut. The default is `Command-Shift-T`.

### Translate Screenshot

1. Press the translation shortcut without selecting text. The default is `Command-Shift-T`.
2. Select a screen region.
3. Select text in the screenshot window.
4. Press the same shortcut to translate it.

The shortcut can be changed in Settings. Existing saved shortcuts are preserved when the default changes.

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

### Verify

```bash
Scripts/verify_features.sh
Scripts/verify_subscription.sh
Scripts/verify.sh
```

`verify_features.sh` checks the unrestricted edition, GUI behavior, the App signature, and the DMG workflow. Run it before creating a friend-test DMG. `verify_subscription.sh` checks subscription-mode code, local StoreKit transactions, and the verification scripts. `verify.sh` runs both in that order. These commands do not create release artifacts, make real purchases, or upload builds.

On macOS 26.5.2 (25F84) with Xcode 26.6 (17F113), the three local StoreKit integration tests are temporarily skipped because purchase succeeds but entitlement queries return empty. Other checks still run; a successful exit with this warning means those checks passed, **not that subscription integration is verified**. Changing either OS or Xcode build re-enables the tests. Run `Scripts/Tests/test_storekit.sh --force` to retry on the affected environment. See [StoreKit testing](AppStore/StoreKitTesting.md).

This needs a macOS desktop session and the build/signing prerequisites above. Actual Apple purchase, trial, renewal, expiration, refund and restore flows are tested separately in the subscription-enabled TestFlight edition, where test purchases incur no charges. See [Apple's testing overview](https://developer.apple.com/documentation/storekit/testing-at-all-stages-of-development-with-xcode-and-the-sandbox).

### Test App Sandbox Compatibility

```bash
Scripts/Tools/build_app.sh --sandbox
```

This builds `Build/Sandbox/Boundless Translator.app` with App Sandbox enabled and a separate bundle identifier, `com.lillard.BoundlessTranslator.Sandbox`. It does not replace the normal build or share its saved settings and permissions.

Quit other copies of Boundless Translator before testing so they do not compete for the shortcut. Grant permissions to the Sandbox copy only when prompted or needed for the test. Test external text selection, screenshot capture, Live Text, translation, speech, and Lookup; a successful build alone does not establish compatibility.

This Developer ID-signed build is a local compatibility test, not an App Store or TestFlight release.

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
