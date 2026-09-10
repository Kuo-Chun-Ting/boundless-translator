import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_submit_when_access_denied_then_does_not_create_translation_request() throws {
    // Arrange
    let coordinator = TranslationCoordinator(authorize: { false })

    // Act
    coordinator.submit(try SelectedText("Hello"), sourceLanguageIdentifier: "en", targetLanguageIdentifier: "ja")

    // Assert
    #expect(coordinator.request == nil)
    #expect(coordinator.status == .idle)
}

@Test @MainActor
func test_retry_and_language_changes_when_access_expires_then_do_not_resubmit() throws {
    // Arrange
    let access = AccessAuthorizationStub()
    let coordinator = TranslationCoordinator(authorize: { access.isAllowed })
    coordinator.submit(try SelectedText("Hello"), sourceLanguageIdentifier: "en", targetLanguageIdentifier: "ja")
    let originalID = coordinator.request?.id
    access.isAllowed = false

    // Act
    coordinator.retry()
    coordinator.updateSourceLanguage("fr")
    coordinator.updateTargetLanguage("de")

    // Assert
    #expect(coordinator.request?.id == originalID)
    #expect(coordinator.request?.sourceLanguageIdentifier == "en")
    #expect(coordinator.request?.targetLanguageIdentifier == "ja")
}

@Test @MainActor
func test_translate_when_access_expires_before_engine_starts_then_never_calls_engine() async throws {
    // Arrange
    let access = AccessAuthorizationStub()
    let coordinator = TranslationCoordinator(authorize: { access.isAllowed })
    coordinator.submit(try SelectedText("Hello"), sourceLanguageIdentifier: "en", targetLanguageIdentifier: "ja")
    let request = try #require(coordinator.request)
    let mock_runner = AccessTranslationRunnerMock()
    access.isAllowed = false

    // Act
    await coordinator.translate(request, using: mock_runner)

    // Assert
    #expect(mock_runner.callCount == 0)
    #expect(coordinator.status == .idle)
}

@MainActor
private final class AccessAuthorizationStub {
    var isAllowed = true
}

@MainActor
private final class AccessTranslationRunnerMock: TranslationRunning {
    var callCount = 0
    func translate(_ request: TranslationRequest) async throws -> TranslationOutput {
        callCount += 1
        return TranslationOutput(translatedText: "translated", sourceLanguageIdentifier: "en", targetLanguageIdentifier: "ja")
    }
}
