import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_init_when_configuring_source_text_then_uses_primary_label_color() throws {
    // Arrange & Act
    let view = SourceTextLookupView()
    let scrollView = try #require(
        view.subviews.compactMap { $0 as? NSScrollView }.first
    )
    let textView = try #require(scrollView.documentView as? NSTextView)

    // Assert
    #expect(textView.textColor == .labelColor)
    #expect(textView.textContainer?.lineFragmentPadding == 0)
}

@Test @MainActor
func test_init_when_configuring_source_text_then_uses_system_serif_font() throws {
    // Arrange
    let view = SourceTextLookupView()
    let expectedDescriptor = try #require(
        NSFont.systemFont(ofSize: NSFont.systemFontSize)
            .fontDescriptor
            .withDesign(.serif)
    )
    let expectedFont = try #require(
        NSFont(
            descriptor: expectedDescriptor,
            size: NSFont.systemFontSize
        )
    )

    // Act
    let scrollView = try #require(
        view.subviews.compactMap { $0 as? NSScrollView }.first
    )
    let textView = try #require(scrollView.documentView as? NSTextView)

    // Assert
    #expect(textView.font?.fontName == expectedFont.fontName)
}

@Test @MainActor
func test_updateText_when_contentExceedsViewport_then_textCanScrollVertically() throws {
    // Arrange
    let view = SourceTextLookupView()
    view.frame = NSRect(x: 0, y: 0, width: 200, height: 100)
    let scrollView = try #require(
        view.subviews.compactMap { $0 as? NSScrollView }.first
    )
    let textView = try #require(scrollView.documentView as? NSTextView)

    // Act
    view.updateText(Array(repeating: "A long source line", count: 40).joined(separator: "\n"))
    view.layoutSubtreeIfNeeded()
    textView.layoutManager?.ensureLayout(for: textView.textContainer!)
    scrollView.tile()
    let maximumOffset = textView.frame.height - scrollView.contentSize.height
    scrollView.contentView.scroll(to: NSPoint(x: 0, y: min(20, maximumOffset)))
    scrollView.reflectScrolledClipView(scrollView.contentView)

    // Assert
    #expect(maximumOffset > 0)
    #expect(scrollView.contentView.bounds.minY > 0)
    #expect(!scrollView.autohidesScrollers)
}

@Test @MainActor
func test_updateText_when_contentFitsViewport_then_hidesVerticalScroller() throws {
    // Arrange
    let view = SourceTextLookupView()
    view.frame = NSRect(x: 0, y: 0, width: 200, height: 100)
    let scrollView = try #require(
        view.subviews.compactMap { $0 as? NSScrollView }.first
    )

    // Act
    view.updateText("Short source text")
    view.layoutSubtreeIfNeeded()

    // Assert
    #expect(!scrollView.hasVerticalScroller)
}

@Test @MainActor
func test_scrollViewBoundsDidChange_when_selectionLeavesViewport_then_hidesLookupAction() throws {
    // Arrange
    let view = SourceTextLookupView()
    view.frame = NSRect(x: 0, y: 0, width: 200, height: 100)
    _ = makeWindow(hosting: view)
    view.updateText(
        (["Target selection"] + Array(repeating: "A long source line", count: 40))
            .joined(separator: "\n")
    )
    view.updateSelection(NSRange(location: 0, length: 16))
    view.layoutSubtreeIfNeeded()
    let scrollView = try #require(
        view.subviews.compactMap { $0 as? NSScrollView }.first
    )
    let textView = try #require(scrollView.documentView as? NSTextView)
    textView.layoutManager?.ensureLayout(for: textView.textContainer!)
    let maximumOffset = textView.frame.height - scrollView.contentSize.height

    // Act
    scrollView.contentView.scroll(to: NSPoint(x: 0, y: maximumOffset))
    scrollView.reflectScrolledClipView(scrollView.contentView)

    // Assert
    #expect(!view.isLookupActionVisible)
}

@Test @MainActor
func test_scrollViewBoundsDidChange_when_selectionReturnsToViewport_then_showsLookupAction() throws {
    // Arrange
    let view = SourceTextLookupView()
    view.frame = NSRect(x: 0, y: 0, width: 200, height: 100)
    _ = makeWindow(hosting: view)
    view.updateText(
        (["Target selection"] + Array(repeating: "A long source line", count: 40))
            .joined(separator: "\n")
    )
    view.updateSelection(NSRange(location: 0, length: 16))
    view.layoutSubtreeIfNeeded()
    let scrollView = try #require(
        view.subviews.compactMap { $0 as? NSScrollView }.first
    )
    let textView = try #require(scrollView.documentView as? NSTextView)
    textView.layoutManager?.ensureLayout(for: textView.textContainer!)
    let maximumOffset = textView.frame.height - scrollView.contentSize.height
    scrollView.contentView.scroll(to: NSPoint(x: 0, y: maximumOffset))
    scrollView.reflectScrolledClipView(scrollView.contentView)

    // Act
    scrollView.contentView.scroll(to: .zero)
    scrollView.reflectScrolledClipView(scrollView.contentView)

    // Assert
    #expect(view.isLookupActionVisible)
}

