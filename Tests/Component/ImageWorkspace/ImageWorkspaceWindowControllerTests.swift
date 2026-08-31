import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_init_whenWorkspaceIsCreated_then_usesStandardPersistentWindow() throws {
    // Arrange & Act
    let fixture = makeImageWorkspaceFixture()
    let window = try #require(fixture.controller.window)

    // Assert
    #expect(window.styleMask.contains(.titled))
    #expect(window.styleMask.contains(.closable))
    #expect(window.styleMask.contains(.miniaturizable))
    #expect(window.styleMask.contains(.resizable))
    #expect(window.collectionBehavior.contains(.moveToActiveSpace))
    #expect(!window.isReleasedWhenClosed)
    #expect(!window.hidesOnDeactivate)
}

@Test @MainActor
func test_present_whenCalledAgain_then_reusesWindowAndReplacesImage() throws {
    // Arrange
    let fixture = makeImageWorkspaceFixture()
    let firstWindow = try #require(fixture.controller.window)
    let firstImage = NSImage(size: NSSize(width: 600, height: 400))
    let secondImage = NSImage(size: NSSize(width: 900, height: 500))

    // Act
    fixture.controller.present(image: firstImage, pointerLocation: .zero)
    fixture.controller.present(image: secondImage, pointerLocation: .zero)

    // Assert
    #expect(fixture.controller.window === firstWindow)
    #expect(fixture.content.displayedImages.count == 2)
    #expect(fixture.content.displayedImages.last === secondImage)
    #expect(firstWindow.isVisible)
    firstWindow.orderOut(nil)
}

@Test @MainActor
func test_present_whenPointerScreenIsKnown_then_placesWindowInsideVisibleFrame() throws {
    // Arrange
    let visibleFrame = NSRect(x: 0, y: 0, width: 1_200, height: 800)
    let fixture = makeImageWorkspaceFixture(visibleFrame: visibleFrame)
    let window = try #require(fixture.controller.window)

    // Act
    fixture.controller.present(
        image: NSImage(size: NSSize(width: 1_600, height: 900)),
        pointerLocation: CGPoint(x: 500, y: 500)
    )

    // Assert
    #expect(visibleFrame.contains(window.frame))
    window.orderOut(nil)
}

@Test @MainActor
func test_windowWillClose_whenWorkspaceCloses_then_clearsSelection() {
    // Arrange
    let fixture = makeImageWorkspaceFixture()

    // Act
    fixture.controller.windowWillClose(
        Notification(name: NSWindow.willCloseNotification)
    )

    // Assert
    #expect(fixture.content.clearSelectionCount == 1)
}

@MainActor
private struct ImageWorkspaceFixture {
    let controller: ImageWorkspaceWindowController
    let content: ImageWorkspaceContentStub
}

@MainActor
private func makeImageWorkspaceFixture(
    visibleFrame: CGRect = CGRect(x: 0, y: 0, width: 1_200, height: 800)
) -> ImageWorkspaceFixture {
    let content = ImageWorkspaceContentStub()
    let controller = ImageWorkspaceWindowController(
        content: content,
        visibleFrameForPointer: { _ in visibleFrame },
        activateApplication: {}
    )
    return ImageWorkspaceFixture(controller: controller, content: content)
}

@MainActor
private final class ImageWorkspaceContentStub: ImageWorkspaceContent {
    let view = NSView()
    var selectedText = ""
    var hasActiveTextSelection = false
    private(set) var displayedImages: [NSImage] = []
    private(set) var clearSelectionCount = 0

    func display(_ image: NSImage) {
        displayedImages.append(image)
    }

    func clearSelection() {
        clearSelectionCount += 1
    }
}
