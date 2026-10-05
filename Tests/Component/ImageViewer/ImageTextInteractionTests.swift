import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_present_when_imageWindowOpens_then_selectAllWorksWithoutExtraFocusSetup() async throws {
    // Arrange
    let view = ImageTextView(analysisProvider: { _ in
        ImageTextDocument(text: "ABC", words: [ImageTextRegion(
            range: NSRange(location: 0, length: 3), bounds: CGRect(x: 10, y: 10, width: 60, height: 20), line: 0)])
    })
    let controller = ImageViewerWindowController(
        content: view, windowPresenter: ForegroundWindowPresenterSpy(),
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings())
    let window = try #require(controller.window)
    defer { window.close() }
    // Act: presentation must establish the responder; the test does not set it.
    controller.present(image: NSImage(size: CGSize(width: 200, height: 200)), pointerLocation: .zero)
    await viewAnalysis(view)
    let event = try #require(NSEvent.keyEvent(
        with: .keyDown, location: .zero, modifierFlags: .command, timestamp: 0,
        windowNumber: window.windowNumber, context: nil, characters: "a",
        charactersIgnoringModifiers: "a", isARepeat: false, keyCode: 0))
    let handled = window.performKeyEquivalent(with: event)
    // Assert
    #expect(window.firstResponder === view)
    #expect(handled)
    #expect(view.selectedText == "ABC")
}

@Test @MainActor
func test_copy_when_textIsSelected_then_copiesExactRange() async throws {
    // Arrange
    let (window, view) = await selectionFixture()
    defer { window.close() }
    let board = NSPasteboard.general
    let backup = try PasteboardSnapshot(pasteboard: board)
    view.selectAll(nil)
    // Act
    view.copy(nil)
    let changeCount = board.changeCount
    defer { backup.restore(to: board, ifUnchangedSince: changeCount) }
    // Assert
    #expect(board.string(forType: .string) == "A B")
}

@Test @MainActor
func test_submit_when_imageSelectionHasMultipleRows_then_preservesExactSourceText() async throws {
    // Arrange
    let text = "電池健康度 正常\n自動調整亮度\n低耗電模式"
    let view = ImageTextView(analysisProvider: { _ in
        ImageTextDocument(text: text, words: [ImageTextRegion(
            range: NSRange(location: 0, length: text.utf16.count),
            bounds: CGRect(x: 10, y: 10, width: 100, height: 50), line: 0)])
    })
    view.display(NSImage(size: CGSize(width: 200, height: 200)))
    await viewAnalysis(view)
    view.selectAll(nil)
    let stub = ActiveImageSelectionStub(view: view)
    let coordinator = TranslationCoordinator()
    // Act
    #expect(view.selectedText == text)
    let selection = try await ImageViewerSelectionReader(provider: stub).readSelectedText()
    coordinator.submit(selection, sourceLanguageIdentifier: "zh-Hant", targetLanguageIdentifier: "en")
    // Assert
    #expect(coordinator.request?.text == text)
}

@Test(arguments: [CGPoint(x: 150, y: 100), CGPoint(x: 100, y: 10)]) @MainActor
func test_mouseDown_when_imageBlankOrOuterMarginIsClicked_then_clearsSelection(point: CGPoint) async {
    // Arrange: the square image has a 50-point margin above and below it.
    let (window, view) = await selectionFixture()
    defer { window.close() }
    window.setContentSize(CGSize(width: 200, height: 300))
    view.selectAll(nil)
    // Act
    view.mouseDown(with: mouseEvent(.leftMouseDown, at: point, in: window))
    view.mouseUp(with: mouseEvent(.leftMouseUp, at: point, in: window))
    // Assert
    #expect(view.selectedText.isEmpty)
}

@Test @MainActor
func test_drag_when_newSelectionStarts_then_replacesPreviousRange() async {
    // Arrange
    let (window, view) = await selectionFixture()
    defer { window.close() }
    view.selectAll(nil)
    // Act
    dragImageText(view, in: window, from: CGPoint(x: 81, y: 20), to: CGPoint(x: 99, y: 20))
    // Assert
    #expect(view.selectedText == "B")
}

@Test @MainActor
func test_mouseMoved_when_dragHasEnded_then_doesNotExtendSelection() async {
    // Arrange
    let (window, view) = await selectionFixture()
    defer { window.close() }
    dragImageText(view, in: window, from: CGPoint(x: 11, y: 20), to: CGPoint(x: 29, y: 20))
    // Act
    view.mouseMoved(with: mouseEvent(.mouseMoved, at: CGPoint(x: 99, y: 20), in: window))
    view.mouseDragged(with: mouseEvent(.leftMouseDragged, at: CGPoint(x: 99, y: 20), in: window))
    // Assert
    #expect(view.selectedText == "A")
}

@Test @MainActor
func test_drag_when_pathStaysInBlank_then_doesNotSelectNearbyWords() async {
    // Arrange
    let (window, view) = await selectionFixture()
    defer { window.close() }
    // Act
    dragImageText(view, in: window, from: CGPoint(x: 0, y: 100), to: CGPoint(x: 15, y: 108))
    // Assert
    #expect(view.selectedText.isEmpty)
}

@Test @MainActor
func test_performKeyEquivalent_when_anotherViewIsFocused_then_doesNotChangeSelection() async throws {
    // Arrange
    let (window, view) = await selectionFixture()
    defer { window.close() }
    dragImageText(view, in: window, from: CGPoint(x: 11, y: 20), to: CGPoint(x: 29, y: 20))
    window.makeFirstResponder(window)
    let event = try #require(NSEvent.keyEvent(
        with: .keyDown, location: .zero, modifierFlags: .command, timestamp: 0,
        windowNumber: window.windowNumber, context: nil, characters: "a",
        charactersIgnoringModifiers: "a", isARepeat: false, keyCode: 0))
    // Act
    let handled = view.performKeyEquivalent(with: event)
    // Assert
    #expect(!handled)
    #expect(view.selectedText == "A")
}

@Test @MainActor
func test_mouseMoved_when_windowIsInactive_then_preservesSelectionAndDoesNotActivate() async {
    // Arrange
    let (window, view) = await selectionFixture()
    defer { window.close() }
    view.selectAll(nil)
    window.orderOut(nil)
    // Act
    view.mouseMoved(with: mouseEvent(.mouseMoved, at: CGPoint(x: 20, y: 20), in: window))
    // Assert
    #expect(!window.isKeyWindow)
    #expect(!window.isVisible)
    #expect(view.selectedText == "A B")
}

@MainActor func dragImageText(
    _ view: ImageTextView, in window: NSWindow, from start: CGPoint, to end: CGPoint
) {
    view.mouseDown(with: mouseEvent(.leftMouseDown, at: start, in: window))
    view.mouseDragged(with: mouseEvent(.leftMouseDragged, at: end, in: window))
    view.mouseUp(with: mouseEvent(.leftMouseUp, at: end, in: window))
}

// OS activation is exercised by GUI/E2E; this fixture controls the reader's active-selection precondition.
@MainActor private final class ActiveImageSelectionStub: ImageViewerSelectionProviding {
    let isSelectionActive = true
    let view: ImageTextView
    var selectedText: String { view.selectedText }
    init(view: ImageTextView) { self.view = view }
}
