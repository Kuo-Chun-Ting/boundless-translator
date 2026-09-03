import AppKit
import SwiftUI
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_preferencesView_when_rendered_then_shows_usage_help_button() throws {
    // Arrange
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        shortcutController: makeTestShortcutController()
    )
    let contentView = try #require(controller.window?.contentView)

    // Act
    contentView.layoutSubtreeIfNeeded()
    let usageHelpButtons = findUsageViews(
        in: contentView,
        accessibilityIdentifier: "usageHelpButton"
    ).compactMap { $0 as? NSButton }

    // Assert
    #expect(usageHelpButtons.count == 1)
    #expect(usageHelpButtons.first?.bezelStyle == .helpButton)
}

@Test @MainActor
func test_usageGuideItems_when_created_then_describes_every_current_feature() {
    // Arrange
    let expectedIdentifiers = [
        "translateText",
        "translateImageText",
        "lookUp",
        "listen",
        "pinWindow",
    ]
    let expectedTitles = [
        "Translate Text",
        "Translate Image Text",
        "Look Up",
        "Listen",
        "Pin Window",
    ]
    let expectedIcons: [UsageGuideIcon] = [
        .systemSymbol(name: "text.cursor", clockwiseRotationDegrees: 0),
        .systemSymbol(name: "photo", clockwiseRotationDegrees: 0),
        .text("📖"),
        .systemSymbol(name: "speaker.wave.2.fill", clockwiseRotationDegrees: 0),
        .systemSymbol(name: "pin", clockwiseRotationDegrees: 45),
    ]

    // Act
    let items = UsageGuideItem.make(shortcut: .commandShiftT)

    // Assert
    #expect(items.map(\.id) == expectedIdentifiers)
    #expect(items.map(\.title) == expectedTitles)
    #expect(items.map(\.icon) == expectedIcons)
    #expect(items[0].description.contains("⇧⌘T"))
    #expect(items[1].description.components(separatedBy: "⇧⌘T").count == 3)
    #expect(
        items[2].description
            == "Select text in the translation panel, then click the book."
    )
}

@Test @MainActor
func test_usageGuideView_when_rendered_then_uses_readableWidth() {
    // Arrange
    let hostingView = NSHostingView(
        rootView: UsageGuideView(shortcut: .commandShiftT)
    )

    // Act
    hostingView.layoutSubtreeIfNeeded()

    // Assert
    #expect(abs(hostingView.fittingSize.width - 520) < 0.5)
}

@MainActor
private func findUsageViews(
    in view: NSView,
    accessibilityIdentifier: String
) -> [NSView] {
    let current = view.accessibilityIdentifier() == accessibilityIdentifier
        ? [view]
        : []
    return current + view.subviews.flatMap {
        findUsageViews(in: $0, accessibilityIdentifier: accessibilityIdentifier)
    }
}
