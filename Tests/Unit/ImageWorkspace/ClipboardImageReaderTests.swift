import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_readImage_when_pasteboard_contains_image_then_returns_image() {
    // Arrange
    let expectedImage = NSImage(size: NSSize(width: 64, height: 32))
    let reader = PasteboardClipboardImageReader {
        expectedImage
    }

    // Act
    let image = reader.readImage()

    // Assert
    #expect(image?.size == expectedImage.size)
}

@Test @MainActor
func test_readImage_when_pasteboard_does_not_contain_image_then_returns_nil() {
    // Arrange
    let reader = PasteboardClipboardImageReader {
        nil
    }

    // Act
    let image = reader.readImage()

    // Assert
    #expect(image == nil)
}
