import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_preferences_when_store_action_supplied_then_purchase_entry_and_quit_remain_usable() throws {
    // Arrange
    var purchasePresentations = 0
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
        shortcutController: makeTestShortcutController(),
        supportedLanguageCatalog: makeStubLanguageCatalog(),
        onShowSubscription: { purchasePresentations += 1 }
    )
    let content = try #require(controller.window?.contentView)
    content.layoutSubtreeIfNeeded()
    let subscription = try #require(findSubscriptionButtons(content).first { $0.accessibilityIdentifier() == "subscriptionButton" })
    let quit = try #require(findSubscriptionButtons(content).first { $0.accessibilityIdentifier() == "quitButton" })

    // Act
    let action = try #require(subscription.action)
    NSApplication.shared.sendAction(action, to: subscription.target, from: subscription)

    // Assert
    #expect(purchasePresentations == 1)
    #expect(subscription.isEnabled)
    #expect(quit.isEnabled)
    let subscriptionFrame = subscription.convert(subscription.bounds, to: content)
    let quitFrame = quit.convert(quit.bounds, to: content)
    #expect(!subscriptionFrame.intersects(quitFrame))
    #expect(content.bounds.contains(subscriptionFrame))
}

@Test @MainActor
func test_preferences_when_direct_distribution_then_does_not_show_purchase_entry() throws {
    // Arrange
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
        shortcutController: makeTestShortcutController(),
        supportedLanguageCatalog: makeStubLanguageCatalog()
    )
    let content = try #require(controller.window?.contentView)

    // Act
    content.layoutSubtreeIfNeeded()

    // Assert
    #expect(!findSubscriptionButtons(content).contains { $0.accessibilityIdentifier() == "subscriptionButton" })
}

@MainActor
private func findSubscriptionButtons(_ view: NSView) -> [NSButton] {
    (view as? NSButton).map { [$0] } ?? []
        + view.subviews.flatMap(findSubscriptionButtons)
}
