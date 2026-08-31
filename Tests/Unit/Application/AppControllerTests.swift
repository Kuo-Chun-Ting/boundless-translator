import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_resolve_shortcut_action_when_text_is_selected_then_returns_translation_without_reading_image() async throws {
    // Arrange
    let selectedText = try SelectedText("Selected text")
    let stub_selectedTextReader = SelectedTextReaderStub(
        result: .success(selectedText)
    )
    let mock_imageReader = ClipboardImageReaderStub(
        image: NSImage(size: NSSize(width: 640, height: 480))
    )
    let controller = AppController(
        selectedTextReader: stub_selectedTextReader,
        clipboardImageReader: mock_imageReader,
        imageWorkspaceController: ImageWorkspaceControllerStub()
    )

    // Act
    let action = await controller.resolveShortcutAction()

    // Assert
    guard case .translate(let actualText) = action else {
        Issue.record("Expected the selected text to be translated")
        return
    }
    #expect(actualText == selectedText)
    #expect(mock_imageReader.invocationCount == 0)
}

@Test @MainActor
func test_resolve_shortcut_action_when_text_is_not_selected_and_image_is_copied_then_returns_image() async throws {
    // Arrange
    let expectedImage = NSImage(size: NSSize(width: 640, height: 480))
    let stub_selectedTextReader = SelectedTextReaderStub(
        result: .failure(SelectedTextReadError.noSelection)
    )
    let stub_imageReader = ClipboardImageReaderStub(
        image: expectedImage
    )
    let controller = AppController(
        selectedTextReader: stub_selectedTextReader,
        clipboardImageReader: stub_imageReader,
        imageWorkspaceController: ImageWorkspaceControllerStub()
    )

    // Act
    let action = await controller.resolveShortcutAction()

    // Assert
    guard case .openImage(let actualImage) = action else {
        Issue.record("Expected the copied image to open")
        return
    }
    #expect(actualImage === expectedImage)
}

@Test @MainActor
func test_resolve_shortcut_action_when_text_and_image_are_missing_then_returns_none() async {
    // Arrange
    let stub_selectedTextReader = SelectedTextReaderStub(
        result: .failure(SelectedTextReadError.noSelection)
    )
    let stub_imageReader = ClipboardImageReaderStub(image: nil)
    let controller = AppController(
        selectedTextReader: stub_selectedTextReader,
        clipboardImageReader: stub_imageReader,
        imageWorkspaceController: ImageWorkspaceControllerStub()
    )

    // Act
    let action = await controller.resolveShortcutAction()

    // Assert
    guard case .none = action else {
        Issue.record("Expected no shortcut action")
        return
    }
}

@MainActor
private final class ClipboardImageReaderStub: ClipboardImageReading {
    let image: NSImage?
    private(set) var invocationCount = 0

    init(image: NSImage?) {
        self.image = image
    }

    func readImage() -> NSImage? {
        invocationCount += 1
        return image
    }
}

@MainActor
private final class SelectedTextReaderStub: SelectedTextReading {
    private let result: Result<SelectedText, Error>

    init(result: Result<SelectedText, Error>) {
        self.result = result
    }

    func readSelectedText() async throws -> SelectedText {
        try result.get()
    }
}

@MainActor
private final class ImageWorkspaceControllerStub: ImageWorkspaceControlling {
    var isSelectionActive = false
    var selectedText = ""

    func present(image: NSImage, pointerLocation: CGPoint) {}
}
