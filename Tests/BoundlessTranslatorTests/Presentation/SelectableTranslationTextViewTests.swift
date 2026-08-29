import AppKit
import SwiftUI
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_makeNSView_when_contentExceedsViewport_then_textCanScrollVertically() throws {
    // Arrange
    let text = Array(repeating: "A long translated line", count: 40)
        .joined(separator: "\n")
    let hostingView = NSHostingView(
        rootView: SelectableTranslationTextView(text: text)
    )
    hostingView.frame = NSRect(x: 0, y: 0, width: 200, height: 100)

    // Act
    hostingView.layoutSubtreeIfNeeded()
    let scrollView = try #require(
        descendants(of: NSScrollView.self, in: hostingView).first
    )
    let textView = try #require(scrollView.documentView as? NSTextView)
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
func test_makeNSView_when_contentFitsViewport_then_hidesVerticalScroller() throws {
    // Arrange
    let hostingView = NSHostingView(
        rootView: SelectableTranslationTextView(text: "Short translation")
    )
    hostingView.frame = NSRect(x: 0, y: 0, width: 200, height: 100)

    // Act
    hostingView.layoutSubtreeIfNeeded()
    let scrollView = try #require(
        descendants(of: NSScrollView.self, in: hostingView).first
    )

    // Assert
    #expect(!scrollView.hasVerticalScroller)
}

@MainActor
private func descendants<ViewType: NSView>(
    of type: ViewType.Type,
    in rootView: NSView
) -> [ViewType] {
    rootView.subviews.flatMap { subview in
        let current = (subview as? ViewType).map { [$0] } ?? []
        return current + descendants(of: type, in: subview)
    }
}
