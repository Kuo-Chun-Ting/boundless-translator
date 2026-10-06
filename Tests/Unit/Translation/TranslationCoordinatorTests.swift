import Foundation
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_init_when_created_then_status_is_idle() {
    // Arrange & Act
    let coordinator = TranslationCoordinator()

    // Assert
    #expect(coordinator.status == .idle)
    #expect(coordinator.request == nil)
}

@Test @MainActor
func test_submit_when_selected_text_is_valid_then_status_is_translating() throws {
    // Arrange
    let coordinator = TranslationCoordinator()
    let selectedText = try SelectedText("Hello")

    // Act
    coordinator.submit(
        selectedText,
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "zh-Hant"
    )

    // Assert
    #expect(coordinator.status == .translating)
    #expect(coordinator.request?.text == "Hello")
    #expect(coordinator.request?.sourceLanguageIdentifier == "en")
    #expect(coordinator.request?.targetLanguageIdentifier == "zh-Hant")
}

@Test @MainActor
func test_updateSourceLanguage_when_requestExists_then_resubmitsWithExplicitSource() throws {
    // Arrange
    let coordinator = TranslationCoordinator()
    coordinator.submit(
        try SelectedText("Hello"),
        sourceLanguageIdentifier: nil,
        targetLanguageIdentifier: "zh-Hant"
    )
    let previousRequestID = coordinator.request?.id

    // Act
    coordinator.updateSourceLanguage("ja")

    // Assert
    #expect(coordinator.request?.id != previousRequestID)
    #expect(coordinator.request?.text == "Hello")
    #expect(coordinator.request?.sourceLanguageIdentifier == "ja")
    #expect(coordinator.request?.targetLanguageIdentifier == "zh-Hant")
    #expect(coordinator.request?.sourceLanguageWasDetected == false)
    #expect(coordinator.status == .translating)
}

@Test @MainActor
func test_updateTargetLanguage_when_appleResolvedSource_then_reusesSourceWithoutDetectingAgain() async throws {
    // Arrange
    let coordinator = TranslationCoordinator()
    coordinator.submit(
        try SelectedText("Hello"),
        sourceLanguageIdentifier: nil,
        targetLanguageIdentifier: "zh-Hant"
    )
    let stub_runner = ImmediateTranslationRunner(result: .success(TranslationOutput(
        translatedText: "你好", sourceLanguageIdentifier: "en", targetLanguageIdentifier: "zh-Hant"
    )))
    await coordinator.translate(try #require(coordinator.request), using: stub_runner)
    let previousRequestID = coordinator.request?.id

    // Act
    coordinator.updateTargetLanguage("ja")

    // Assert
    #expect(coordinator.request?.id != previousRequestID)
    #expect(coordinator.request?.text == "Hello")
    #expect(coordinator.request?.sourceLanguageIdentifier == "en")
    #expect(coordinator.request?.targetLanguageIdentifier == "ja")
    #expect(coordinator.request?.sourceLanguageWasDetected == true)
    #expect(coordinator.status == .translating)
}

@Test @MainActor
func test_retry_when_requestExists_then_resubmitsSameTranslation() throws {
    // Arrange
    let coordinator = TranslationCoordinator()
    coordinator.submit(
        try SelectedText("Hello"),
        sourceLanguageIdentifier: nil,
        targetLanguageIdentifier: "zh-Hant"
    )
    let previousRequestID = coordinator.request?.id

    // Act
    coordinator.retry()

    // Assert
    #expect(coordinator.request?.id != previousRequestID)
    #expect(coordinator.request?.text == "Hello")
    #expect(coordinator.request?.sourceLanguageIdentifier == nil)
    #expect(coordinator.request?.targetLanguageIdentifier == "zh-Hant")
    #expect(coordinator.request?.sourceLanguageWasDetected == true)
    #expect(coordinator.status == .translating)
}

@Test @MainActor
func test_translate_when_runner_succeeds_then_publishes_output() async throws {
    // Arrange
    let output = TranslationOutput(
        translatedText: "你好",
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "zh-Hant"
    )
    let coordinator = TranslationCoordinator()
    coordinator.submit(
        try SelectedText("Hello"),
        sourceLanguageIdentifier: nil,
        targetLanguageIdentifier: "zh-Hant"
    )
    let request = try #require(coordinator.request)
    let stub_runner = ImmediateTranslationRunner(result: .success(output))

    // Act
    await coordinator.translate(request, using: stub_runner)

    // Assert
    #expect(coordinator.status == .translated(output))
    #expect(coordinator.sourceLanguageIdentifier == "en")
}

@Test @MainActor
func test_translate_when_runner_fails_then_publishes_error() async throws {
    // Arrange
    let coordinator = TranslationCoordinator()
    coordinator.submit(
        try SelectedText("Hello"),
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "zh-Hant"
    )
    let request = try #require(coordinator.request)
    let stub_runner = ImmediateTranslationRunner(
        result: .failure(TranslationTestError.unavailable)
    )

    // Act
    await coordinator.translate(request, using: stub_runner)

    // Assert
    #expect(
        coordinator.status == .failed(
            .unexpected("Translation is unavailable.")
        )
    )
}

