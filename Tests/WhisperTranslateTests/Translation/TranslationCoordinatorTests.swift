import Foundation
import Testing
@testable import WhisperTranslate

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
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "zh-Hant"
    )
    let stub_runner = ImmediateTranslationRunner(result: .success(output))

    // Act
    await coordinator.translate(using: stub_runner)

    // Assert
    #expect(coordinator.status == .translated(output))
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
    let stub_runner = ImmediateTranslationRunner(
        result: .failure(TranslationTestError.unavailable)
    )

    // Act
    await coordinator.translate(using: stub_runner)

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
    let mock_runner = TranslationRunnerMock(output: output)

    // Act
    await coordinator.translate(using: mock_runner)

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
    let firstTask = Task { @MainActor in
        await coordinator.translate(using: suspended_runner)
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
    await coordinator.translate(using: second_runner)

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
