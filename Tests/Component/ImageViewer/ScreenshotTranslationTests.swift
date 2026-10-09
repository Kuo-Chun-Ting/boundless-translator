import AppKit
import Testing
@testable import BoundlessTranslator

@Test(arguments: ["A", "A B", "A complete sentence."]) @MainActor
func test_preview_when_textChanges_then_submitsExactSourceAndConfiguredLanguages(text: String) async throws {
    // Arrange
    let fixture = await ScreenshotPreviewFixture()
    defer { fixture.close() }
    // Act
    fixture.controller.update(fixture.target(text))
    // Assert
    #expect(fixture.coordinator.sourceText == text)
    #expect(fixture.coordinator.request?.sourceLanguageIdentifier == "en")
    #expect(fixture.coordinator.request?.targetLanguageIdentifier == "zh-Hant")
    #expect(fixture.controller.panel.isVisible)
}

@Test @MainActor
func test_preview_when_wordIsUnchanged_then_doesNotRestartTranslation() async throws {
    // Arrange
    let fixture = await ScreenshotPreviewFixture()
    defer { fixture.close() }
    fixture.controller.update(fixture.target("A"))
    let id = fixture.coordinator.request?.id
    // Act
    fixture.controller.update(fixture.target("A"))
    // Assert
    #expect(fixture.coordinator.request?.id == id)
}

@Test @MainActor
func test_preview_when_selectionExists_then_hoverCannotReplaceSelection() async throws {
    // Arrange
    let fixture = await ScreenshotPreviewFixture()
    defer { fixture.close() }
    fixture.imageView.selectAll(nil)
    let id = fixture.coordinator.request?.id
    // Act
    fixture.imageView.mouseMoved(with: mouseEvent(.mouseMoved, at: CGPoint(x: 15, y: 15), in: fixture.window))
    // Assert
    #expect(fixture.coordinator.sourceText == "A B")
    #expect(fixture.coordinator.request?.id == id)
}

@Test @MainActor
func test_preview_when_dragging_then_waitsUntilSelectionCompletes() async throws {
    // Arrange
    let fixture = await ScreenshotPreviewFixture()
    defer { fixture.close() }
    fixture.controller.update(fixture.target("A"))
    // Act
    fixture.imageView.mouseDown(with: mouseEvent(.leftMouseDown, at: CGPoint(x: 11, y: 15), in: fixture.window))
    fixture.imageView.mouseDragged(with: mouseEvent(.leftMouseDragged, at: CGPoint(x: 99, y: 15), in: fixture.window))
    // Assert
    #expect(fixture.coordinator.request == nil)
    #expect(!fixture.controller.panel.isVisible)
    // Act
    fixture.imageView.mouseUp(with: mouseEvent(.leftMouseUp, at: CGPoint(x: 99, y: 15), in: fixture.window))
    // Assert
    #expect(fixture.coordinator.sourceText == "A B")
}

@Test @MainActor
func test_previewLookup_when_translationIsPending_then_looksUpWholeSourceWithoutRestarting() async throws {
    // Arrange
    let fixture = await ScreenshotPreviewFixture()
    defer { fixture.close() }
    fixture.controller.update(fixture.target("A complete sentence."))
    let id = fixture.coordinator.request?.id
    // Act
    fixture.controller.showDefinition()
    // Assert
    #expect(fixture.lookups == ["A complete sentence."])
    #expect(fixture.coordinator.request?.id == id)
    #expect(fixture.controller.panel.isVisible)
}

@Test @MainActor
func test_previewSpeech_when_sourceChanges_then_stopsPreviousPlayback() async throws {
    // Arrange
    let fixture = await ScreenshotPreviewFixture()
    defer { fixture.close() }
    fixture.controller.update(fixture.target("A"))
    fixture.controller.toggleSpeech()
    #expect(fixture.mock_speech.played == ["A:en"])
    let stopCount = fixture.mock_speech.stops
    // Act
    fixture.controller.update(fixture.target("B"))
    // Assert
    #expect(fixture.mock_speech.stops > stopCount)
    #expect(fixture.controller.speech.activeRole == nil)
}

