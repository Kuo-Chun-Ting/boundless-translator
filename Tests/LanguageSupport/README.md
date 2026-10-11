# Language support checks

Run `Scripts/run_language_support_tests.sh` from the repository root. The tests use the production translation adapter and OCR recognizer, without windows, shortcuts or permission resets. Ordinary `swift test` skips this group; full Verify runs its dedicated entry.

The headless translation test requires macOS 26 or later and ready translation models. Traditional models use individual language packs from System Settings → General → Language & Region → Translation Languages. Apple Intelligence translation requires Apple Intelligence to be enabled and its models ready; its additional languages may have no individual download entry. The tests do not download models. An unready pair produces an `UNVERIFIED` issue and a nonzero exit. The current diagnostic always suggests installing packs; that advice is incomplete for Apple Intelligence-only languages. The App itself still supports macOS 15.

See the [language support reference](../../docs/language-support.md) for the verified lists, differences, model requirements and latest recorded results.

## Coverage

- Translation: one fixed sentence in each language, to and from English. Assert successful, nonempty output distinct from the input and the requested language identifiers through `AppleTranslationRunner`. The fixture sentences require translation. This checks availability, not translation quality or every possible language pair.
- OCR: select fixed images using Vision's accurate-recognition language list, then compare `ImageTextRecognizer` output with the expected text. Recognition is tested independently of translation support. These clean images check basic recognition, not selection or GUI behavior.
- App interface: Unit tests verify the declared languages, complete localization keys and actual loading of each language's text.

Translation and OCR tests log their supported languages and those without samples. Missing samples do not fail the tests; a passing run covers only the samples executed. Samples unsupported on this Mac are excluded. Regional variants share a sample; simplified/traditional Chinese remain separate, and Norwegian `no` is grouped with Bokmål `nb` (not Nynorsk `nn`).

## Fixtures

`Fixtures/languages.json` contains 25 languages, each with input text and an OCR image name. Open the checked-in PNGs in `Fixtures/OCR` to inspect the actual input.

To deliberately change an input, edit the JSON, run `swift Tests/LanguageSupport/Fixtures/generate_ocr_images.swift`, and review the image diff. Tests read the committed PNGs; they never generate images or derive expected text from OCR results. Only Unicode canonical composition is normalized for the comparison.

Run these checks before a release or after changing the engine or OS. Record the macOS version with the results; this suite does not maintain a separate language list for every macOS release. A green result applies to the tested runtime and fixtures.
