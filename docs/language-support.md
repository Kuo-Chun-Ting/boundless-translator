# Language support reference

## User-facing language lists (planned)

- List support separately for selected-text translation, screenshot translation and App interface. Distinguish screenshot source and target languages.
- In the App, use the Mac's current translation and image-recognition support for language lists; use bundled localizations for interface languages.
- Public documentation explains that macOS and model readiness affect availability. Do not promise a fixed translation or screenshot language count or maintain a list for every macOS version.
- The snapshot below records one tested environment, not support on every Mac. Label any published test results with the macOS version.

## Latest test result

2026-10-11, macOS 27.0.1 (26A434): 48 translation directions and 25 OCR images passed. Unit tests passed, including the declared 48 interface locales, localization completeness and actual text loading.

Translation and OCR use their own runtime language lists. Hebrew translation and OCR languages `ars`, `cs`, `mr`, `nn`, `ro`, `yue-Hans` and `yue-Hant` have no samples and were not exercised. These results do not establish translation quality or OCR accuracy for arbitrary input.

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
