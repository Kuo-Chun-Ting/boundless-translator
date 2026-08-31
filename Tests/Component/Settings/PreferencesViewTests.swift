import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_preferencesView_when_rendered_then_containsCurrentShortcutRecorder() throws {
    // Arrange
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        shortcutController: makeTestShortcutController()
    )
    let contentView = try #require(controller.window?.contentView)

    // Act
    contentView.layoutSubtreeIfNeeded()
    let recorders = findViews(
            in: contentView,
            accessibilityIdentifier: "shortcutRecorder"
        ).compactMap { $0 as? NSButton }
    let recorder = try #require(recorders.first)

    // Assert
    #expect(recorders.count == 1)
    #expect(recorder.title == "⇧⌘T")
}

@MainActor
private func findViews(
    in view: NSView,
    accessibilityIdentifier: String
) -> [NSView] {
    let current = view.accessibilityIdentifier() == accessibilityIdentifier
        ? [view]
        : []
    return current + view.subviews.flatMap {
        findViews(in: $0, accessibilityIdentifier: accessibilityIdentifier)
    }
}
