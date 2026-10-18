# Language support reference

## User-facing language lists (planned)

Public support wording and sources: [system and language support](product-support.md).

- List support separately for selected-text translation, screenshot translation and App interface. Distinguish screenshot source and target languages.
- In the App, use the Mac's current translation and image-recognition support for language lists; use bundled localizations for interface languages.
- Public documentation explains that macOS and model readiness affect availability. Do not promise a fixed translation or screenshot language count or maintain a list for every macOS version.
- The snapshot below records one tested environment, not support on every Mac. Label any published test results with the macOS version.

## Latest test result

2026-10-11, macOS 27.0.1 (26A434): 48 translation directions and 25 OCR images passed. Unit tests passed, including the declared 48 interface locales, localization completeness and actual text loading.

Translation and OCR use their own runtime language lists. Hebrew translation and OCR languages `ars`, `cs`, `mr`, `nn`, `ro`, `yue-Hans` and `yue-Hant` have no samples and were not exercised. These results do not establish translation quality or OCR accuracy for arbitrary input.

## Official translation model requirements

Checked 2026-10-18:

- Apple’s [traditional translation strategy](https://developer.apple.com/documentation/translation/translationsession/strategy/lowlatency) uses downloaded language models and works without Apple Intelligence. Manage downloads in System Settings → General → Language & Region → Translation Languages; see [Apple’s Mac translation guide](https://support.apple.com/guide/mac-help/mchldd8b3c15/mac).
- The [`highFidelity` strategy API](https://developer.apple.com/documentation/translation/translationsession/strategy/highfidelity) was introduced in macOS 26.4; this dates the API, not the underlying models. It uses Apple Intelligence models, supports additional languages, and needs no separate language downloads once those models are ready. Without Apple Intelligence it falls back to traditional models; this does not establish availability of those additional languages.
- Apple’s [system-wide translation list](https://www.apple.com/macos/feature-availability/#translate-system-wide-translation) does not classify every language by its Apple Intelligence requirement. Danish, Norwegian Bokmål and Swedish requiring Apple Intelligence is a project observation on macOS 26.5.2, not an official exhaustive list for all OS versions. Live Translation in Messages, FaceTime and Phone has separate feature-specific lists.
- Apple documents device, OS, matching system/Siri language and region requirements in [Apple Intelligence setup](https://support.apple.com/121115). Public Support pages distinguish these conditions from project test results.
- Production `AppleTranslationConfigurationFactory` sets source and target without overriding the preferred strategy. Apple’s [strategy documentation](https://developer.apple.com/documentation/translation/translationsession/strategy) says model selection can fall back according to device capabilities and language availability. Do not promise that every translation uses Apple Intelligence or that an unavailable language becomes available merely by enabling it.

## Earlier verified snapshot

Snapshot: 2026-10-05, macOS 26.5.2. Counts combine regional variants and keep Simplified and Traditional Chinese separate. Availability depends on the user's Mac, macOS and model readiness.

| Feature | Languages | Differences and requirements |
|---|---:|---|
| Selected-text translation | 23 | Danish, Norwegian Bokmål and Swedish require Apple Intelligence to be enabled and ready on this tested Mac. Other languages may require downloaded translation packs. |
| Screenshot translation | 22 source languages | Same sources as selected-text translation except Hindi. All 23 translation languages remain available as targets. Image recognition lists 29 languages, but only 22 also support translation. The same translation-model requirements apply. |
| App interface | 34 | Includes all 23 translation languages plus 11 interface-only languages, marked below. Controls menus, settings and hints; does not imply translation support. |

★ marks languages with different support across features. ✓ means supported; — means unsupported. Screenshot targets use the selected-text translation list, including Hindi.

## Language comparison

| Language | Selected-text translation | Screenshot source | App interface |
|---|:---:|:---:|:---:|
| Catalan ★ | — | — | ✓ |
| Croatian ★ | — | — | ✓ |
| Czech ★ | — | — | ✓ |
| Finnish ★ | — | — | ✓ |
| Greek ★ | — | — | ✓ |
| Hebrew ★ | — | — | ✓ |
| Hungarian ★ | — | — | ✓ |
| Malay ★ | — | — | ✓ |
| Romanian ★ | — | — | ✓ |
| Slovak ★ | — | — | ✓ |
| Slovenian ★ | — | — | ✓ |
| Hindi ★ | ✓ | — | ✓ |
| Arabic | ✓ | ✓ | ✓ |
| Chinese (Simplified) | ✓ | ✓ | ✓ |
| Chinese (Traditional) | ✓ | ✓ | ✓ |
| Danish | ✓ | ✓ | ✓ |
| Dutch | ✓ | ✓ | ✓ |
| English | ✓ | ✓ | ✓ |
| French | ✓ | ✓ | ✓ |
| German | ✓ | ✓ | ✓ |
| Indonesian | ✓ | ✓ | ✓ |
| Italian | ✓ | ✓ | ✓ |
| Japanese | ✓ | ✓ | ✓ |
| Korean | ✓ | ✓ | ✓ |
| Norwegian Bokmål | ✓ | ✓ | ✓ |
| Polish | ✓ | ✓ | ✓ |
| Portuguese | ✓ | ✓ | ✓ |
| Russian | ✓ | ✓ | ✓ |
| Spanish | ✓ | ✓ | ✓ |
| Swedish | ✓ | ✓ | ✓ |
| Thai | ✓ | ✓ | ✓ |
| Turkish | ✓ | ✓ | ✓ |
| Ukrainian | ✓ | ✓ | ✓ |
| Vietnamese | ✓ | ✓ | ✓ |

| Verification | Result |
|---|---|
| Translation | 44 directions to/from English passed after enabling Apple Intelligence and preparing language packs; checks successful output and language identifiers, not translation quality. |
| Screenshot recognition | One fixed image for each of the 22 supported source languages passed. |
| App interface | 34 language groups from bundled resources; not a claim of manual proofreading. |