@Test @MainActor
func test_translate_when_called_then_forwards_current_request_to_runner() async throws {
    // Arrange
    let output = TranslationOutput(
        translatedText: "你好",
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "zh-Hant"
    )
    let coordinator = TranslationCoordinator()
    coordinator.submit(
        try SelectedText("Hello"),
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "zh-Hant"
    )
    let request = try #require(coordinator.request)
    let mock_runner = TranslationRunnerMock(output: output)

    // Act
    await coordinator.translate(request, using: mock_runner)

    // Assert
    #expect(mock_runner.receivedRequest == coordinator.request)
}

@Test @MainActor
func test_translate_when_older_request_finishes_then_keeps_newer_result() async throws {
    // Arrange
    let coordinator = TranslationCoordinator()
    let suspended_runner = SuspendedTranslationRunner()
    coordinator.submit(
        try SelectedText("First"),
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "zh-Hant"
    )
    let firstRequest = try #require(coordinator.request)
    let firstTask = Task { @MainActor in
        await coordinator.translate(firstRequest, using: suspended_runner)
    }
    await suspended_runner.waitUntilRequestArrives()

    coordinator.submit(
        try SelectedText("Second"),
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "ja"
    )
    let secondOutput = TranslationOutput(
        translatedText: "二番目",
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "ja"
    )
    let second_runner = ImmediateTranslationRunner(result: .success(secondOutput))
    let secondRequest = try #require(coordinator.request)
    await coordinator.translate(secondRequest, using: second_runner)

    // Act
    let firstOutput = TranslationOutput(
        translatedText: "第一個",
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "zh-Hant"
    )
    suspended_runner.complete(with: firstOutput)
    await firstTask.value

    // Assert
    #expect(coordinator.status == .translated(secondOutput))
}

@Test @MainActor
func test_translate_when_stale_host_starts_after_resubmission_then_ignores_stale_result() async throws {
    // Arrange
    let coordinator = TranslationCoordinator()
    coordinator.submit(
        try SelectedText("First"),
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "zh-Hant"
    )
    let staleRequest = try #require(coordinator.request)
    coordinator.submit(
        try SelectedText("Second"),
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "ja"
    )
    let output = TranslationOutput(
        translatedText: "第一個",
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "zh-Hant"
    )
    let mock_runner = TranslationRunnerMock(output: output)

    // Act
    await coordinator.translate(staleRequest, using: mock_runner)

    // Assert
    #expect(mock_runner.receivedRequest == nil)
    #expect(coordinator.request?.text == "Second")
    #expect(coordinator.status == .translating)
}

@Test @MainActor
func test_translate_when_runner_reports_domain_failure_then_preserves_failure_and_retry_policy() async throws {
    // Arrange
    let coordinator = TranslationCoordinator()
    coordinator.submit(
        try SelectedText("Hello"),
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "zh-Hant"
    )
    let request = try #require(coordinator.request)
    let stub_runner = ImmediateTranslationRunner(
        result: .failure(TranslationFailure.unsupportedLanguagePairing)
    )

    // Act
    await coordinator.translate(request, using: stub_runner)

    // Assert
    #expect(coordinator.status == .failed(.unsupportedLanguagePairing))
}

@Test @MainActor
func test_cancel_when_translationIsRunning_then_requestsCancellationAndDiscardsLateResult() async throws {
    // Arrange
    let coordinator = TranslationCoordinator()
    let stub_runner = SuspendedTranslationRunner()
    var cancellationCount = 0
    coordinator.submit(try SelectedText("First"), sourceLanguageIdentifier: "en", targetLanguageIdentifier: "zh-Hant")
    let request = try #require(coordinator.request)
    let task = Task { @MainActor in
        await coordinator.translate(request, using: stub_runner, onCancel: { cancellationCount += 1 })
    }
    await stub_runner.waitUntilRequestArrives()

    // Act
    coordinator.cancel()
    coordinator.cancel()
    stub_runner.complete(with: TranslationOutput(
        translatedText: "Late result", sourceLanguageIdentifier: "en", targetLanguageIdentifier: "zh-Hant"
    ))
    await task.value

    // Assert
    #expect(cancellationCount == 1)
    #expect(coordinator.request == nil)
    #expect(coordinator.status == .idle)
}

