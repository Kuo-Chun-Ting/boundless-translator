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
    let recorder = try #require(
        findView(
            in: contentView,
            accessibilityIdentifier: "shortcutRecorder"
        ) as? NSButton
    )

    // Assert
    #expect(recorder.title == "⇧⌘T")
}

@MainActor
private func findView(
    in view: NSView,
    accessibilityIdentifier: String
) -> NSView? {
    if view.accessibilityIdentifier() == accessibilityIdentifier {
        return view
    }
    return view.subviews.lazy.compactMap {
        findView(in: $0, accessibilityIdentifier: accessibilityIdentifier)
    }.first
}
