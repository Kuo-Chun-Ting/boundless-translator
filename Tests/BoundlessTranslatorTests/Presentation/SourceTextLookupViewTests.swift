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