@Test @MainActor
func test_submit_when_previousTranslationFinishesLate_then_nextTranslationCanStillBeCancelled() async throws {
    // Arrange
    let coordinator = TranslationCoordinator()
    let stub_firstRunner = SuspendedTranslationRunner()
    let stub_secondRunner = SuspendedTranslationRunner()
    var firstCancellationCount = 0
    var secondCancellationCount = 0
    coordinator.submit(try SelectedText("First"), sourceLanguageIdentifier: "en", targetLanguageIdentifier: "zh-Hant")
    let firstRequest = try #require(coordinator.request)
    let firstTask = Task { @MainActor in
        await coordinator.translate(firstRequest, using: stub_firstRunner, onCancel: { firstCancellationCount += 1 })
    }
    await stub_firstRunner.waitUntilRequestArrives()

    // Act
    coordinator.submit(try SelectedText("Second"), sourceLanguageIdentifier: "en", targetLanguageIdentifier: "zh-Hant")
    let secondRequest = try #require(coordinator.request)
    let secondTask = Task { @MainActor in
        await coordinator.translate(secondRequest, using: stub_secondRunner, onCancel: { secondCancellationCount += 1 })
    }
    await stub_secondRunner.waitUntilRequestArrives()
    let lateOutput = TranslationOutput(
        translatedText: "Late result", sourceLanguageIdentifier: "en", targetLanguageIdentifier: "zh-Hant"
    )
    stub_firstRunner.complete(with: lateOutput)
    await firstTask.value
    coordinator.cancel()
    stub_secondRunner.complete(with: lateOutput)
    await secondTask.value

    // Assert
    #expect(firstCancellationCount == 1)
    #expect(secondCancellationCount == 1)
    #expect(coordinator.request == nil)
    #expect(coordinator.status == .idle)
}

@Test(arguments: [false, true]) @MainActor
func test_translate_when_runnerIsCancelled_then_doesNotPublishFailure(byUser: Bool) async throws {
    // Arrange
    let coordinator = TranslationCoordinator()
    coordinator.submit(try SelectedText("Hello"), sourceLanguageIdentifier: "en", targetLanguageIdentifier: "zh-Hant")
    let request = try #require(coordinator.request)
    let error: any Error = byUser ? CocoaError(.userCancelled) : CancellationError()
    let stub_runner = ImmediateTranslationRunner(result: .failure(error))

    // Act
    await coordinator.translate(request, using: stub_runner)

    // Assert
    #expect(coordinator.status == .idle)
}

@Test @MainActor
func test_cancel_when_translationAlreadyFinished_then_doesNotCallExpiredSession() async throws {
    // Arrange
    let coordinator = TranslationCoordinator()
    var cancellationCount = 0
    coordinator.submit(try SelectedText("Hello"), sourceLanguageIdentifier: "en", targetLanguageIdentifier: "zh-Hant")
    let request = try #require(coordinator.request)
    let stub_runner = ImmediateTranslationRunner(result: .success(TranslationOutput(
        translatedText: "你好", sourceLanguageIdentifier: "en", targetLanguageIdentifier: "zh-Hant"
    )))
    await coordinator.translate(request, using: stub_runner, onCancel: { cancellationCount += 1 })

    // Act
    coordinator.cancel()

    // Assert
    #expect(cancellationCount == 0)
    #expect(coordinator.request == nil)
    #expect(coordinator.status == .idle)
}

private struct ImmediateTranslationRunner: TranslationRunning {
    let result: Result<TranslationOutput, Error>

    func translate(_ request: TranslationRequest) async throws -> TranslationOutput {
        try result.get()
    }
}

@MainActor
private final class SuspendedTranslationRunner: TranslationRunning {
    private var continuation: CheckedContinuation<TranslationOutput, Error>?

    func translate(_ request: TranslationRequest) async throws -> TranslationOutput {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func waitUntilRequestArrives() async {
        while continuation == nil {
            await Task.yield()
        }
    }

    func complete(with output: TranslationOutput) {
        continuation?.resume(returning: output)
        continuation = nil
    }
}

@MainActor
private final class TranslationRunnerMock: TranslationRunning {
    private(set) var receivedRequest: TranslationRequest?

    private let output: TranslationOutput

    init(output: TranslationOutput) {
        self.output = output
    }

    func translate(_ request: TranslationRequest) async throws -> TranslationOutput {
        receivedRequest = request
        return output
    }
}

private enum TranslationTestError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        "Translation is unavailable."
    }
}
