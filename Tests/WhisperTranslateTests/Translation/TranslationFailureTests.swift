import Foundation
import Testing
import Translation
@testable import WhisperTranslate

@Test
func test_init_when_language_pair_is_unsupported_then_explains_pairing() {
    // Arrange
    let error = TranslationError.unsupportedLanguagePairing

    // Act
    let failure = TranslationFailure(error: error)

    // Assert
    #expect(failure == .unsupportedLanguagePairing)
    #expect(failure.canRetry == false)
}

@Test
func test_init_when_source_language_cannot_be_identified_then_explains_detection() {
    // Arrange
    let error = TranslationError.unableToIdentifyLanguage

    // Act
    let failure = TranslationFailure(error: error)

    // Assert
    #expect(failure == .unableToIdentifyLanguage)
}

@Test
func test_init_when_error_is_unknown_then_preserves_description_and_allows_retry() {
    // Arrange
    let error = TranslationFailureTestError.network

    // Act
    let failure = TranslationFailure(error: error)

    // Assert
    #expect(failure == .unexpected("The translation service is unavailable."))
    #expect(failure.canRetry)
}

private enum TranslationFailureTestError: LocalizedError {
    case network

    var errorDescription: String? {
        "The translation service is unavailable."
    }
}
