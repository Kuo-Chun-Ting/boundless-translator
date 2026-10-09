# Boundless Translator

Boundless Translator translates selected text and screenshots without copying text into another app.

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
3. Press the screenshot shortcut (`Command-Shift-2` by default) to capture a region. When needed, the Screen Recording guide starts Apple's permission flow. Quit and reopen the App if macOS requests it.

### Settings

1. Open **Preferences…** from the menu bar.
2. Set **Translate From**, **Translate To**, and the keyboard shortcuts.
3. Set **Language** for the app interface.

**Language** uses **System Default** by default. It changes the app interface only. It does not change **Translate From** or **Translate To**.

The app interface supports the same languages as macOS. macOS provides translation languages and downloads.

### Translate Text

1. Select text in another app.
2. Press the translation shortcut. The default is `Command-Shift-1`.

### Translate Screenshot

1. Press the screenshot shortcut. The default is `Command-Shift-2`.
2. Select a screen region.
3. Hold the pointer over a word or select text to see its translation.

You can also listen to the original text or look it up in the dictionary.

Both shortcuts can be changed in Settings. Existing saved shortcuts are preserved when the default changes.

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
Scripts/build_dmg_app.sh
```

This uses the `BoundlessTranslator-DMG` Xcode scheme to build and publish `Build/Boundless Translator DMG Test.app`, with App Sandbox enabled and no subscription required. DMG Test releases use this build path; the App Store release uses an Xcode archive.

`release_dmg.sh` normally calls this step for you. Run it directly only when diagnosing the App build before DMG packaging.

Launch that `.app` when testing product behavior. App Sandbox is applied through the signed app's entitlements and enforced when it runs. Running the raw SwiftPM executable does not exercise the same sandboxed app environment. SwiftPM's `--disable-sandbox` option controls its build subprocesses, independently of the shipped App Sandbox entitlement.

### Tests and full verification

For normal code changes:

```sh
Scripts/run_unit_tests.sh
Scripts/run_component_tests.sh
```

GUI, E2E, StoreKit, language support, script and release checks have independent entry points directly under `Scripts/`. See [test commands and requirements](Tests/README.md).

`Scripts/verify.sh` runs **all eight levels**, including real E2E and DMG release verification. It has no partial mode, attempts every level, and returns nonzero if any test fails or is skipped. It can build, notarize and temporarily install a DMG; it does not upload to App Store Connect.

Local StoreKit has a known environment skip on macOS 26.5.2 (25F84) with Xcode 26.6 (17F113). Under the project’s current StoreKit exception, Verify passes when all other levels pass. See [StoreKit testing](app-store/storekit-testing.md). Actual store purchases still require acceptance in TestFlight.

### XCTest UI Automation

Allow GUI/E2E tests to enable UI Automation without repeated password prompts. This setting applies to the whole Mac.

```sh
# Remove the password requirement (run once).
sudo automationmodetool enable-automationmode-without-authentication

# Restore the password requirement.
sudo automationmodetool disable-automationmode-without-authentication
```

### Script Layout

- `Scripts/` contains all test, Verify, release and reset entry points.
- `Scripts/DMG/` contains the private steps used by `release_dmg.sh` to build the App, package the DMG, verify the mounted DMG, and notarize it.
- `Scripts/AppStore/` contains the archive, validation, and upload steps called by `release_app_store.sh`.
- `Scripts/Reset/` contains the shared reset cores called by the edition-specific entry points.
- `Scripts/Shared/` contains the shared Swift test runner and Xcode test-result check. `verify.sh` calls all eight test entries.
- `Scripts/Assets/` contains manual tools for regenerating App and DMG artwork.
- `Tests/Scripts/` contains Shell tests of these workflows. Other `Tests/` directories contain Swift tests, fixtures and configuration, without Shell runners.

### Reset App Data

Run the entry point for the installed edition, without arguments:

| Edition | Reset App data | Reset permissions |
| --- | --- | --- |
| DMG Test | `Scripts/reset_app_data_dmg.sh` | `Scripts/reset_permissions_dmg.sh` |
| App Store / TestFlight | `Scripts/reset_app_data_app_store.sh` | `Scripts/reset_permissions_app_store.sh` |

Data reset quits the selected App and clears its preferences and dismissed tips. It leaves macOS permissions granted. Permission reset quits the selected App and clears its Accessibility and Screen Recording permissions. Reopen it to test permission setup.

The shared cores are `Scripts/Reset/reset_app_data.sh <dmg|app-store|e2e>` and `Scripts/Reset/reset_permissions.sh <dmg|app-store|e2e>`. E2E calls the permission core with `e2e` only in `--from-permission-setup` mode. Normal tests preserve permissions. The E2E runner passes its installed App path; manual entry points use the corresponding App in `/Applications`.

Run resets manually when needed. If data reset reports `Operation not permitted`, give the terminal app Full Disk Access in System Settings and reopen it.

### Create a DMG Test installer

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

- Output: `Build/Boundless Translator DMG Test.dmg`.
- The App has App Sandbox enabled and requires no subscription.
- The script verifies the real built App, signs and mounts the real DMG to verify its contents, gets Apple notarization, attaches the ticket and checks Gatekeeper approval.
- The script replaces the previous DMG Test installer only after all checks pass.

Quit the other edition, then install `Boundless Translator DMG Test.app` into Applications. Authorize Accessibility and Screen Recording once for this new identity; subsequent compatible Developer ID updates should retain those permissions. Use `Scripts/reset_permissions_dmg.sh` to reset this DMG App’s permissions. Test permission setup, selected-text translation, screenshot translation, speech and Lookup.

### Prepare an App Store Release

The App Store edition uses the same Xcode App target, Swift sources and Sandbox settings, with subscription access enabled. It adds **Subscription…** to the menu and Preferences, using Apple's purchase and restore interface. Direct distribution produces the subscription-free `Boundless Translator DMG Test` (`com.lillard.BoundlessTranslator.dmgtest`). TestFlight and App Store keep `Boundless Translator` (`com.lillard.BoundlessTranslator`). Each edition has separate settings and permission records.

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
