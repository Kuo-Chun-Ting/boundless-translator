import AppKit
import StoreKit
import SwiftUI
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_subscriptionWindow_when_configurationIsMissing_thenSizesToItsContent() throws {
    // Arrange
    let access = SubscriptionAccessController(productID: "annual", provider: LayoutEntitlementsStub())
    let controller = SubscriptionWindowController(
        access: access, interfaceLanguageSettings: makeTestInterfaceLanguageSettings()
    )
    let window = try #require(controller.window)
    let content = try #require(window.contentView)

    // Act
    content.layoutSubtreeIfNeeded()

    // Assert
    #expect(window.contentLayoutRect.height >= content.fittingSize.height - 1)
    #expect(window.contentLayoutRect.height <= content.fittingSize.height + 1)
}

@MainActor
private final class LayoutEntitlementsStub: SubscriptionProviding {
    var entitlements: [SubscriptionEntitlement] = []
    func loadEntitlements() async throws -> [SubscriptionEntitlement] { entitlements }
    func observeChanges(_ onChange: @escaping @MainActor @Sendable () async -> Void) async {}
}

@Test(arguments: InterfaceLanguageCatalog.languageIdentifiers, [false, true]) @MainActor
func test_subscriptionContent_when_localized_thenFitsContentWithoutFixedHeight(language: String, subscribed: Bool) async throws {
    // Arrange
    var fixture = SubscriptionViewFixture(language: language, subscribed: subscribed)
    fixture.offer.freeTrialPeriod = DateComponents(month: 1)
    await fixture.access.refresh()
    let window = fixture.makeWindow()
    defer { fixture.close(window) }
    let content = try #require(window.contentView)

    // Act
    content.layoutSubtreeIfNeeded()

    // Assert
    #expect(abs(window.contentLayoutRect.height - content.fittingSize.height) < 1)
    #expect(window.contentLayoutRect.width == 480)
    #expect(window.contentLayoutRect.height < 700, "Subscription content exceeds a compact desktop's height in \(language)")
}
