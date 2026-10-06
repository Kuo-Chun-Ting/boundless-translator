import Foundation
import Testing
@testable import BoundlessTranslator

@Test
func test_init_when_language_pair_is_unsupported_then_explains_pairing() {
    // Arrange
    let error = TranslationFailure.unsupportedLanguagePairing

    // Act
    let failure = TranslationFailure(error: error)

    // Assert
    #expect(failure == .unsupportedLanguagePairing)
    #expect(failure.canRetry == false)
}

@Test
func test_init_when_source_language_cannot_be_identified_then_explains_detection() {
    // Arrange
    let error = TranslationFailure.unableToIdentifyLanguage

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

@Test(arguments: [
    (TranslationFailure.unsupportedSourceLanguage, "不支援所選文字的語言。", false),
    (.unsupportedTargetLanguage, "不支援所選的目標語言。請在設定中選擇其他語言。", false),
    (.unsupportedLanguagePairing, "文字可能已是目標語言，或不支援此語言組合。", false),
    (.unableToIdentifyLanguage, "無法偵測所選文字的語言。", false),
    (.nothingToTranslate, "選取內容沒有可翻譯的文字。", false),
    (.languageNotInstalled, "尚未安裝所需語言。請再試一次，並允許 macOS 下載。", true),
    (.unexpected("Service unavailable."), "Service unavailable. 請再試一次。", true)
])
func test_message_when_translationFails_then_localizesErrorAndOffersAppropriateRecovery(
    failure: TranslationFailure, message: String, canRetry: Bool
) {
    // Arrange
    let localization = AppLocalization(languageIdentifier: "zh-Hant")

    // Act & Assert
    #expect(failure.message(localization: localization) == message)
    #expect(failure.canRetry == canRetry)
}
