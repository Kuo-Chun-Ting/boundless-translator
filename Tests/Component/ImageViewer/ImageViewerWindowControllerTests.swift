import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_init_whenWorkspaceIsCreated_then_usesStandardPersistentWindow() throws {
    // Arrange & Act
    let fixture = makeImageViewerFixture()
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
    let fixture = makeImageViewerFixture()
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
func test_present_whenWindowWasClosed_then_reopensSameWindowWithNewImage() throws {
    // Arrange
    let fixture = makeImageViewerFixture()
    let window = try #require(fixture.controller.window)
    defer { window.orderOut(nil) }
    fixture.controller.present(image: NSImage(size: NSSize(width: 600, height: 400)), pointerLocation: .zero)
    window.performClose(nil)
    #expect(!window.isVisible)
    let secondImage = NSImage(size: NSSize(width: 900, height: 500))

    // Act
    fixture.controller.present(image: secondImage, pointerLocation: .zero)

    // Assert
    #expect(fixture.controller.window === window)
    #expect(fixture.content.displayedImages.last === secondImage)
    #expect(window.isVisible)
}

@Test @MainActor
func test_cancelOperation_whenImageWindowIsOpen_then_closesAndClearsSelection() throws {
    // Arrange
    let fixture = makeImageViewerFixture()
    let window = try #require(fixture.controller.window)
    defer { window.orderOut(nil) }
    fixture.controller.present(image: NSImage(size: NSSize(width: 600, height: 400)), pointerLocation: .zero)

    // Act
    window.cancelOperation(nil)

    // Assert
    #expect(!window.isVisible)
    #expect(fixture.content.clearSelectionCount == 1)
}

@Test @MainActor
func test_sendEvent_whenEscapeIsPressedWithContentFocused_then_closesImageWindow() throws {
    // Arrange
    let fixture = makeImageViewerFixture()
    let window = try #require(fixture.controller.window)
    defer { window.orderOut(nil) }
    fixture.controller.present(image: NSImage(size: NSSize(width: 600, height: 400)), pointerLocation: .zero)
    let focusedView = EscapeConsumingView()
    fixture.content.view.addSubview(focusedView)
    #expect(window.makeFirstResponder(focusedView))
    let event = try #require(NSEvent.keyEvent(
        with: .keyDown, location: .zero, modifierFlags: [],
        timestamp: 0, windowNumber: window.windowNumber, context: nil,
        characters: "\u{1b}", charactersIgnoringModifiers: "\u{1b}", isARepeat: false, keyCode: 53
    ))

    // Act
    window.sendEvent(event)

    // Assert
    #expect(!window.isVisible)
    #expect(fixture.content.clearSelectionCount == 1)
}

@Test @MainActor
func test_performKeyEquivalent_whenCommandWIsPressed_then_closesImageWindow() throws {
    // Arrange
    let fixture = makeImageViewerFixture()
    let window = try #require(fixture.controller.window)
    defer { window.orderOut(nil) }
    fixture.controller.present(image: NSImage(size: NSSize(width: 600, height: 400)), pointerLocation: .zero)
    let event = try #require(NSEvent.keyEvent(
        with: .keyDown, location: .zero, modifierFlags: .command,
        timestamp: 0, windowNumber: window.windowNumber, context: nil,
        characters: "w", charactersIgnoringModifiers: "w", isARepeat: false, keyCode: 13
    ))

    // Act
    let handled = window.performKeyEquivalent(with: event)

    // Assert
    #expect(handled)
    #expect(!window.isVisible)
    #expect(fixture.content.clearSelectionCount == 1)
}

@MainActor
private final class EscapeConsumingView: NSView {
    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        interpretKeyEvents([event])
    }

    override func cancelOperation(_ sender: Any?) {}
}

@Test @MainActor
func test_present_whenPointerScreenIsKnown_then_placesWindowInsideVisibleFrame() throws {
    // Arrange
    let visibleFrame = NSRect(x: 0, y: 0, width: 1_200, height: 800)
    let fixture = makeImageViewerFixture(visibleFrame: visibleFrame)
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
    let fixture = makeImageViewerFixture()

    // Act
    fixture.controller.windowWillClose(
        Notification(name: NSWindow.willCloseNotification)
    )

    // Assert
    #expect(fixture.content.clearSelectionCount == 1)
}

@Test @MainActor
func test_languageIdentifier_when_changed_then_updatesOpenImageViewerTitle() throws {
    // Arrange
    let suiteName = "ImageViewerLanguageTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let interfaceLanguageSettings = InterfaceLanguageSettings(
        defaults: defaults,
        preferredLanguageIdentifiers: { ["en"] }
    )
    let fixture = makeImageViewerFixture(
        interfaceLanguageSettings: interfaceLanguageSettings
    )
    let window = try #require(fixture.controller.window)
    #expect(window.title == "Screenshot")

    // Act
    interfaceLanguageSettings.languageIdentifier = "zh-Hant"

    // Assert
    #expect(window.title == "螢幕截圖")
}

@MainActor
private struct ImageViewerFixture {
    let controller: ImageViewerWindowController
    let content: ImageViewerContentStub
}

@MainActor
private func makeImageViewerFixture(
    visibleFrame: CGRect = CGRect(x: 0, y: 0, width: 1_200, height: 800),
    interfaceLanguageSettings: InterfaceLanguageSettings? = nil
) -> ImageViewerFixture {
    let content = ImageViewerContentStub()
    let controller = ImageViewerWindowController(
        content: content,
        visibleFrameForPointer: { _ in visibleFrame },
        activateApplication: {},
        interfaceLanguageSettings: interfaceLanguageSettings
            ?? makeTestInterfaceLanguageSettings()
    )
    return ImageViewerFixture(controller: controller, content: content)
}

@MainActor
private final class ImageViewerContentStub: ImageViewerContent {
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
