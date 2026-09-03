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

@Test @MainActor
func test_quitButton_when_clicked_then_requests_application_termination() throws {
    // Arrange
    let terminationSpy = TerminationSpy()
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        shortcutController: makeTestShortcutController(),
        quitApplication: {
            terminationSpy.request()
        }
    )
    let contentView = try #require(controller.window?.contentView)
    contentView.layoutSubtreeIfNeeded()
    let quitButton = try #require(
        findViews(
            in: contentView,
            accessibilityIdentifier: "quitButton"
        ).compactMap { $0 as? NSButton }.first
    )

    // Act
    quitButton.performClick(nil)

    // Assert
    #expect(quitButton.title == "Quit")
    #expect(terminationSpy.didRequestTermination)
}

@MainActor
private final class TerminationSpy {
    private(set) var didRequestTermination = false

    func request() {
        didRequestTermination = true
    }
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
