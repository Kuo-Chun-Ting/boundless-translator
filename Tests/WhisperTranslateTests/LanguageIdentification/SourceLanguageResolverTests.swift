import Testing
@testable import WhisperTranslate

@Test
func test_resolve_when_detected_language_meets_threshold_then_uses_detected_language() {
    // Arrange
    let stub_identifier = LanguageIdentifierStub(
        hypotheses: [
            LanguageHypothesis(languageIdentifier: "en", confidence: 0.82),
            LanguageHypothesis(languageIdentifier: "de", confidence: 0.11)
        ]
    )
    let resolver = SourceLanguageResolver(
        minimumConfidence: 0.60,
        languageIdentifier: stub_identifier
    )

    // Act
    let resolution = resolver.resolve(text: "What are you doing?", configuredSource: nil)

    // Assert
    #expect(resolution == .resolved("en"))
}

@Test
func test_resolve_when_confidence_equals_threshold_then_uses_detected_language() {
    // Arrange
    let stub_identifier = LanguageIdentifierStub(
        hypotheses: [
            LanguageHypothesis(languageIdentifier: "en", confidence: 0.60)
        ]
    )
    let resolver = SourceLanguageResolver(
        minimumConfidence: 0.60,
        languageIdentifier: stub_identifier
    )

    // Act
    let resolution = resolver.resolve(text: "Hello world", configuredSource: nil)

    // Assert
    #expect(resolution == .resolved("en"))
}

@Test
func test_resolve_when_detected_language_is_below_threshold_then_requests_selection_with_suggestion() {
    // Arrange
    let stub_identifier = LanguageIdentifierStub(
        hypotheses: [
            LanguageHypothesis(languageIdentifier: "en", confidence: 0.42),
            LanguageHypothesis(languageIdentifier: "de", confidence: 0.31)
        ]
    )
    let resolver = SourceLanguageResolver(
        minimumConfidence: 0.60,
        languageIdentifier: stub_identifier
    )

    // Act
    let resolution = resolver.resolve(text: "Instant", configuredSource: nil)

    // Assert
    #expect(
        resolution == .needsSelection(suggestedLanguageIdentifier: "en")
    )
}

@Test
func test_resolve_when_source_language_is_configured_then_uses_configured_language() {
    // Arrange
    let mock_identifier = LanguageIdentifierMock()
    let resolver = SourceLanguageResolver(
        minimumConfidence: 0.60,
        languageIdentifier: mock_identifier
    )

    // Act
    let resolution = resolver.resolve(
        text: "Bonjour",
        configuredSource: "fr"
    )

    // Assert
    #expect(resolution == .resolved("fr"))
    #expect(mock_identifier.identifyCallCount == 0)
}

@Test
func test_resolve_when_no_hypotheses_then_requests_selection_without_suggestion() {
    // Arrange
    let stub_identifier = LanguageIdentifierStub(hypotheses: [])
    let resolver = SourceLanguageResolver(
        minimumConfidence: 0.60,
        languageIdentifier: stub_identifier
    )

    // Act
    let resolution = resolver.resolve(text: "123", configuredSource: nil)

    // Assert
    #expect(
        resolution == .needsSelection(suggestedLanguageIdentifier: nil)
    )
}

private struct LanguageIdentifierStub: SourceLanguageIdentifying {
    let hypotheses: [LanguageHypothesis]

    func identify(_ text: String) -> [LanguageHypothesis] {
        hypotheses
    }
}

private final class LanguageIdentifierMock: SourceLanguageIdentifying, @unchecked Sendable {
    private(set) var identifyCallCount = 0

    func identify(_ text: String) -> [LanguageHypothesis] {
        identifyCallCount += 1
        return []
    }
}
