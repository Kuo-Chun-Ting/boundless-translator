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

1. Install Boundless Translator from the DMG, then launch the installed App.
2. Select text in another app and press the shortcut. When needed, the Accessibility guide opens **System Settings → Privacy & Security → Accessibility**. Enable Boundless Translator; if it is missing, click **+** and choose the installed App.
3. With no text selected, use the shortcut to capture a region. When needed, the Screen Recording guide starts Apple's permission flow. Quit and reopen the App if macOS requests it.

### Settings

1. Open **Preferences…** from the menu bar.
2. Set **Translate From**, **Translate To**, and the keyboard shortcut.
3. Set **Language** for the app interface.

**Language** uses **System Default** by default. It changes the app interface only. It does not change **Translate From** or **Translate To**.

The app interface supports the same languages as macOS. macOS provides translation languages and downloads.

### Translate Text

1. Select text in another app.
2. Press the translation shortcut. The default is `Command-Shift-1`.

### Translate Screenshot

1. Press the screenshot shortcut. The default is `Command-Shift-2`.
2. Select a screen region.
3. Select text in the screenshot window.
4. Press the translation shortcut to translate it.

The shortcut can be changed in Settings. Existing saved shortcuts are preserved when the default changes.

If prompted, allow Screen Recording for Boundless Translator in **System Settings → Privacy & Security**, then try again. You may need to quit and reopen the app.

Release Control before finishing the selection: macOS uses it to send the capture to the clipboard instead of opening it in the app.

## Build and Release

### Build the App

Building requires:

- Xcode with Swift 6.2
- The signing certificate and matching private key in your Mac's Keychain, as configured in `Scripts/DMG/signing.conf`

```bash
git clone https://github.com/Kuo-Chun-Ting/boundless-translator.git
cd boundless-translator
Scripts/DMG/build_app.sh
```

This uses the `BoundlessTranslator-Direct` Xcode scheme to build and publish `Build/Boundless Translator.app`, with App Sandbox enabled and no subscription required. Test DMG releases use this build path; the App Store release uses an Xcode archive.

`release_dmg.sh` normally calls this step for you. Run it directly only when diagnosing the App build before DMG packaging.

Launch that `.app` when testing product behavior. App Sandbox is applied through the signed app's entitlements and enforced when it runs. Running the raw SwiftPM executable does not exercise the same sandboxed app environment. SwiftPM's `--disable-sandbox` option controls its build subprocesses, independently of the shipped App Sandbox entitlement.

### Verify

```bash
Scripts/verify.sh
```

`verify.sh` checks free-mode code, GUI behavior, subscription-mode code, local StoreKit transactions, Xcode project settings, and shell workflows. Pass `features` or `subscription` only when diagnosing one side; the normal workflow runs everything. It builds only test targets and test hosts; it does not build the production App or create a DMG, archive, or PKG.

On macOS 26.5.2 (25F84) with Xcode 26.6 (17F113), the three local StoreKit integration tests are temporarily skipped because purchase succeeds but entitlement queries return empty. Other checks still run; a successful exit with this warning means those checks passed, **not that subscription integration is verified**. Changing either OS or Xcode build re-enables the tests. Run `Scripts/TestRunners/run_storekit_tests.sh --force` to retry on the affected environment. See [StoreKit testing](app-store/storekit-testing.md).

GUI and StoreKit integration tests need a macOS desktop session. They do not need the production signing certificate. Actual Apple purchase, trial, renewal, expiration, refund and restore flows are tested separately in the subscription-enabled TestFlight edition, where test purchases incur no charges. See [Apple's testing overview](https://developer.apple.com/documentation/storekit/testing-at-all-stages-of-development-with-xcode-and-the-sandbox).

### Script Layout

- `Scripts/verify.sh`, `Scripts/release_dmg.sh`, and `Scripts/reset_test_permissions.sh` are the commands run directly during normal development.
- `Scripts/DMG/` contains the private steps used by `release_dmg.sh` to build the App, package the DMG, verify the mounted DMG, and notarize it.
- `Scripts/TestRunners/` contains test runners called by `verify.sh`.
- `Scripts/Assets/` contains manual tools for regenerating App and DMG artwork.
- `Tests/Scripts/` tests the shell workflows themselves.

### Create a Test DMG

Run this setup once. Replace the placeholders with your Apple Account email and Developer Team ID:

```bash
brew install create-dmg
xcrun notarytool store-credentials "BoundlessTranslatorNotary" \
  --apple-id "<apple-id>" \
  --team-id "<team-id>"
```

Enter an app-specific password when prompted. The credentials are stored in Keychain.

Build the DMG:

```bash
Scripts/release_dmg.sh
```

- Output: `Build/Boundless Translator-test.dmg`.
- The App has App Sandbox enabled and requires no subscription.
- The script verifies the real built App, signs and mounts the real DMG to verify its contents, gets Apple notarization, attaches the ticket and checks Gatekeeper approval.
- The script replaces the previous test DMG only after all checks pass.

Quit other copies of the App, then install from this DMG. Test permission setup, selected-text translation, screenshot translation, speech and Lookup.

### Prepare an App Store Release

The App Store edition uses the same Xcode App target, Swift sources and Sandbox settings, with subscription access enabled. It adds **Subscription…** to the menu and Preferences, using Apple's purchase and restore interface. Direct distribution currently produces only the subscription-free test DMG.

Complete the account, signing, product and public privacy-policy setup in the [App Store implementation plan](app-store/implementation-plan.md).

Sign in once under **Xcode → Settings → Apple Accounts** with the Apple Account that belongs to the App Store Connect team. Xcode stores that session in the macOS Keychain and uses it to manage signing certificates and provisioning profiles; do not put an Apple Account password in this repository or a shell script.

The `AppStoreRelease` build configuration contains the developer team, subscription product ID, privacy-policy URL and copyright used by the App Store edition. Before archiving, set the intended **Version** and a **Build** number higher than every previously uploaded build in the Xcode target settings.

1. Select the **BoundlessTranslator-AppStore** scheme and **Any Mac (Apple Silicon)** destination.
2. Choose **Product → Archive**. Xcode builds the subscription-enabled App, signs it with automatic signing and opens the archive in Organizer.
3. In Organizer, choose **Validate App** and resolve every reported issue.
4. Choose **Distribute App → App Store Connect**. Xcode creates the App Store package and uploads it to App Store Connect.
5. Wait for Apple processing, then verify the exact build in TestFlight before submitting it for review.

The first Store edition targets Apple silicon (`arm64`). Its bundle ID is `com.lillard.BoundlessTranslator`; the App Store Connect record and signing team must match it. Uploading a build does not submit it for review or publish it.

Treat the Xcode Archive, generated App Store package and processed TestFlight build as one release chain. Test the exact uploaded build before submission. Track the remaining App Store Connect and TestFlight work in the [App Store implementation plan](app-store/implementation-plan.md).