@Test @MainActor
func test_init_when_configuring_lookup_action_then_uses_colored_open_book() throws {
    // Arrange
    let view = SourceTextLookupView()
    let window = makeWindow(hosting: view)
    view.updateText("She felt strong emotions.")

    // Act
    view.updateSelection(NSRange(location: 9, length: 15))
    view.layoutSubtreeIfNeeded()
    let lookupButton = try #require(
        window.contentView?.subviews.compactMap { $0 as? NSButton }.first
    )

    // Assert
    #expect(lookupButton.title == "📖")
    #expect(lookupButton.image == nil)
}

@Test @MainActor
func test_updateSelection_when_lookupActionMoves_then_keeps_lookup_action_hittable_at_new_position() throws {
    // Arrange
    let view = SourceTextLookupView()
    let window = makeWindow(hosting: view)
    view.updateText("First line\nSecond line\nThird line\nFourth line")
    view.updateSelection(NSRange(location: 0, length: 10))
    view.layoutSubtreeIfNeeded()
    let contentView = try #require(window.contentView)
    let lookupButton = try #require(
        contentView.subviews.compactMap { $0 as? PointingHandButton }.first
    )
    let firstCenter = NSPoint(
        x: lookupButton.frame.midX,
        y: lookupButton.frame.midY
    )

    // Act
    view.updateSelection(NSRange(location: 34, length: 11))
    view.layoutSubtreeIfNeeded()
    let secondCenter = NSPoint(
        x: lookupButton.frame.midX,
        y: lookupButton.frame.midY
    )

    // Assert
    #expect(firstCenter != secondCenter)
    #expect(contentView.hitTest(firstCenter) !== lookupButton)
    #expect(contentView.hitTest(secondCenter) === lookupButton)
}

@Test @MainActor
func test_updateSelection_when_lookupActionMovesToFifthLine_then_buttonOwnsHitTestAtItsNewPosition() throws {
    // Arrange
    let view = SourceTextLookupView()
    let window = makeWindow(hosting: view)
    view.updateText(
        "First line\nSecond line\nThird line\nFourth line\nFifth line"
    )
    view.updateSelection(NSRange(location: 46, length: 10))
    view.layoutSubtreeIfNeeded()
    let contentView = try #require(window.contentView)
    let lookupButton = try #require(
        contentView.subviews.compactMap { $0 as? PointingHandButton }.first
    )
    let buttonCenter = NSPoint(
        x: lookupButton.frame.midX,
        y: lookupButton.frame.midY
    )

    // Act
    let hitView = contentView.hitTest(buttonCenter)

    // Assert
    #expect(hitView === lookupButton)
}

@Test @MainActor
func test_updateSelection_when_selectionIsOnFirstLine_then_placesBookTwoPointsAboveSelection() throws {
    // Arrange
    let view = SourceTextLookupView()
    let window = makeWindow(hosting: view)
    view.updateText("First line\nSecond line\nThird line")
    let selectedRange = NSRange(location: 0, length: 10)

    // Act
    view.updateSelection(selectedRange)
    view.layoutSubtreeIfNeeded()
    let contentView = try #require(window.contentView)
    let scrollView = try #require(
        view.subviews.compactMap { $0 as? NSScrollView }.first
    )
    let textView = try #require(scrollView.documentView as? NSTextView)
    let lookupButton = try #require(
        contentView.subviews.compactMap { $0 as? PointingHandButton }.first
    )
    let selectionScreenRect = textView.firstRect(
        forCharacterRange: selectedRange,
        actualRange: nil
    )
    let buttonWindowRect = contentView.convert(lookupButton.frame, to: nil)
    let buttonScreenRect = window.convertToScreen(buttonWindowRect)

    // Assert
    #expect(buttonScreenRect.minY - selectionScreenRect.maxY == 2)
}

@Test @MainActor
func test_updateSelection_when_selectionIsOnMiddleLine_then_alignsBookWithPreviousVisualLine() throws {
    // Arrange
    let view = SourceTextLookupView()
    let window = makeWindow(hosting: view)
    view.updateText("First line\nSecond line\nThird line")
    view.layoutSubtreeIfNeeded()
    let textView = try sourceTextView(in: view)
    let previousLine = try #require(
        lineFragments(in: textView, window: window).first
    )

    // Act
    view.updateSelection(NSRange(location: 11, length: 11))
    view.layoutSubtreeIfNeeded()
    let bookRect = try lookupButtonScreenRect(in: window)

    // Assert
    #expect(bookRect.midY == previousLine.screenRect.midY)
}

