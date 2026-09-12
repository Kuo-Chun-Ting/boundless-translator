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

This builds and signs `Build/Boundless Translator.app`, with App Sandbox enabled and no subscription required.

Launch that `.app` when testing product behavior. App Sandbox is applied through the signed app's entitlements and enforced when it runs. Running the raw SwiftPM executable does not exercise the same sandboxed app environment. SwiftPM's `--disable-sandbox` option controls its build subprocesses, independently of the shipped App Sandbox entitlement.

### Verify

```bash
Scripts/verify_features.sh
Scripts/verify_subscription.sh
Scripts/verify.sh
```

`verify_features.sh` checks the unrestricted edition, GUI behavior, the Sandbox-enabled App, and the DMG workflow. Run it before creating a friend-test DMG. `verify_subscription.sh` checks subscription-mode code, local StoreKit transactions, and the App Store package workflow. `verify.sh` runs both in that order. These commands do not create release artifacts, make real purchases, or upload builds.

On macOS 26.5.2 (25F84) with Xcode 26.6 (17F113), the three local StoreKit integration tests are temporarily skipped because purchase succeeds but entitlement queries return empty. Other checks still run; a successful exit with this warning means those checks passed, **not that subscription integration is verified**. Changing either OS or Xcode build re-enables the tests. Run `Scripts/Tests/test_storekit.sh --force` to retry on the affected environment. See [StoreKit testing](app-store/storekit-testing.md).

This needs a macOS desktop session and the build/signing prerequisites above. Actual Apple purchase, trial, renewal, expiration, refund and restore flows are tested separately in the subscription-enabled TestFlight edition, where test purchases incur no charges. See [Apple's testing overview](https://developer.apple.com/documentation/storekit/testing-at-all-stages-of-development-with-xcode-and-the-sandbox).

### Create a Test DMG

```bash
Scripts/release_dmg.sh --test
```

Requires `create-dmg` (`brew install create-dmg`). The output is `Build/Boundless Translator-test.dmg`: Sandbox enabled, no subscription, Developer ID signed, **not notarized**. This command does not change version numbers, contact Apple's notarization service, or overwrite versioned release DMGs. Gatekeeper may require an override when installing this unnotarized test artifact.

Install the App from the DMG before testing. Quit other copies so they do not compete for the shortcut. The Accessibility guide opens its System Settings pane; click **+**, choose the installed Boundless Translator App, and enable it. The Screen Recording guide starts the native macOS authorization flow; use the prompt's **Open System Settings** button when needed. Test external text selection, screenshot capture, Live Text, translation, speech, and Lookup.

The test and versioned DMGs use the same bundle identifier and share settings. They are not separate installations.

### Release a DMG

Release builds the same Sandbox-enabled, subscription-free App and packages it as a notarized DMG for sharing with testers. It is not a paid website edition.

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

### Prepare an App Store Release

The App Store edition uses the same Swift sources and Sandbox settings, with subscription access enabled. It adds **Subscription…** to the menu and Preferences, using Apple's purchase and restore interface. A paid website DMG requires a separate payment and subscription-verification provider; it is not implemented.

Complete the account, signing, product and public privacy-policy setup in the [App Store implementation plan](app-store/implementation-plan.md). Then provide the configuration as environment variables in your terminal:

```bash
export BOUNDLESS_TRANSLATOR_APP_STORE_TEAM_ID="<team-id>"
export BOUNDLESS_TRANSLATOR_APP_STORE_SIGNING_IDENTITY="<App Store app certificate name>"
export BOUNDLESS_TRANSLATOR_INSTALLER_SIGNING_IDENTITY="<Mac Installer Distribution certificate name>"
export BOUNDLESS_TRANSLATOR_APP_STORE_PROVISIONING_PROFILE="<absolute-profile-path>"
export BOUNDLESS_TRANSLATOR_SUBSCRIPTION_PRODUCT_ID="<annual-product-id>"
export BOUNDLESS_TRANSLATOR_PRIVACY_POLICY_URL="<published-https-privacy-policy-url>"
export BOUNDLESS_TRANSLATOR_APP_STORE_COPYRIGHT="<copyright notice with the actual rights holder>"
Scripts/release_app_store.sh 1.0 1
```

Use your intended public version and a build number higher than any previously uploaded build. This creates `Build/AppStore/BoundlessTranslator-1.0-1.pkg` and the matching `.app`, without modifying `Resources/Info.plist` or uploading. The first Store edition targets Apple silicon (`arm64`), not Intel. Its bundle ID is `com.lillard.BoundlessTranslator`; the provisioning profile and App Store Connect record must match it.

Uploading additionally requires App Store Connect API key authentication:

```bash
cp .env.example .env.local
# Fill the Key ID and Issuer ID in .env.local.
Scripts/upload_app_store.sh Build/AppStore/BoundlessTranslator-1.0-1.pkg
```

`.env.local` is ignored by Git, and values already exported in the shell take precedence over it. Keep the API private key outside this repository in `~/.appstoreconnect/private_keys/`; do not put passwords or private keys in project files. The upload script validates and uploads the existing PKG without rebuilding it. Uploading makes the build available for processing in App Store Connect; it does not submit for review or publish it.

The upload script does not modify the local PKG. If local release publishing cannot restore previous files after a failure, the release script prints the recovery directory instead of deleting it.

The `1.0 (1)` App Store `.app` and PKG have been built and locally verified with the production certificates and provisioning profile. Upload processing and purchase/restore flows still require validation with the exact TestFlight build. See the [App Store implementation plan](app-store/implementation-plan.md).
