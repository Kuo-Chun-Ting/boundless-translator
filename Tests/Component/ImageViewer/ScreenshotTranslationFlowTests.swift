import AppKit
import SwiftUI
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_previewResult_when_previousRequestReturnsLast_then_keepsCurrentCard() async throws {
    // Arrange
    let fixture = await ScreenshotPreviewFixture()
    defer { fixture.close() }
    fixture.controller.update(fixture.target("A"))
    let oldRequest = try #require(fixture.coordinator.request)
    let stub_oldRunner = PreviewPendingRunner()
    let oldTask = Task { await fixture.coordinator.translate(oldRequest, using: stub_oldRunner) }
    await stub_oldRunner.waitForRequest()
    // Act
    fixture.controller.update(fixture.target("B"))
    await fixture.coordinator.translate(try #require(fixture.coordinator.request), using: PreviewResultRunner(text: "新的"))
    stub_oldRunner.finish("過期")
    await oldTask.value
    // Assert
    #expect(fixture.controller.card.textView.string == "新的")
    #expect(fixture.coordinator.sourceText == "B")
}

@Test @MainActor
func test_previewResult_when_closedDuringTranslation_then_lateReplyCannotReopenCard() async throws {
    // Arrange
    let fixture = await ScreenshotPreviewFixture()
    defer { fixture.close() }
    fixture.controller.update(fixture.target("A"))
    let stub_runner = PreviewPendingRunner()
    let task = Task { await fixture.coordinator.translate(try! #require(fixture.coordinator.request), using: stub_runner) }
    await stub_runner.waitForRequest()
    // Act
    fixture.controller.dismiss()
    stub_runner.finish("過期")
    await task.value
    // Assert
    #expect(!fixture.controller.panel.isVisible)
    #expect(fixture.controller.card.textView.string.isEmpty)
}

@Test @MainActor
func test_previewResult_when_laterChunkFails_then_keepsTranslatedTextInCard() async throws {
    // Arrange
    let fixture = await ScreenshotPreviewFixture()
    defer { fixture.close() }
    fixture.controller.update(fixture.target("First.\nSecond."))
    let mock_runner = PreviewFailingChunkRunner()
    // Act
    await fixture.coordinator.translate(try #require(fixture.coordinator.request), using: mock_runner)
    // Assert
    #expect(mock_runner.requests == ["First.\n", "Second."])
    #expect(fixture.controller.card.textView.string == "第一句。")
    #expect(fixture.coordinator.status == .failed(.languageNotInstalled))
}

@Test @MainActor
func test_previewResult_when_firstChunkFails_then_retryPreservesOriginalRequest() async throws {
    // Arrange
    let fixture = await ScreenshotPreviewFixture()
    defer { fixture.close() }
    fixture.controller.update(fixture.target("A"))
    await fixture.coordinator.translate(try #require(fixture.coordinator.request),
                                        using: PreviewResultRunner(error: .languageNotInstalled))
    #expect(fixture.controller.card.textView.string.isEmpty)
    #expect(fixture.coordinator.status == .failed(.languageNotInstalled))
    // Act
    fixture.controller.retry()
    // Assert
    #expect(fixture.coordinator.status == .translating)
    #expect(fixture.coordinator.sourceText == "A")
}

@Test @MainActor
func test_previewResult_when_appleReportsUserCancellation_then_closesOnlyCard() async throws {
    // Arrange
    let fixture = await ScreenshotPreviewFixture()
    defer { fixture.close() }
    fixture.window.orderFront(nil)
    fixture.imageView.selectAll(nil)
    // Act
    await fixture.coordinator.translate(try #require(fixture.coordinator.request), using: PreviewCancelledRunner())
    // Assert
    #expect(!fixture.controller.panel.isVisible)
    #expect(fixture.window.isVisible)
    #expect(fixture.imageView.selectedText == "A B")
    // Act: incidental motion over the preserved selection must not prompt again.
    let cancelled = fixture.target("A B")
    fixture.controller.update(cancelled)
    // Assert
    #expect(fixture.coordinator.request == nil)
    #expect(!fixture.controller.panel.isVisible)
}

@Test(arguments: [NSAppearance.Name.aqua, .darkAqua], [false, true]) @MainActor
func test_previewLayout_when_appearanceAndLengthVary_then_textScrollsWithoutMovingActions(
    appearance: NSAppearance.Name, longText: Bool
) async throws {
    do {
        // Arrange
        let text = longText ? String(repeating: "這是很長的翻譯內容。", count: 250) : "檔案"
        let fixture = await ScreenshotPreviewFixture()
        defer { fixture.close() }
        fixture.window.appearance = NSAppearance(named: appearance)
        fixture.controller.update(fixture.target("A"))
        // Act
        await fixture.coordinator.translate(try #require(fixture.coordinator.request), using: PreviewResultRunner(text: text))
        fixture.controller.panel.contentView?.layoutSubtreeIfNeeded()
        let card = fixture.controller.card
        // Assert
        #expect(card.textView.string == text)
        let existingTranslationText = TranslationTextViewFactory.make()
        existingTranslationText.string = text
        #expect(card.textView.font!.pointSize > existingTranslationText.font!.pointSize)
        #expect(card.lookupButton.title == LookupActionOverlay.bookIcon)
        #expect(card.speechButton.frame.size == CGSize(width: 28, height: 28))
        #expect(card.lookupButton.frame.size == card.speechButton.frame.size)
        #expect(card.lookupButton.frame.minY == card.speechButton.frame.minY)
        #expect(!card.scrollView.frame.intersects(card.speechButton.frame))
        #expect(card.scrollView.frame.maxX < card.speechButton.frame.minX)
        #expect(card.bounds.contains(card.scrollView.frame))
        #expect(card.bounds.height <= 400)
        let firstGlyph = card.textView.layoutManager!.boundingRect(
            forGlyphRange: NSRange(location: 0, length: 1), in: card.textView.textContainer!)
        let firstLine = card.scrollView.documentView!.convert(firstGlyph, from: card.textView)
        #expect(card.scrollView.documentVisibleRect.intersects(firstLine),
                "New results must start at the first line")
        if text.count > 100 {
            #expect(card.textView.frame.height > card.scrollView.contentSize.height)
            card.scrollView.contentView.scroll(to: CGPoint(x: 0, y: 200))
            let visibleText = card.textView.convert(card.textView.visibleRect, to: card)
            #expect(card.scrollView.frame.contains(visibleText),
                    "Scrolled text must stay inside the viewport, away from padding and actions")
        } else {
            #expect(card.bounds.width < 200, "Short translations must remain compact")
            #expect(card.textView.frame.height <= card.scrollView.contentSize.height,
                    "A short translation should fit without scrolling")
        }
    }
}

@Test @MainActor
func test_previewLayout_when_failureMessageIsLong_then_keepsFullMessageScrollable() async throws {
    // Arrange
    let fixture = await ScreenshotPreviewFixture()
    defer { fixture.close() }
    fixture.controller.update(fixture.target("A"))
    // Act
    await fixture.coordinator.translate(try #require(fixture.coordinator.request), using: PreviewResultRunner(
        error: .unexpected(String(repeating: "Service unavailable. ", count: 80))))
    fixture.controller.panel.contentView?.layoutSubtreeIfNeeded()
    let card = fixture.controller.card
    func findFailure(in view: NSView) -> NSHostingView<AnyView>? {
        if let failure = view as? NSHostingView<AnyView> { return failure }
        return view.subviews.lazy.compactMap { findFailure(in: $0) }.first
    }
    let failure = try #require(findFailure(in: card))
    // Assert
    #expect(failure.frame.height >= failure.fittingSize.height)
    #expect(failure.enclosingScrollView != nil)
    #expect(card.bounds.height <= 400)
    #expect(card.speechButton.frame.minY > 0)
    #expect(!card.speechButton.frame.intersects(card.scrollView.frame))
}

@Test @MainActor
func test_previewSpeech_when_clickedTwice_then_stopsReadingWithoutRetranslating() async {
    // Arrange
    let fixture = await ScreenshotPreviewFixture()
    defer { fixture.close() }
    fixture.controller.update(fixture.target("A"))
    let id = fixture.coordinator.request?.id
    fixture.controller.toggleSpeech()
    // Act
    fixture.controller.toggleSpeech()
    // Assert
    #expect(fixture.controller.speech.activeRole == nil)
    #expect(fixture.mock_speech.played == ["A:en"])
    #expect(fixture.coordinator.request?.id == id)
}

private struct PreviewResultRunner: TranslationRunning {
    var text = ""
    var error: TranslationFailure?
    func translate(_ request: TranslationRequest) async throws -> TranslationOutput {
        if let error { throw error }
        return TranslationOutput(translatedText: text, sourceLanguageIdentifier: "en", targetLanguageIdentifier: "zh-Hant")
    }
}

private struct PreviewCancelledRunner: TranslationRunning {
    func translate(_ request: TranslationRequest) async throws -> TranslationOutput { throw CocoaError(.userCancelled) }
}

@MainActor
private final class PreviewFailingChunkRunner: TranslationRunning {
    var requests: [String] = []
    func translate(_ request: TranslationRequest) async throws -> TranslationOutput {
        requests.append(request.text)
        if requests.count > 1 { throw TranslationFailure.languageNotInstalled }
        return TranslationOutput(translatedText: "第一句。", sourceLanguageIdentifier: "en", targetLanguageIdentifier: "zh-Hant")
    }
}

@MainActor
private final class PreviewPendingRunner: TranslationRunning {
    private var continuation: CheckedContinuation<TranslationOutput, Error>?
    private var started: CheckedContinuation<Void, Never>?
    func translate(_ request: TranslationRequest) async throws -> TranslationOutput {
        try await withCheckedThrowingContinuation {
            continuation = $0
            started?.resume()
            started = nil
        }
    }
    func waitForRequest() async {
        if continuation == nil { await withCheckedContinuation { started = $0 } }
    }
    func finish(_ text: String) {
        continuation?.resume(returning: TranslationOutput(translatedText: text,
            sourceLanguageIdentifier: "en", targetLanguageIdentifier: "zh-Hant"))
        continuation = nil
    }
}

@Test @MainActor
func test_sendEvent_when_pointerLeavesCardControls_then_restoresCursorForCurrentRegion() {
    // Arrange
    let panel = ScreenshotTranslationPanel()
    let card = ScreenshotTranslationCard(frame: .zero)
    card.textView.string = "Translation"
    panel.install(card)
    panel.setFrame(CGRect(x: 0, y: 0, width: 200, height: 120), display: false)
    panel.contentView?.layoutSubtreeIfNeeded()
    defer { panel.close(); NSCursor.arrow.set() }
    let blank = CGPoint(x: 190, y: 10)
    let text = card.textView.convert(CGPoint(x: 3, y: 3), to: card)
    let positions: [(CGPoint, NSCursor)] = [
        (CGPoint(x: card.speechButton.frame.midX, y: card.speechButton.frame.midY), .pointingHand), (blank, .arrow),
        (CGPoint(x: card.lookupButton.frame.midX, y: card.lookupButton.frame.midY), .pointingHand), (blank, .arrow),
        (text, .iBeam), (blank, .arrow)
    ]
    // Act & Assert
    for (point, expected) in positions {
        let event = NSEvent.mouseEvent(with: .mouseMoved,
            location: card.convert(point, to: nil), modifierFlags: [], timestamp: 0,
            windowNumber: panel.windowNumber, context: nil, eventNumber: 0,
            clickCount: 0, pressure: 0)!
        panel.sendEvent(event)
        #expect(NSCursor.current == expected)
    }
}

@Test @MainActor
func test_positionCard_when_shownAboveSource_then_reservesSpaceForPointerBelowContent() async throws {
    // Arrange
    let fixture = await ScreenshotPreviewFixture()
    defer { fixture.close() }
    // Act
    fixture.controller.update(fixture.target("A"))
    fixture.controller.panel.contentView?.layoutSubtreeIfNeeded()
    let card = fixture.controller.card
    let content = card.convert(card.bounds, to: nil)
    // Assert: the arrow sits outside the content, so it cannot overlap text or controls.
    #expect(content.minY >= 10)
    #expect(fixture.controller.panel.frame.height >= card.bounds.height + 10)
}

@Test @MainActor
func test_previewHover_when_pointerEntersCardBeforePendingWord_then_keepsCurrentWord() async throws {
    // Arrange
    let fixture = await ScreenshotPreviewFixture()
    defer { fixture.close() }
    fixture.controller.update(fixture.target("A"))
    fixture.controller.hover(fixture.target("B"))
    // Act
    fixture.controller.card.onPointerEntered?()
    try await Task.sleep(for: .milliseconds(350))
    // Assert
    #expect(fixture.coordinator.sourceText == "A")
}

@Test(arguments: [false, true])
func test_bubblePath_when_pointerChangesEdge_then_pointsTowardSource(pointsUp: Bool) {
    // Arrange
    let rect = CGRect(x: 0, y: 0, width: 200, height: 70)
    // Act
    let path = ScreenshotTranslationBubble(pointerX: 90, pointsUp: pointsUp).path(in: rect)
    // Assert: only the pointer reaches into the reserved strip.
    let tipY: CGFloat = pointsUp ? 2 : 68
    #expect(path.contains(CGPoint(x: 90, y: tipY)))
    #expect(!path.contains(CGPoint(x: 50, y: tipY)))
    #expect(path.contains(CGPoint(x: 50, y: 35)))
    #expect(rect.contains(path.boundingRect))
}

@Test(arguments: [CGFloat(-100), CGFloat(300)])
func test_bubblePath_when_anchorBeyondCardEdge_then_keepsPointerInsideOutline(anchorX: CGFloat) {
    // Arrange
    let rect = CGRect(x: 0, y: 0, width: 200, height: 70)
    // Act
    let path = ScreenshotTranslationBubble(pointerX: anchorX, pointsUp: false).path(in: rect)
    // Assert
    #expect(rect.contains(path.boundingRect))
    #expect(path.contains(CGPoint(x: anchorX < 0 ? 34 : 166, y: 68)))
}

@Test @MainActor
func test_positionCard_when_belowSource_then_reservesPointerAboveContent() {
    // Arrange
    let panel = ScreenshotTranslationPanel()
    let card = ScreenshotTranslationCard(frame: .zero)
    panel.install(card)
    panel.setFrame(CGRect(x: 100, y: 100, width: 200, height: 70), display: false)
    defer { panel.close() }
    // Act
    panel.point(to: CGRect(x: 180, y: 180, width: 20, height: 20))
    panel.contentView?.layoutSubtreeIfNeeded()
    // Assert
    let content = card.convert(card.bounds, to: nil)
    #expect(content.minY == 0)
    #expect(content.maxY <= 60)
}
