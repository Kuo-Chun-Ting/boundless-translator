import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_present_when_recognitionFindsNoText_then_showsOneAlertAndKeepsScreenshot() async throws {
    // Arrange
    let view = ImageTextView(analysisProvider: { _ in ImageTextDocument(text: "", words: []) })
    let controller = makeScreenshotFeedbackController(content: view)
    let window = try #require(controller.window)
    let image = NSImage(size: CGSize(width: 200, height: 100))
    defer { closeScreenshotFeedback(controller) }

    // Act
    controller.present(image: image, pointerLocation: .zero)
    await viewAnalysis(view)

    // Assert
    let alert = try #require(window.attachedSheet)
    #expect(window.isVisible)
    #expect(view.image === image)
    window.endSheet(alert)
    alert.orderOut(nil)
    window.setContentSize(CGSize(width: 700, height: 500))
    #expect(window.attachedSheet == nil)
    #expect(window.isVisible)
    #expect(view.image === image)
}

@Test @MainActor
func test_present_when_recognitionFindsText_then_doesNotShowEmptyResultAlert() async throws {
    // Arrange
    let view = ImageTextView(analysisProvider: { _ in ImageTextDocument(text: "Hello", words: []) })
    let controller = makeScreenshotFeedbackController(content: view)
    let window = try #require(controller.window)
    defer { closeScreenshotFeedback(controller) }

    // Act
    controller.present(image: NSImage(size: CGSize(width: 200, height: 100)), pointerLocation: .zero)
    await viewAnalysis(view)

    // Assert
    #expect(window.isVisible)
    #expect(window.attachedSheet == nil)
    #expect(view.document.text == "Hello")
}

@Test @MainActor
func test_present_when_recognitionFails_then_doesNotReportNoText() async throws {
    // Arrange
    let view = ImageTextView(analysisProvider: { _ in throw ScreenshotFeedbackError.unavailable })
    let controller = makeScreenshotFeedbackController(content: view)
    let window = try #require(controller.window)
    defer { closeScreenshotFeedback(controller) }

    // Act
    controller.present(image: NSImage(size: CGSize(width: 200, height: 100)), pointerLocation: .zero)
    await viewAnalysis(view)

    // Assert
    #expect(window.isVisible)
    #expect(window.attachedSheet == nil)
    #expect(view.accessibilityIdentifier() == "imageWorkspace.unavailable")
}

@MainActor private func makeScreenshotFeedbackController(content: ImageTextView) -> ImageViewerWindowController {
    ImageViewerWindowController(
        content: content, windowPresenter: ForegroundWindowPresenterSpy(),
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings())
}

@MainActor private func closeScreenshotFeedback(_ controller: ImageViewerWindowController) {
    if let window = controller.window, let alert = window.attachedSheet {
        window.endSheet(alert)
        alert.orderOut(nil)
    }
    controller.close()
}

private enum ScreenshotFeedbackError: Error { case unavailable }

@Test @MainActor
func test_present_when_newBlankScreenshotIsCaptured_then_warnsAgain() async throws {
    // Arrange
    let view = ImageTextView(analysisProvider: { _ in ImageTextDocument(text: "", words: []) })
    let controller = makeScreenshotFeedbackController(content: view)
    let window = try #require(controller.window)
    defer { closeScreenshotFeedback(controller) }
    controller.present(image: NSImage(size: CGSize(width: 200, height: 100)), pointerLocation: .zero)
    await viewAnalysis(view)
    let firstAlert = try #require(window.attachedSheet)
    window.endSheet(firstAlert)
    firstAlert.orderOut(nil)

    // Act
    controller.present(image: NSImage(size: CGSize(width: 300, height: 150)), pointerLocation: .zero)
    await viewAnalysis(view)

    // Assert
    let nextAlert = try #require(window.attachedSheet)
    #expect(nextAlert !== firstAlert)
    #expect(view.image?.size == CGSize(width: 300, height: 150))
}

@Test @MainActor
func test_present_when_closedBeforeAnalysisCompletes_then_doesNotOpenAlert() async throws {
    // Arrange
    let stub = ScreenshotFeedbackAnalysis()
    let view = ImageTextView(analysisProvider: stub.analyze)
    let controller = makeScreenshotFeedbackController(content: view)
    let window = try #require(controller.window)
    defer { closeScreenshotFeedback(controller) }
    controller.present(image: NSImage(size: CGSize(width: 200, height: 100)), pointerLocation: .zero)
    await stub.waitForRequests(1)

    // Act
    controller.close()
    stub.requests[0].resume(returning: ImageTextDocument(text: "", words: []))
    await viewAnalysis(view)

    // Assert
    #expect(!window.isVisible)
    #expect(window.attachedSheet == nil)
}

@Test @MainActor
func test_present_when_replacedAnalysisReturnsEmptyLate_then_doesNotWarnForOldImage() async throws {
    // Arrange
    let stub = ScreenshotFeedbackAnalysis()
    let view = ImageTextView(analysisProvider: stub.analyze)
    let controller = makeScreenshotFeedbackController(content: view)
    let window = try #require(controller.window)
    defer { closeScreenshotFeedback(controller) }
    controller.present(image: NSImage(size: CGSize(width: 200, height: 100)), pointerLocation: .zero)
    await stub.waitForRequests(1)
    controller.present(image: NSImage(size: CGSize(width: 300, height: 150)), pointerLocation: .zero)
    await stub.waitForRequests(2)
    stub.requests[1].resume(returning: ImageTextDocument(text: "Hello", words: []))
    await viewAnalysis(view)

    // Act
    stub.requests[0].resume(returning: ImageTextDocument(text: "", words: []))
    for _ in 0..<10 { await Task.yield() }

    // Assert
    #expect(window.attachedSheet == nil)
    #expect(view.document.text == "Hello")
}

@MainActor private final class ScreenshotFeedbackAnalysis {
    var requests: [CheckedContinuation<ImageTextDocument?, Never>] = []
    func analyze(_ image: NSImage) async -> ImageTextDocument? {
        await withCheckedContinuation { requests.append($0) }
    }
    func waitForRequests(_ count: Int) async {
        while requests.count < count { await Task.yield() }
    }
}
