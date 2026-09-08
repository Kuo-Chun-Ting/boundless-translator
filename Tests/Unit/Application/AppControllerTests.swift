import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_resolveShortcutAction_when_external_text_is_selected_then_returns_translation() async throws {
    // Arrange
    let text = try SelectedText("Selected text")
    let controller = AppController(
        selectedTextReader: SelectedTextReaderStub(result: .success(text)),
        imageViewerController: ImageViewerControllerStub()
    )

    // Act
    let action = await controller.resolveShortcutAction()

    // Assert
    guard case .translate(let actual) = action else {
        Issue.record("Expected selected text")
        return
    }
    #expect(actual == text)
}

@Test @MainActor
func test_handleShortcut_when_no_text_is_selected_then_captures_and_presents_image() async {
    // Arrange
    let mock_viewer = ImageViewerControllerStub()
    let controller = AppController(
        selectedTextReader: SelectedTextReaderStub(result: .failure(SelectedTextReadError.noSelection)),
        screenshotCapture: ScreenshotCaptureStub(
            result: .success(NSImage(size: NSSize(width: 100, height: 50)))
        ),
        imageViewerController: mock_viewer
    )

    // Act
    controller.handleShortcut()
    for _ in 0..<5 {
        await Task.yield()
    }

    // Assert
    #expect(mock_viewer.presentationCount == 1)
}

@Test @MainActor
func test_resolveShortcutAction_when_image_text_is_selected_then_prefers_image_selection() async throws {
    // Arrange
    let stub_viewer = ImageViewerControllerStub()
    stub_viewer.isSelectionActive = true
    stub_viewer.selectedText = "Image text"
    let controller = AppController(
        selectedTextReader: SelectedTextReaderStub(result: .success(try SelectedText("External text"))),
        imageViewerController: stub_viewer
    )

    // Act
    let action = await controller.resolveShortcutAction()

    // Assert
    guard case .translate(let actual) = action else {
        Issue.record("Expected image text")
        return
    }
    #expect(actual.value == "Image text")
}

@MainActor
private final class SelectedTextReaderStub: SelectedTextReading {
    let result: Result<SelectedText, Error>
    init(result: Result<SelectedText, Error>) { self.result = result }
    func readSelectedText() async throws -> SelectedText { try result.get() }
}

@MainActor
private struct ScreenshotCaptureStub: ScreenshotCapturing {
    let result: Result<NSImage?, Error>
    func captureRegion() async throws -> NSImage? { try result.get() }
}

@MainActor
private final class ImageViewerControllerStub: ImageViewerControlling {
    var isSelectionActive = false
    var selectedText = ""
    var presentationCount = 0
    func present(image: NSImage, pointerLocation: CGPoint) { presentationCount += 1 }
}