@Test @MainActor
func test_preview_when_imageIsReplaced_then_cancelsAndClosesCard() async throws {
    // Arrange
    let fixture = await ScreenshotPreviewFixture()
    defer { fixture.close() }
    fixture.controller.update(fixture.target("A"))
    // Act
    fixture.imageView.display(NSImage(size: CGSize(width: 200, height: 200)))
    // Assert
    #expect(fixture.coordinator.request == nil)
    #expect(!fixture.controller.panel.isVisible)
}

@Test @MainActor
func test_preview_when_accessIsDenied_then_doesNotShowOrTranslate() async throws {
    // Arrange
    let fixture = await ScreenshotPreviewFixture(authorize: { false })
    defer { fixture.close() }
    // Act
    fixture.controller.update(fixture.target("A"))
    // Assert
    #expect(fixture.coordinator.request == nil)
    #expect(!fixture.controller.panel.isVisible)
}

@Test @MainActor
func test_preview_when_accessExpiresBetweenWords_then_dropsPreviousRequest() async {
    // Arrange
    var allowed = true
    let fixture = await ScreenshotPreviewFixture(authorize: { allowed })
    defer { fixture.close() }
    fixture.controller.update(fixture.target("A"))
    // Act
    allowed = false
    fixture.controller.update(fixture.target("B"))
    fixture.controller.showDefinition()
    // Assert
    #expect(fixture.coordinator.request == nil)
    #expect(!fixture.controller.panel.isVisible)
    #expect(fixture.lookups.isEmpty)
}

@Test @MainActor
func test_previewLookup_when_nativeLookupReturns_then_allowsAnotherTarget() async {
    // Arrange
    let fixture = await ScreenshotPreviewFixture()
    defer { fixture.close() }
    fixture.controller.update(fixture.target("A"))
    fixture.controller.showDefinition()
    // Act
    fixture.controller.update(fixture.target("B"))
    // Assert
    #expect(fixture.coordinator.sourceText == "B")
}

@Test(arguments: ["workspace", "card"]) @MainActor
func test_preview_when_presentedWindowIsOpen_then_preservesTargetUntilWindowCloses(parent: String) async {
    // Arrange
    let fixture = await ScreenshotPreviewFixture()
    defer { fixture.close() }
    fixture.controller.update(fixture.target("A"))
    let requestID = fixture.coordinator.request?.id
    let child = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 300, height: 200),
                         styleMask: [.titled], backing: .buffered, defer: false)
    child.isReleasedWhenClosed = false
    let owner = parent == "workspace" ? fixture.window : fixture.controller.panel
    owner.addChildWindow(child, ordered: .above)
    child.orderFront(nil)
    defer {
        owner.removeChildWindow(child)
        child.orderOut(nil)
    }
    // Act: background hover must not replace the card during native UI.
    fixture.controller.update(fixture.target("B"))
    // Assert
    #expect(fixture.coordinator.sourceText == "A")
    #expect(fixture.coordinator.request?.id == requestID)
    #expect(fixture.controller.panel.isVisible)
    // Act: closing the native UI restores ordinary target changes.
    owner.removeChildWindow(child)
    child.orderOut(nil)
    fixture.controller.update(fixture.target("B"))
    // Assert
    #expect(fixture.coordinator.sourceText == "B")
}

@Test @MainActor
func test_previewCursor_when_dragLeavesText_then_arrowDoesNotClearSelection() async {
    // Arrange
    let fixture = await ScreenshotPreviewFixture()
    defer { fixture.close() }
    fixture.imageView.mouseDown(with: mouseEvent(.leftMouseDown, at: CGPoint(x: 11, y: 15), in: fixture.window))
    // Act
    fixture.imageView.mouseDragged(with: mouseEvent(.leftMouseDragged, at: CGPoint(x: 90, y: 15), in: fixture.window))
    // Assert
    #expect(fixture.imageView.cursor(atImagePoint: CGPoint(x: 90, y: 15)) == .iBeam)
    // Act
    fixture.imageView.mouseDragged(with: mouseEvent(.leftMouseDragged, at: CGPoint(x: 150, y: 15), in: fixture.window))
    // Assert
    #expect(fixture.imageView.cursor(atImagePoint: CGPoint(x: 150, y: 15)) == .arrow)
    #expect(fixture.imageView.selectedText == "A B")
}

