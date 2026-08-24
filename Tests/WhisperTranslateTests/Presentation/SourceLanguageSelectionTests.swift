import Foundation
import Testing
@testable import WhisperTranslate

@Test
func test_make_when_supported_languages_are_empty_then_returns_nil() {
    // Arrange
    let supportedLanguages: [Locale.Language] = []

    // Act
    let selection = SourceLanguageSelection.make(
        supportedLanguages: supportedLanguages,
        suggestedLanguageIdentifier: "en"
    )

    // Assert
    #expect(selection == nil)
}
