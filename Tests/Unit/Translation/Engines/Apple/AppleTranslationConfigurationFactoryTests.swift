import Testing
@testable import BoundlessTranslator

@Test
func test_make_when_sourceIsAutomatic_then_leavesDetectionToApple() {
    // Arrange
    let request = TranslationRequest(text: "test", sourceLanguageIdentifier: nil, targetLanguageIdentifier: "zh-Hant")

    // Act
    let configuration = AppleTranslationConfigurationFactory.make(for: request)

    // Assert
    #expect(configuration.source == nil)
    #expect(configuration.target?.minimalIdentifier == "zh-TW")
}

@Test
func test_make_when_request_has_source_and_target_then_returns_explicit_configuration() {
    // Arrange
    let request = TranslationRequest(
        text: "Hello",
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "zh-Hant"
    )

    // Act
    let configuration = AppleTranslationConfigurationFactory.make(for: request)

    // Assert
    #expect(configuration.source?.minimalIdentifier == "en")
    #expect(configuration.target?.minimalIdentifier == "zh-TW")
}
