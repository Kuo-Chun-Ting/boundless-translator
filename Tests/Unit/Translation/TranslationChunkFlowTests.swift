import Foundation
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_translate_when_multipleChunks_then_publishesEachResultBeforeSendingTheNext() async throws {
    // Arrange
    let coordinator = TranslationCoordinator(splitter: TranslationTextSplitter(targetCharacters: 7))
    coordinator.submit(try SelectedText("First.\nSecond."), sourceLanguageIdentifier: "en", targetLanguageIdentifier: "zh-Hant")
    let request = try #require(coordinator.request)
    let mock_runner = ChunkRunnerMock()
    let task = Task { await coordinator.translate(request, using: mock_runner) }
    try await mock_runner.waitForRequest(1)

    // Act
    mock_runner.complete("第一句。\n")
    try await mock_runner.waitForRequest(2)

    // Assert: partial output is visible while the second call is outstanding.
    #expect(coordinator.partialOutput?.translatedText == "第一句。")
    #expect(coordinator.status == .translating)
    #expect(mock_runner.requests.map(\.text) == ["First.\n", "Second."])

    // Act
    mock_runner.complete("第二句。")
    await task.value

    // Assert
    #expect(coordinator.partialOutput?.translatedText == "第一句。\n第二句。")
    #expect(coordinator.status == .translated(try #require(coordinator.partialOutput)))
}

@Test @MainActor
func test_cancel_when_chunkIsOutstanding_then_stopsRemainingChunksAndProtectsNewResult() async throws {
    // Arrange
    let coordinator = TranslationCoordinator(splitter: TranslationTextSplitter(targetCharacters: 7))
    coordinator.submit(try SelectedText("First.\nSecond."), sourceLanguageIdentifier: "en", targetLanguageIdentifier: "zh-Hant")
    let oldRequest = try #require(coordinator.request)
    let oldRunner = ChunkRunnerMock()
    var cancelCount = 0
    let oldTask = Task { await coordinator.translate(oldRequest, using: oldRunner, onCancel: { cancelCount += 1 }) }
    try await oldRunner.waitForRequest(1)

    // Act
    coordinator.cancel()
    coordinator.submit(try SelectedText("New."), sourceLanguageIdentifier: "en", targetLanguageIdentifier: "zh-Hant")
    let newRequest = try #require(coordinator.request)
    let newRunner = ChunkRunnerMock()
    let newTask = Task { await coordinator.translate(newRequest, using: newRunner) }
    try await newRunner.waitForRequest(1)
    newRunner.complete("新的。")
    await newTask.value
    oldRunner.complete("過期的。")
    await oldTask.value

    // Assert
    #expect(cancelCount == 1)
    #expect(oldRunner.requests.count == 1)
    #expect(coordinator.request?.id == newRequest.id)
    #expect(coordinator.partialOutput?.translatedText == "新的。")
    #expect(coordinator.status == .translated(try #require(coordinator.partialOutput)))
}

@Test @MainActor
func test_translate_when_laterChunkFails_then_preservesPartialOutputAndStopsRemainingChunks() async throws {
    // Arrange
    let coordinator = TranslationCoordinator(splitter: TranslationTextSplitter(targetCharacters: 7))
    coordinator.submit(try SelectedText("First.\nSecond.\nThird."), sourceLanguageIdentifier: "en", targetLanguageIdentifier: "zh-Hant")
    let request = try #require(coordinator.request)
    let mock_runner = ChunkRunnerMock()
    let task = Task { await coordinator.translate(request, using: mock_runner) }
    try await mock_runner.waitForRequest(1)
    mock_runner.complete("第一句。")
    try await mock_runner.waitForRequest(2)

    // Act
    mock_runner.fail()
    await task.value

    // Assert
    #expect(coordinator.partialOutput?.translatedText == "第一句。")
    #expect(mock_runner.requests.count == 2)
    guard case .failed = coordinator.status else {
        Issue.record("Expected failure instead of an endless translating state")
        return
    }
}

@MainActor
private final class ChunkRunnerMock: TranslationRunning {
    var requests: [TranslationRequest] = []
    private var continuation: CheckedContinuation<TranslationOutput, Error>?
    private var arrival: CheckedContinuation<Void, Never>?

    func translate(_ request: TranslationRequest) async throws -> TranslationOutput {
        requests.append(request)
        return try await withCheckedThrowingContinuation {
            continuation = $0
            arrival?.resume()
            arrival = nil
        }
    }

    func waitForRequest(_ count: Int) async throws {
        if requests.count < count {
            await withCheckedContinuation { arrival = $0 }
        }
        try #require(requests.count == count)
    }

    func complete(_ text: String) {
        let callback = continuation
        continuation = nil
        callback?.resume(returning: TranslationOutput(translatedText: text, sourceLanguageIdentifier: "en", targetLanguageIdentifier: "zh-Hant"))
    }

    func fail() {
        continuation?.resume(throwing: TranslationFailure.unsupportedLanguagePairing)
        continuation = nil
    }
}
