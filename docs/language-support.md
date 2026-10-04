# Language support reference

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
