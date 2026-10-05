import AppKit
import Testing

@testable import BoundlessTranslator

@Test @MainActor
func test_appearance_when_switchingLightDarkLight_then_preservesImageAndSelection() async throws {
    // Arrange
    let view = ImageTextView(analysisProvider: { _ in sampleDocument() })
    let image = NSImage(size: NSSize(width: 400, height: 200))
    view.display(image)
    await viewAnalysis(view)
    view.selectAll(nil)
    var backgrounds: [CGColor] = []
    // Act & Assert
    for name in [NSAppearance.Name.aqua, .darkAqua, .aqua] {
        view.appearance = NSAppearance(named: name)
        view.displayIfNeeded()
        let actual = try #require(view.layer?.backgroundColor)
        var expected: CGColor?
        view.effectiveAppearance.performAsCurrentDrawingAppearance {
            expected = NSColor.windowBackgroundColor.cgColor
        }
        #expect(actual == expected)
        #expect(view.image === image)
        #expect(view.selectedText == "ABC")
        backgrounds.append(actual)
    }
    #expect(backgrounds[0] != backgrounds[1])
    #expect(backgrounds[0] == backgrounds[2])
}

@Test @MainActor
func test_display_when_oldAnalysisFinishesLast_then_keepsNewestImageAndText() async {
    // Arrange
    let stub = SuspendedImageAnalysis()
    let view = ImageTextView(analysisProvider: stub.analyze)
    let first = NSImage(size: NSSize(width: 100, height: 80))
    let second = NSImage(size: NSSize(width: 300, height: 200))
    view.display(first)
    await stub.waitForRequests(1)
    view.display(second)
    await stub.waitForRequests(2)
    // Act
    stub.complete(1, with: sampleDocument())
    await viewAnalysis(view)
    view.selectAll(nil)
    stub.complete(0, with: ImageTextDocument(text: "OLD", words: []))
    for _ in 0..<10 { await Task.yield() }
    // Assert
    #expect(view.image === second)
    #expect(view.document.text == "ABC")
    #expect(view.selectedText == "ABC")
}

@Test @MainActor
func test_display_when_replacingImage_then_clearsSelectionWhileAnalysisLoads() async {
    // Arrange
    let view = ImageTextView(analysisProvider: { _ in sampleDocument() })
    view.display(NSImage(size: NSSize(width: 400, height: 200)))
    await viewAnalysis(view)
    view.selectAll(nil)
    // Act
    view.display(NSImage(size: NSSize(width: 600, height: 300)))
    // Assert
    #expect(view.selectedText.isEmpty)
    #expect(!view.hasActiveTextSelection)
    #expect(view.document.text.isEmpty)
    #expect(view.accessibilityIdentifier() == "imageWorkspace.loading")
}

@Test @MainActor
func test_display_when_analysisFails_then_keepsImageWithoutStaleText() async {
    // Arrange
    let view = ImageTextView(analysisProvider: { _ in throw AnalysisFailure.unavailable })
    let image = NSImage(size: NSSize(width: 100, height: 80))
    // Act
    view.display(image)
    await viewAnalysis(view)
    // Assert
    #expect(view.image === image)
    #expect(view.selectedText.isEmpty)
    #expect(view.accessibilityIdentifier() == "imageWorkspace.unavailable")
}

@Test @MainActor
func test_viewRect_when_imageFitsWithMargins_then_mapsImageCoordinatesAndResizes() {
    // Arrange
    let view = ImageTextView(analysisProvider: { _ in nil })
    view.frame = CGRect(x: 0, y: 0, width: 800, height: 600)
    view.display(NSImage(size: NSSize(width: 400, height: 200)))
    // Act & Assert
    #expect(view.imageRect == CGRect(x: 0, y: 100, width: 800, height: 400))
    #expect(
        view.viewRect(for: CGRect(x: 10, y: 20, width: 30, height: 40))
            == CGRect(x: 20, y: 140, width: 60, height: 80))
    view.frame.size = NSSize(width: 400, height: 600)
    #expect(view.imageRect == CGRect(x: 0, y: 200, width: 400, height: 200))
}

@Test @MainActor
func test_clearSelection_when_textSelected_then_preventsStaleTextFromBeingRead() async {
    // Arrange
    let view = ImageTextView(analysisProvider: { _ in sampleDocument() })
    view.display(NSImage(size: NSSize(width: 400, height: 200)))
    await viewAnalysis(view)
    view.selectAll(nil)
    // Act
    view.clearSelection()
    // Assert
    #expect(view.selectedText.isEmpty)
    #expect(!view.hasActiveTextSelection)
    #expect(view.document.text == "ABC")
}

