import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_handleTranslationShortcut_when_no_text_is_selected_then_does_not_capture_screenshot() async {
    // Arrange
    let mock_capture = ScreenshotCaptureMock()
    let controller = AppController(
        selectedTextReader: SelectedTextReaderStub(result: .failure(SelectedTextReadError.noSelection)),
        screenshotCapture: mock_capture,
        imageViewerController: ImageViewerControllerStub(),
        subscriptionAccess: makeUnrestrictedTestAccess()
    )

    // Act
    controller.handleTranslationShortcut()
    for _ in 0..<5 {
        await Task.yield()
    }

    // Assert
    #expect(mock_capture.captureCount == 0)
}

@Test @MainActor
func test_handleTranslationShortcut_when_selection_is_cancelled_then_does_not_capture_screenshot() async {
    // Arrange
    let mock_capture = ScreenshotCaptureMock()
    let controller = AppController(
        selectedTextReader: SelectedTextReaderStub(result: .failure(CancellationError())),
        screenshotCapture: mock_capture,
        imageViewerController: ImageViewerControllerStub(),
        subscriptionAccess: makeUnrestrictedTestAccess()
    )

    // Act
    controller.handleTranslationShortcut()
    for _ in 0..<5 {
        await Task.yield()
    }

    // Assert
    #expect(mock_capture.captureCount == 0)
}

@MainActor
private final class SelectedTextReaderStub: SelectedTextReading {
    let result: Result<SelectedText, Error>
    init(result: Result<SelectedText, Error>) { self.result = result }
    func readSelectedText() async throws -> SelectedText { try result.get() }
}

@MainActor
private final class ScreenshotCaptureMock: ScreenshotCapturing {
    private(set) var captureCount = 0

    func captureRegion() async throws -> NSImage? {
        captureCount += 1
        return nil
    }
}

@MainActor
private final class ImageViewerControllerStub: ImageViewerControlling {
    var isSelectionActive = false
    var selectedText = ""
    var presentationCount = 0
    func present(image: NSImage, pointerLocation: CGPoint) { presentationCount += 1 }
}
