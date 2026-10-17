import AppKit
import Testing

@testable import BoundlessTranslator

@Test @MainActor
func test_display_when_recognitionTakesLongerThanHalfSecond_then_showsCenteredProgressUntilCompletion() async throws {
    // Arrange
    let stub_analysis = PendingRecognition()
    let view = ImageTextView(analysisProvider: stub_analysis.analyze)
    view.frame = CGRect(x: 0, y: 0, width: 800, height: 600)
    let start = ContinuousClock.now
    // Act
    view.display(NSImage(size: CGSize(width: 400, height: 200)))
    #expect(progress(in: view) == nil)
    try await waitForRecognitionState { progress(in: view) != nil }
    let overlay = try #require(progress(in: view))
    view.layoutSubtreeIfNeeded()
    // Assert
    #expect(start.duration(to: .now) >= .milliseconds(500))
    #expect(abs(overlay.frame.midX - view.bounds.midX) < 1)
    #expect(abs(overlay.frame.midY - view.bounds.midY) < 1)
    stub_analysis.finish(0)
    try await waitForRecognitionState { view.accessibilityIdentifier() == "imageWorkspace.text" }
    #expect(progress(in: view) == nil)
}

@Test @MainActor
func test_display_when_recognitionFinishesQuickly_then_neverShowsDelayedProgress() async throws {
    // Arrange
    let view = ImageTextView(analysisProvider: { _ in ImageTextDocument(text: "Done", words: []) })
    // Act
    view.display(NSImage(size: CGSize(width: 200, height: 200)))
    try await waitForRecognitionState { view.accessibilityIdentifier() == "imageWorkspace.text" }
    // Assert: observe past the display deadline, catching an uncancelled timer.
    let deadline = ContinuousClock.now + .milliseconds(650)
    while ContinuousClock.now < deadline {
        #expect(progress(in: view) == nil)
        try await Task.sleep(for: .milliseconds(10))
    }
}

@Test @MainActor
func test_display_when_delayedRecognitionFails_then_removesProgressAndKeepsImage() async throws {
    // Arrange
    let stub_analysis = PendingRecognition()
    let view = ImageTextView(analysisProvider: stub_analysis.analyze)
    let image = NSImage(size: CGSize(width: 200, height: 200))
    view.display(image)
    try await waitForRecognitionState { progress(in: view) != nil }
    // Act
    stub_analysis.requests[0].resume(throwing: RecognitionFailure.unavailable)
    try await waitForRecognitionState { view.accessibilityIdentifier() == "imageWorkspace.unavailable" }
    // Assert
    #expect(progress(in: view) == nil)
    #expect(view.image === image)
}

@Test @MainActor
func test_display_when_replacingPendingRecognition_then_oldResultCannotHideNewProgress() async throws {
    // Arrange
    let stub_analysis = PendingRecognition()
    let view = ImageTextView(analysisProvider: stub_analysis.analyze)
    view.display(NSImage(size: CGSize(width: 200, height: 200)))
    try await waitForRecognitionState { progress(in: view) != nil }
    // Act
    view.display(NSImage(size: CGSize(width: 300, height: 200)))
    #expect(progress(in: view) == nil)
    try await waitForRecognitionState { progress(in: view) != nil && stub_analysis.requests.count == 2 }
    stub_analysis.finish(0)
    let deadline = ContinuousClock.now + .milliseconds(50)
    while ContinuousClock.now < deadline {
        #expect(progress(in: view) != nil)
        try await Task.sleep(for: .milliseconds(5))
    }
    stub_analysis.finish(1)
    try await waitForRecognitionState { view.accessibilityIdentifier() == "imageWorkspace.text" }
    // Assert
    #expect(progress(in: view) == nil)
}

@Test(arguments: [false, true]) @MainActor
func test_windowWillClose_when_recognitionIsPending_then_removesProgressAndDiscardsLateCompletion(progressAlreadyVisible: Bool) async throws {
    // Arrange
    let stub_analysis = PendingRecognition()
    let view = ImageTextView(analysisProvider: stub_analysis.analyze)
    let controller = ImageViewerWindowController(content: view,
        windowPresenter: ForegroundWindowPresenterSpy(),
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings())
    let window = try #require(controller.window)
    controller.present(image: NSImage(size: CGSize(width: 400, height: 300)), pointerLocation: .zero)
    try await waitForRecognitionState { stub_analysis.requests.count == 1 }
    if progressAlreadyVisible {
        try await waitForRecognitionState { progress(in: view) != nil }
    }
    // Act
    window.close()
    #expect(progress(in: view) == nil)
    stub_analysis.finish(0)
    // Assert: late completion must not restore a closed screenshot's state.
    let deadline = ContinuousClock.now + .milliseconds(650)
    while ContinuousClock.now < deadline {
        #expect(progress(in: view) == nil)
        #expect(view.document.text.isEmpty)
        try await Task.sleep(for: .milliseconds(5))
    }
}

@MainActor private func progress(in view: ImageTextView) -> NSView? {
    view.subviews.first { $0.accessibilityIdentifier() == "imageWorkspace.recognitionProgress" }
}

@MainActor private func waitForRecognitionState(_ condition: () -> Bool) async throws {
    // The full Component run also drives native menus on the main actor.
    let deadline = ContinuousClock.now + .seconds(120)
    while !condition() {
        guard ContinuousClock.now < deadline else { throw RecognitionFailure.timeout }
        try await Task.sleep(for: .milliseconds(10))
    }
}

@MainActor private final class PendingRecognition {
    var requests: [CheckedContinuation<ImageTextDocument?, any Error>] = []

    func analyze(_ image: NSImage) async throws -> ImageTextDocument? {
        try await withCheckedThrowingContinuation { requests.append($0) }
    }

    func finish(_ index: Int) {
        requests[index].resume(returning: ImageTextDocument(text: "Done", words: []))
    }
}

private enum RecognitionFailure: Error { case unavailable, timeout }
