import Testing
@testable import WhisperTranslate

@Test
func test_make_when_request_has_source_and_target_then_returns_explicit_configuration() {
    // Arrange
    let request = TranslationRequest(
        text: "Hello",
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "zh-Hant"
    )

    // Act
    let configuration = TranslationConfigurationFactory.make(for: request)

    // Assert
    #expect(configuration.source?.minimalIdentifier == "en")
    #expect(configuration.target?.minimalIdentifier == "zh-TW")
}
