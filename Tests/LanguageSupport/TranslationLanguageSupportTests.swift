import Foundation
import Testing
@preconcurrency import Translation
@testable import BoundlessTranslator

@Test(
    .enabled(if: LanguageSupportFixture.isEnabled, "Run Scripts/run_language_support_tests.sh"),
    .serialized,
    .timeLimit(.minutes(1)),
    arguments: try await TranslationLanguagePair.load()
) @MainActor
func test_translate_when_language_pair_is_supported_then_returns_translation(
    pair: TranslationLanguagePair
) async throws {
    // Arrange
    guard #available(macOS 26.0, *) else {
        Issue.record("UNVERIFIED: headless translation tests require macOS 26; the App still supports macOS 15.")
        return
    }
    let source = Locale.Language(identifier: pair.source.id)
    let target = Locale.Language(identifier: pair.target.id)
    let status = await LanguageAvailability().status(from: source, to: target)
    guard status == .installed else {
        let reason = status == .supported
            ? "Install the source and target language packs before rerunning."
            : "The runtime does not report this language pair as available."
        Issue.record("UNVERIFIED: \(pair.testDescription), status=\(status). \(reason) No translation was attempted.")
        return
    }
    let session = TranslationSession(installedSource: source, target: target)
    defer { session.cancel() }
    let runner = AppleTranslationRunner(session: session)
    let request = TranslationRequest(
        text: pair.source.text, sourceLanguageIdentifier: pair.source.id,
        targetLanguageIdentifier: pair.target.id
    )

    // Act
    let result = try await runner.translate(request)

    // Assert
    #expect(!result.translatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    #expect(result.translatedText != request.text)
    #expect(LanguageSupportFixture.languageGroup(result.sourceLanguageIdentifier) == pair.source.id)
    #expect(LanguageSupportFixture.languageGroup(result.targetLanguageIdentifier) == pair.target.id)
    print("TRANSLATED \(pair.testDescription): \(result.translatedText)")
}
