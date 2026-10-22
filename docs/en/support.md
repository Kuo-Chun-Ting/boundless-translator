---
layout: page
kind: support
title: Support
lang: en
permalink: /en/support/
---

## Before you start

- Requires Apple silicon (M1 or later) and macOS 15 or later. Intel Macs are not supported.
- Translation in the Mac App Store edition requires an annual subscription. Check the purchase screen for pricing and trial eligibility.

## Initial setup

- Open the app and choose Translate From and Translate To in Preferences.
  - If the subscription screen appears, purchase or restore your subscription.
- Select text in another app and press Command-Shift-1. Follow the guide to allow Accessibility.
  - If the app is missing from the list, click “+” and add the installed app.
  - After granting permission, return to the original app, select the text again, and press the shortcut.
- If macOS asks to download translation resources, connect to the internet and let the downloads finish before translating.
  - You can also manage downloads in System Settings → General → Language & Region → Translation Languages. See [Apple’s language download instructions](https://support.apple.com/guide/mac-help/mchldd8b3c15/mac).
- Press Command-Shift-2 and follow the guide to allow Screen Recording.
  - Quit and reopen the app if macOS requests it.
  - Press the shortcut again to capture an area.
- To look up words, open the Dictionary app on your Mac, choose Dictionary → Settings, select the dictionary sources you need, and wait for the downloads to finish before looking up a word.
  - See [Apple’s Dictionary User Guide](https://support.apple.com/guide/dictionary/dic34880/mac).

## How to use

These are the default shortcuts. Change them in Preferences, or click “?” for instructions.

- Select text in another app and press Command-Shift-1 to translate.
- If you cannot select text directly, press Command-Shift-2 to capture an area.
  - Hover over a word or select text in the screenshot to see its translation.
- Select a word or phrase in the translation window’s source text and click the book icon to look it up.
- Click a Read Aloud button to hear the source text or translation. Screenshot translation cards also have buttons for dictionary lookup and reading the source text aloud.

## Common questions

- Image recognition takes a long time:
  - macOS may need to compile a recognition model, preparing it to run on your Mac. Recognition uses several models, so you may need to wait again when a model that has not yet been compiled is used.
  - If “Preparing recognition models…” appears, wait for it to disappear before interacting.
- Auto Detect cannot identify the source language:
  - [Apple’s translation feature](https://developer.apple.com/documentation/translation/translationsession/configuration/source) identifies the language from the original text. If it is unclear, it asks you to choose a language.
  - If the prompt keeps appearing, change Translate From from Auto Detect to the language of the original text.
- Language settings in Preferences and the translation window: Preferences saves the default languages for new windows. Changing languages in a translation window affects only that window and does not change the defaults.

## Supported languages

Boundless Translator uses macOS for translation and text recognition. Available languages vary by macOS version.

- **Selected-text translation:** Supports the languages macOS can translate. See [Apple’s translation language list](https://www.apple.com/macos/feature-availability/#translate-system-wide-translation).
  - If macOS asks you to download language resources, follow [Initial setup](#initial-setup).
  - Some languages require Apple Intelligence. Turn it on in System Settings → Apple Intelligence & Siri and wait for the models to finish downloading. See [Apple’s requirements](https://support.apple.com/121115).
- **Screenshot translation:** The language of the text in the image must support both text recognition and translation in macOS. Target languages are the same as for selected-text translation.
  - If you choose a language in Translate From instead of Auto Detect and it does not support text recognition, the screenshot window shows a notice.
- **App interface:** Currently supports all [macOS system languages](https://www.apple.com/macos/feature-availability/#system-language). It follows macOS by default. To change it, open Preferences → App Language.

After installing the app, check Translate From and Translate To in Preferences for the languages you can select on your Mac.

## Subscription management

- Open Subscription from the menu bar or Preferences to purchase, restore purchases or manage your subscription.
- To cancel renewal, [open Apple’s subscription management](https://apps.apple.com/account/subscriptions), choose Boundless Translator, and select Cancel Subscription. See [Apple’s cancellation instructions](https://support.apple.com/118428).
  - Use the Apple Account you used to subscribe. Deleting the app does not cancel the subscription.

## Contact

- For help, email [halila@me.com](mailto:halila@me.com) with your app version, macOS version, and the steps that caused the problem.
  - Find the app version and build number at the bottom right of Preferences → “?”, for example `Version 1.0 (49)`.