private enum AnalysisFailure: Error { case unavailable }

@Test @MainActor
func test_display_when_analysisCompletesInBackground_then_doesNotPresentWindowAgain() async throws {
    // Arrange
    let stub = SuspendedImageAnalysis()
    let view = ImageTextView(analysisProvider: stub.analyze)
    let presenter = ForegroundWindowPresenterSpy()
    let controller = ImageViewerWindowController(
        content: view, windowPresenter: presenter,
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings())
    let window = try #require(controller.window)
    defer { window.close() }
    controller.present(image: NSImage(size: CGSize(width: 200, height: 200)), pointerLocation: .zero)
    await stub.waitForRequests(1)
    window.orderOut(nil)
    // Act
    stub.complete(0, with: sampleDocument())
    await viewAnalysis(view)
    // Assert
    #expect(view.document.text == "ABC")
    #expect(presenter.presentedWindows.count == 1)
    #expect(!window.isVisible)
    #expect(!window.isKeyWindow)
}

@Test @MainActor
func test_selectAll_when_commandKeyUsesZhuyinInput_then_selectsRecognizedText() async throws {
    // Arrange: macOS supplies the Latin command character while the unmodified key is Zhuyin.
    let (window, view) = await selectionFixture()
    window.makeFirstResponder(view)
    let event = try #require(NSEvent.keyEvent(
        with: .keyDown, location: .zero, modifierFlags: .command, timestamp: 0,
        windowNumber: window.windowNumber, context: nil, characters: "a",
        charactersIgnoringModifiers: "ㄇ", isARepeat: false, keyCode: 0))
    // Act
    let handled = view.performKeyEquivalent(with: event)
    // Assert
    #expect(handled)
    #expect(view.selectedText == "A B")
}

@Test @MainActor
func test_selection_when_diagonalDragNeverTouchesText_then_doesNotSelect() async {
    // Arrange
    let (window, view) = await selectionFixture()
    // Act: the enclosing rectangle covers A, but the actual diagonal does not.
    view.mouseDown(with: mouseEvent(.leftMouseDown, at: CGPoint(x: 0, y: 150), in: window))
    view.mouseDragged(with: mouseEvent(.leftMouseDragged, at: CGPoint(x: 150, y: 0), in: window))
    // Assert
    #expect(view.selectedText.isEmpty)
}

@Test @MainActor
func test_selection_when_dragReachesTextThenContinuesIntoBlank_then_keepsContinuousRange() async {
    // Arrange
    let (window, view) = await selectionFixture()
    view.mouseDown(with: mouseEvent(.leftMouseDown, at: CGPoint(x: 0, y: 150), in: window))
    // Act: the path reaches A, then curves into blank space beyond B.
    view.mouseDragged(with: mouseEvent(.leftMouseDragged, at: CGPoint(x: 20, y: 20), in: window))
    view.mouseDragged(with: mouseEvent(.leftMouseDragged, at: CGPoint(x: 150, y: 0), in: window))
    // Assert
    #expect(view.selectedText == "A B")
}

@Test @MainActor
func test_selection_when_focusIsLostMidDrag_then_staleDragCannotExtendSelection() async {
    // Arrange
    let (window, view) = await selectionFixture()
    view.mouseDown(with: mouseEvent(.leftMouseDown, at: CGPoint(x: 11, y: 20), in: window))
    view.mouseDragged(with: mouseEvent(.leftMouseDragged, at: CGPoint(x: 29, y: 20), in: window))
    #expect(view.selectedText == "A")
    // Act
    NotificationCenter.default.post(name: NSWindow.didResignKeyNotification, object: window)
    view.mouseDragged(with: mouseEvent(.leftMouseDragged, at: CGPoint(x: 99, y: 20), in: window))
    // Assert
    #expect(view.selectedText == "A")
}

private func sampleDocument() -> ImageTextDocument {
    ImageTextDocument(
        text: "ABC",
        words: [
            ImageTextRegion(
                range: NSRange(location: 0, length: 3), bounds: CGRect(x: 20, y: 20, width: 60, height: 20),
                line: 0)
        ])
}

@MainActor private final class SuspendedImageAnalysis {
    var requests: [CheckedContinuation<ImageTextDocument?, any Error>] = []
    func analyze(_ image: NSImage) async throws -> ImageTextDocument? {
        try await withCheckedThrowingContinuation { requests.append($0) }
    }
    func waitForRequests(_ count: Int) async {
        while requests.count < count { await Task.yield() }
    }
    func complete(_ index: Int, with document: ImageTextDocument) {
        requests[index].resume(returning: document)
    }
}