@MainActor
final class ScreenshotPreviewFixture {
    let window: NSWindow
    let imageView: ImageTextView
    let coordinator: TranslationCoordinator
    let mock_speech = PreviewSpeechMock()
    var controller: ScreenshotTranslationController!
    var lookups: [String] = []

    init(authorize: @escaping @MainActor () -> Bool = { true }) async {
        (window, imageView) = await selectionFixture()
        coordinator = TranslationCoordinator(splitter: TranslationTextSplitter(targetCharacters: 7), authorize: authorize)
        let suite = "ScreenshotPreviewTests.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        let settings = TranslationSettings(defaults: defaults)
        settings.sourceLanguageIdentifier = "en"
        settings.targetLanguageIdentifier = "zh-Hant"
        controller = ScreenshotTranslationController(
            imageView: imageView, settings: settings,
            interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
            engine: makeStubTranslationEngine(), coordinator: coordinator,
            speechPlayer: mock_speech,
            showDefinition: { [weak self] _, text, _ in self?.lookups.append(text) })
        imageView.quickTranslation = controller
        defaults.removePersistentDomain(forName: suite)
    }

    func target(_ text: String) -> ImageTextPreviewTarget {
        ImageTextPreviewTarget(text: text, range: NSRange(location: 0, length: text.utf16.count),
                               bounds: CGRect(x: 10, y: 10, width: 110, height: 20))
    }

    func close() {
        controller.dismiss()
        window.close()
    }
}

@MainActor
final class PreviewSpeechMock: SpeechPlaying {
    var played: [String] = []
    var stops = 0
    func supports(languageIdentifier: String) -> Bool { !languageIdentifier.isEmpty }
    func play(text: String, languageIdentifier: String, completion: @escaping @MainActor () -> Void) {
        played.append("\(text):\(languageIdentifier)")
    }
    func stop() { stops += 1 }
}

@Test @MainActor
func test_previewHighlight_when_cardOpensAndCloses_then_marksOnlyItsSource() async throws {
    // Arrange
    let fixture = await ScreenshotPreviewFixture()
    defer { fixture.close() }
    let original = try previewImageData(fixture.imageView)
    // Act
    fixture.controller.update(fixture.target("A"))
    let highlighted = try previewImageData(fixture.imageView)
    fixture.controller.card.onPointerEntered?()
    // Assert
    #expect(highlighted != original)
    #expect(try previewImageData(fixture.imageView) == highlighted)
    #expect(fixture.imageView.selectedText.isEmpty)
    // Act
    fixture.controller.dismiss()
    // Assert
    #expect(try previewImageData(fixture.imageView) == original)
}

@Test @MainActor
func test_previewHighlight_when_textIsSelected_then_preservesSelectionColor() async throws {
    // Arrange
    let fixture = await ScreenshotPreviewFixture()
    defer { fixture.close() }
    fixture.imageView.selectAll(nil)
    let selected = try previewImageData(fixture.imageView)
    // Act
    fixture.controller.dismiss()
    // Assert
    #expect(try previewImageData(fixture.imageView) == selected)
    #expect(fixture.imageView.selectedText == "A B")
}

@MainActor
private func previewImageData(_ view: NSView) throws -> Data {
    let bitmap = try #require(view.bitmapImageRepForCachingDisplay(in: view.bounds))
    view.cacheDisplay(in: view.bounds, to: bitmap)
    return try #require(bitmap.representation(using: .png, properties: [:]))
}
