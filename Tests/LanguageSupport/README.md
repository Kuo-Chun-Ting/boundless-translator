# Language support checks

Run `Tests/Runners/run_language_support_tests.sh` from the repository root. The tests use the production translation adapter and OCR recognizer, without windows, shortcuts or permission resets. Ordinary `swift test` and Verify skip this group.

The headless translation test requires macOS 26 or later and ready translation models. Traditional models use individual language packs from System Settings → General → Language & Region → Translation Languages. Apple Intelligence translation requires Apple Intelligence to be enabled and its models ready; its additional languages may have no individual download entry. The tests do not download models. An unready pair produces an `UNVERIFIED` issue and a nonzero exit. The current diagnostic always suggests installing packs; that advice is incomplete for Apple Intelligence-only languages. The App itself still supports macOS 15.

See the [language support reference](../../docs/language-support.md) for the verified lists, differences, model requirements and latest recorded results.

## Coverage

- Translation: one fixed sentence in each language, to and from English. Assert successful, nonempty output distinct from the input and the requested language identifiers through `AppleTranslationRunner`. The fixture sentences require translation. This checks availability, not translation quality or every possible language pair.
- Screenshot sources: a fixed image for each language shared by Translation and accurate OCR. Assert the text returned by `ImageTextRecognizer` against the fixture. This is a clean-image smoke test, not an OCR accuracy benchmark or a selection/GUI test.
- Capability coverage: compare current API languages with fixture coverage and print the runtime, raw API identifiers, translation/OCR intersection and bundled interface locales. New languages without fixtures fail coverage. Fixtures unsupported on this Mac are listed and excluded from execution; they do not make an older runtime fail for supporting fewer languages. Regional variants share a fixture; simplified/traditional Chinese remain separate, and Norwegian `no` is grouped with Bokmål `nb` (not Nynorsk `nn`).
- Interface translations remain covered by the existing Unit tests.

## Fixtures

`Fixtures/languages.json` contains the visible input text and its OCR image name. `ocrImage: null` means no screenshot recognition fixture; Hindi is currently translation-only. Open the checked-in PNGs in `Fixtures/OCR` to inspect the actual input.

To deliberately change an input, edit the JSON, run `swift Tests/LanguageSupport/Fixtures/generate_ocr_images.swift`, and review the image diff. Tests read the committed PNGs; they never generate images or derive expected text from OCR results. Only Unicode canonical composition is normalized for the comparison.

Run these checks before a release or after changing the engine or OS. Record the macOS version with the results; this suite does not maintain a separate language list for every macOS release. A green result applies to the tested runtime and fixtures.
