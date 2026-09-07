import Foundation
import Testing
import Translation
@testable import BoundlessTranslator

@Test(arguments: [
    (TranslationError.unsupportedSourceLanguage, TranslationFailure.unsupportedSourceLanguage),
    (TranslationError.unsupportedTargetLanguage, TranslationFailure.unsupportedTargetLanguage),
    (TranslationError.unsupportedLanguagePairing, TranslationFailure.unsupportedLanguagePairing),
    (TranslationError.unableToIdentifyLanguage, TranslationFailure.unableToIdentifyLanguage),
    (TranslationError.nothingToTranslate, TranslationFailure.nothingToTranslate),
]) @MainActor
func test_translate_when_apple_reports_known_error_then_throws_domain_failure(
    error: TranslationError,
    expected: TranslationFailure
) async throws {
    // Arrange
    let stub_runner = AppleTranslationRunner(translateText: { _ in throw error })
    let request = makeAppleRunnerRequest()

    // Act & Assert
    await #expect(throws: expected) {
        try await stub_runner.translate(request)
    }
}

@Test @MainActor
func test_translate_when_language_is_not_installed_then_preserves_recoverable_failure() async throws {
    guard #available(macOS 26.0, *) else { return }
    // Arrange
    let stub_runner = AppleTranslationRunner(translateText: { _ in
        throw TranslationError.notInstalled
    })

    // Act & Assert
    await #expect(throws: TranslationFailure.languageNotInstalled) {
        try await stub_runner.translate(makeAppleRunnerRequest())
    }
    #expect(TranslationFailure.languageNotInstalled.canRetry)
}

@Test @MainActor
func test_translate_when_operation_succeeds_then_forwards_text_and_returns_output() async throws {
    // Arrange
    var receivedText: String?
    let expected = TranslationOutput(
        translatedText: "你好", sourceLanguageIdentifier: "en", targetLanguageIdentifier: "zh-Hant"
    )
    let runner = AppleTranslationRunner(translateText: { text in
        receivedText = text
        return expected
    })

    // Act
    let result = try await runner.translate(makeAppleRunnerRequest())

    // Assert
    #expect(receivedText == "Hello")
    #expect(result == expected)
}

@Test @MainActor
func test_translate_when_operation_throws_unknown_error_then_preserves_description() async {
    // Arrange
    let stub_runner = AppleTranslationRunner(translateText: { _ in
        throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unavailable"])
    })

    // Act & Assert
    await #expect(throws: TranslationFailure.unexpected("Unavailable")) {
        try await stub_runner.translate(makeAppleRunnerRequest())
    }
}

private func makeAppleRunnerRequest() -> TranslationRequest {
    TranslationRequest(text: "Hello", sourceLanguageIdentifier: "en", targetLanguageIdentifier: "zh-Hant")
}
