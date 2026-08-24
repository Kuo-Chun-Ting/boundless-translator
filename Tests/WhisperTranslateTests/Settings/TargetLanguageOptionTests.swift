import Foundation
import Testing
@testable import WhisperTranslate

@Test
func test_make_when_selected_identifier_has_equivalent_supported_language_then_preserves_selected_identifier() {
    // Arrange
    let supportedLanguages = [
        Locale.Language(identifier: "en"),
        Locale.Language(identifier: "zh-TW")
    ]

    // Act
    let options = LanguageOption.make(
        supportedLanguages: supportedLanguages,
        selectedIdentifier: "zh-Hant"
    )

    // Assert
    #expect(options.count == 2)
    #expect(options.contains(where: { $0.id == "zh-Hant" }))
    #expect(!options.contains(where: { $0.id == "zh-TW" }))
}

@Test
func test_make_when_selected_language_is_unsupported_then_includes_selected_language() {
    // Arrange
    let supportedLanguages = [Locale.Language(identifier: "en")]

    // Act
    let options = LanguageOption.make(
        supportedLanguages: supportedLanguages,
        selectedIdentifier: "ja"
    )

    // Assert
    #expect(options.first?.id == "ja")
    #expect(options.first?.language.maximalIdentifier == "ja-Jpan-JP")
}

@Test
func test_preferredIdentifier_when_suggestion_matches_supported_language_then_returns_suggestion() {
    // Arrange
    let supportedLanguages = [
        Locale.Language(identifier: "en"),
        Locale.Language(identifier: "zh-TW")
    ]

    // Act
    let identifier = LanguageOption.preferredIdentifier(
        supportedLanguages: supportedLanguages,
        suggestedIdentifier: "zh-Hant"
    )

    // Assert
    #expect(identifier == "zh-Hant")
}