@Test @MainActor
func test_updateSelection_when_selectionIsOnLastLine_then_alignsBookWithPreviousVisualLine() throws {
    // Arrange
    let view = SourceTextLookupView()
    let window = makeWindow(hosting: view)
    view.updateText("First line\nSecond line\nThird line")
    view.layoutSubtreeIfNeeded()
    let textView = try sourceTextView(in: view)
    let fragments = lineFragments(in: textView, window: window)
    let previousLine = try #require(fragments.dropFirst().first)

    // Act
    view.updateSelection(NSRange(location: 23, length: 10))
    view.layoutSubtreeIfNeeded()
    let bookRect = try lookupButtonScreenRect(in: window)

    // Assert
    #expect(bookRect.midY == previousLine.screenRect.midY)
}

@Test @MainActor
func test_updateSelection_when_textWraps_then_alignsBookWithPreviousVisualLine() throws {
    // Arrange
    let view = SourceTextLookupView()
    let window = makeWindow(hosting: view)
    view.updateText(
        "Alpha beta gamma delta epsilon zeta eta theta iota kappa lambda"
    )
    view.layoutSubtreeIfNeeded()
    let textView = try sourceTextView(in: view)
    let fragments = lineFragments(in: textView, window: window)
    let selectedLine = try #require(fragments.dropFirst(2).first)
    let previousLine = try #require(fragments.dropFirst().first)
    let selectedRange = NSRange(
        location: selectedLine.characterRange.location,
        length: min(5, selectedLine.characterRange.length)
    )

    // Act
    view.updateSelection(selectedRange)
    view.layoutSubtreeIfNeeded()
    let bookRect = try lookupButtonScreenRect(in: window)

    // Assert
    #expect(fragments.count >= 3)
    #expect(bookRect.midY == previousLine.screenRect.midY)
}

@Test @MainActor
func test_updateSelection_when_selection_contains_text_then_shows_lookup_action() {
    // Arrange
    let view = SourceTextLookupView()
    view.updateText("She felt strong emotions.")

    // Act
    view.updateSelection(NSRange(location: 9, length: 15))

    // Assert
    #expect(view.isLookupActionVisible)
}

@Test @MainActor
func test_updateSelection_when_selection_is_empty_then_hides_lookup_action() {
    // Arrange
    let view = SourceTextLookupView()
    view.updateText("She felt strong emotions.")
    view.updateSelection(NSRange(location: 9, length: 15))

    // Act
    view.updateSelection(NSRange(location: 9, length: 0))

    // Assert
    #expect(!view.isLookupActionVisible)
}

@Test @MainActor
func test_makeFirstResponder_when_focusMovesToTranslationText_then_hidesLookupAction() throws {
    // Arrange
    let view = SourceTextLookupView()
    let window = makeTranslationPanel(hosting: view)
    view.updateText("She felt strong emotions.")
    view.layoutSubtreeIfNeeded()
    let scrollView = try #require(
        view.subviews.compactMap { $0 as? NSScrollView }.first
    )
    let sourceTextView = try #require(
        scrollView.documentView as? NSTextView
    )
    let translationTextView = NSTextView(
        frame: NSRect(x: 220, y: 20, width: 160, height: 100)
    )
    window.contentView?.addSubview(translationTextView)
    #expect(window.makeFirstResponder(sourceTextView))
    #expect(window.firstResponder === sourceTextView)
    view.updateSelection(NSRange(location: 9, length: 15))
    #expect(view.isLookupActionVisible)

    // Act
    #expect(window.makeFirstResponder(translationTextView))
    #expect(window.firstResponder === translationTextView)

    // Assert
    #expect(!view.isLookupActionVisible)
}

@Test
func test_origin_when_preferred_position_exceeds_bounds_then_keeps_button_inside_bounds() {
    // Arrange
    let positioner = LookupActionPositioner(
        horizontalMargin: 4,
        verticalGap: 4
    )
    let selectionRect = CGRect(x: 80, y: 80, width: 40, height: 15)

    // Act
    let origin = positioner.origin(
        selectionRect: selectionRect,
        buttonSize: CGSize(width: 28, height: 28),
        bounds: CGRect(x: 0, y: 0, width: 200, height: 100)
    )

    // Assert
    #expect(origin.y == 68)
    #expect(origin.y + 28 <= 96)
}

@Test @MainActor
func test_layout_when_lookup_action_is_hidden_then_uses_card_content_padding() throws {
    // Arrange
    let view = SourceTextLookupView()
    view.setFrameSize(NSSize(width: 200, height: 100))

    // Act
    view.layoutSubtreeIfNeeded()
    let scrollView = try #require(
        view.subviews.compactMap { $0 as? NSScrollView }.first
    )

    // Assert
    #expect(
        scrollView.frame
            == view.bounds.insetBy(
                dx: TranslationPanelStyle.cardContentPadding,
                dy: TranslationPanelStyle.cardContentPadding
            )
    )
}

