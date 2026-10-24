import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_subscriptionView_when_unsubscribed_thenShowsOfferAndRoutesPurchaseAndRestore() async throws {
    // Arrange
    let fixture = SubscriptionViewFixture()
    await fixture.access.refresh()
    let window = fixture.makeWindow()
    defer { fixture.close(window) }
    let content = try #require(window.contentView)
    _ = try await findAccessibilityMenus(in: content)

    // Act & Assert
    try await waitForSubscriptionView { subscriptionTexts(content).contains("Subscribe") }
    #expect(subscriptionTexts(content).contains("Annual plan"))
    #expect(subscriptionTexts(content).contains { $0.contains("NT$199") })
    #expect(!subscriptionTexts(content).contains("Active"))
    #expect(!subscriptionTexts(content).contains("Manage Subscription"))
    try pressSubscriptionControl("Subscribe", in: content)
    try pressSubscriptionControl("Restore purchases", in: content)
    try await waitForSubscriptionView { fixture.actions.restoreCount == 1 }
    #expect(fixture.actions.purchaseCount == 1)
    #expect(fixture.actions.restoreCount == 1)
    #expect(!fixture.access.hasAccess)
}

@Test @MainActor
func test_subscriptionView_when_subscribed_thenShowsDetailsAndRoutesManagement() async throws {
    // Arrange
    let fixture = SubscriptionViewFixture(subscribed: true)
    await fixture.access.refresh()
    let window = fixture.makeWindow()
    defer { fixture.close(window) }
    let content = try #require(window.contentView)
    _ = try await findAccessibilityMenus(in: content)

    // Act & Assert
    try await waitForSubscriptionView { subscriptionTexts(content).contains("Active") }
    #expect(subscriptionTexts(content).contains("Annual plan"))
    let price = Decimal(199).formatted(.currency(code: "TWD").locale(fixture.settings.locale))
    #expect(subscriptionTexts(content).contains { $0.contains(price) })
    #expect(subscriptionTexts(content).contains("Next renewal"))
    let expiry = SubscriptionViewFixture.entitlement.expiresAt.formatted(.dateTime.year().month().day().locale(fixture.settings.locale))
    #expect(subscriptionTexts(content).contains(expiry))
    #expect(!subscriptionTexts(content).contains("Subscribe"))
    try pressSubscriptionControl("Manage Subscription", in: content)
    try await waitForSubscriptionView { !fixture.actions.openedURLs.isEmpty }
    #expect(fixture.actions.openedURLs.map(\.absoluteString) == ["https://apps.apple.com/account/subscriptions"])
    #expect(fixture.actions.purchaseCount == 0)
}

@Test @MainActor
func test_subscriptionView_when_entitlementChanges_thenSwitchesContentInSameWindow() async throws {
    // Arrange
    let fixture = SubscriptionViewFixture()
    await fixture.access.refresh()
    let window = fixture.makeWindow()
    defer { fixture.close(window) }
    let content = try #require(window.contentView)
    _ = try await findAccessibilityMenus(in: content)
    try await waitForSubscriptionView { subscriptionTexts(content).contains("Subscribe") }

    // Act & Assert
    fixture.provider.entitlements = [SubscriptionViewFixture.entitlement]
    await fixture.access.refresh()
    try await waitForSubscriptionView {
        subscriptionTexts(content).contains("Active") && !subscriptionTexts(content).contains("Subscribe")
    }
    fixture.provider.entitlements = []
    await fixture.access.refresh()
    try await waitForSubscriptionView {
        subscriptionTexts(content).contains("Subscribe") && !subscriptionTexts(content).contains("Active")
    }
    #expect(window.contentView === content)
}

@MainActor
private func subscriptionElements(_ element: AnyObject) -> [AnyObject] {
    [element] + (element.accessibilityChildren?() ?? []).flatMap { subscriptionElements($0 as AnyObject) }
}

@MainActor
private func subscriptionTexts(_ view: NSView) -> [String] {
    view.layoutSubtreeIfNeeded()
    return subscriptionElements(view).flatMap { element -> [String] in
        let value: String? = element.accessibilityValue?()
        return [element.accessibilityLabel?(), value].compactMap { $0 }
    }
}

@MainActor
private func pressSubscriptionControl(_ title: String, in view: NSView) throws {
    let control = try #require(subscriptionElements(view).first {
        ($0.accessibilityRole?() == .button || $0.accessibilityRole?() == .link) && $0.accessibilityLabel?() == title
    }, "Missing subscription control: \(title)")
    #expect(control.accessibilityPerformPress?() == true)
}

@MainActor
private func waitForSubscriptionView(_ condition: () -> Bool) async throws {
    let deadline = ContinuousClock.now.advanced(by: .seconds(2))
    while !condition() && ContinuousClock.now < deadline {
        try await Task.sleep(for: .milliseconds(10))
    }
    try #require(condition(), "Subscription view did not reach the expected state")
}