@Test @MainActor
func test_updateSelection_when_selection_contains_text_then_places_lookup_action_in_window_overlay() throws {
    // Arrange
    let view = SourceTextLookupView()
    let window = makeWindow(hosting: view)
    view.updateText("She felt strong emotions.")

    // Act
    view.updateSelection(NSRange(location: 9, length: 15))
    view.layoutSubtreeIfNeeded()
    let contentView = try #require(window.contentView)
    let lookupButton = try #require(
        contentView.subviews.compactMap { $0 as? NSButton }.first
    )

    // Assert
    #expect(lookupButton.superview === contentView)
    #expect(
        contentView.hitTest(
            NSPoint(x: lookupButton.frame.midX, y: lookupButton.frame.midY)
        ) === lookupButton
    )
}

@Test @MainActor
func test_performLookup_when_selection_has_outer_whitespace_then_presents_trimmed_range() {
    // Arrange
    let mock_presenter = DictionaryDefinitionPresenterMock()
    let view = SourceTextLookupView(dictionaryPresenter: mock_presenter)
    view.updateText("She felt  strong emotions  today.")
    view.updateSelection(NSRange(location: 8, length: 19))

    // Act
    view.performLookup()

    // Assert
    #expect(mock_presenter.receivedRanges == [NSRange(location: 10, length: 15)])
}

@MainActor
private final class DictionaryDefinitionPresenterMock: DictionaryDefinitionPresenting {
    private(set) var receivedRanges: [NSRange] = []

    func showDefinition(
        in textView: NSTextView,
        selectedRange: NSRange
    ) {
        receivedRanges.append(selectedRange)
    }
}

private struct LineFragmentSnapshot {
    let characterRange: NSRange
    let screenRect: NSRect
}

@MainActor
private func sourceTextView(
    in view: SourceTextLookupView
) throws -> NSTextView {
    let scrollView = try #require(
        view.subviews.compactMap { $0 as? NSScrollView }.first
    )
    return try #require(scrollView.documentView as? NSTextView)
}

@MainActor
private func lookupButtonScreenRect(in window: NSWindow) throws -> NSRect {
    let contentView = try #require(window.contentView)
    let lookupButton = try #require(
        contentView.subviews.compactMap { $0 as? PointingHandButton }.first
    )
    let buttonWindowRect = contentView.convert(lookupButton.frame, to: nil)
    return window.convertToScreen(buttonWindowRect)
}

@MainActor
private func lineFragments(
    in textView: NSTextView,
    window: NSWindow
) -> [LineFragmentSnapshot] {
    guard
        let layoutManager = textView.layoutManager,
        let textContainer = textView.textContainer
    else {
        return []
    }

    layoutManager.ensureLayout(for: textContainer)
    let glyphRange = layoutManager.glyphRange(for: textContainer)
    var fragments: [LineFragmentSnapshot] = []
    layoutManager.enumerateLineFragments(
        forGlyphRange: glyphRange
    ) { _, usedRect, _, lineGlyphRange, _ in
        let textViewRect = usedRect.offsetBy(
            dx: textView.textContainerOrigin.x,
            dy: textView.textContainerOrigin.y
        )
        let windowRect = textView.convert(textViewRect, to: nil)
        fragments.append(
            LineFragmentSnapshot(
                characterRange: layoutManager.characterRange(
                    forGlyphRange: lineGlyphRange,
                    actualGlyphRange: nil
                ),
                screenRect: window.convertToScreen(windowRect)
            )
        )
    }
    return fragments
}

@MainActor
private func makeWindow(hosting view: SourceTextLookupView) -> NSWindow {
    let contentView = NSView(
        frame: NSRect(x: 0, y: 0, width: 400, height: 240)
    )
    let window = NSWindow(
        contentRect: contentView.bounds,
        styleMask: .borderless,
        backing: .buffered,
        defer: false
    )
    window.contentView = contentView
    view.frame = NSRect(x: 20, y: 20, width: 200, height: 100)
    contentView.addSubview(view)
    return window
}

@MainActor
private func makeTranslationPanel(
    hosting view: SourceTextLookupView
) -> TranslationPanel {
    let contentView = NSView(
        frame: NSRect(x: 0, y: 0, width: 400, height: 240)
    )
    let panel = TranslationPanel(contentSize: contentView.bounds.size)
    panel.contentView = contentView
    view.frame = NSRect(x: 20, y: 20, width: 200, height: 100)
    contentView.addSubview(view)
    return panel
}
