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
    let fixture = SubscriptionLayoutFixture(language: language, subscribed: subscribed)
    await fixture.access.refresh()
    let window = fixture.makeWindow()
    defer {
        window.close()
        UserDefaults.standard.removePersistentDomain(forName: fixture.defaultsSuiteName)
    }
    let content = try #require(window.contentView)

    // Act
    content.layoutSubtreeIfNeeded()

    // Assert
    #expect(abs(window.contentLayoutRect.height - content.fittingSize.height) < 1)
    #expect(window.contentLayoutRect.width == 480)
    #expect(window.contentLayoutRect.height < 700, "Subscription content exceeds a compact desktop's height in \(language)")
}

@MainActor
private struct SubscriptionLayoutFixture {
    let access: SubscriptionAccessController
    let store: SubscriptionStoreController
    let settings: InterfaceLanguageSettings
    let defaultsSuiteName = "SubscriptionLayout.\(UUID().uuidString)"

    init(language: String, subscribed: Bool) {
        let provider = LayoutEntitlementsStub()
        if subscribed {
            provider.entitlements = [.init(productID: "annual", expiresAt: Date(timeIntervalSince1970: 1893456000), renewsAutomatically: true, renewalPrice: Decimal(199), currencyCode: "TWD")]
        }
        access = SubscriptionAccessController(productID: "annual", provider: provider)
        store = SubscriptionStoreController(access: access, storeProvider: LayoutStoreProviderStub())
        let defaults = UserDefaults(suiteName: defaultsSuiteName)!
        settings = InterfaceLanguageSettings(defaults: defaults, preferredLanguageIdentifiers: { [language] })
    }

    func makeWindow() -> NSWindow {
        let window = NSWindow(contentRect: CGRect(x: 100, y: 100, width: 480, height: 500), styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        let localization = AppLocalization(languageIdentifier: settings.resolvedLanguageIdentifier)
        let content: AnyView
        if let entitlement = access.activeEntitlement {
            content = AnyView(SubscribedView(
                entitlement: entitlement,
                localization: localization,
                locale: settings.locale
            ))
        } else {
            var offer = SubscriptionOffer(displayPrice: "NT$199", activeOffer: nil)
            offer.freeTrialPeriod = DateComponents(month: 1)
            content = AnyView(VStack(spacing: 20) {
                SubscriptionIntroductionView(localization: localization)
                    .padding(.horizontal, 30)
                    .padding(.top, 30)
                UnsubscribedView(
                    offer: offer,
                    store: store,
                    localization: localization,
                    locale: settings.locale,
                    subscribe: {}
                )
                .padding(.horizontal, 30)
            })
        }
        window.contentView = NSHostingView(rootView:
            VStack(spacing: 20) {
                content
                SubscriptionFooter(
                    store: store,
                    localization: localization,
                    configuration: SubscriptionConfiguration(
                        productID: "annual", privacyPolicyURL: "https://example.com/privacy"
                    )
                )
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
            .frame(width: 480)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGSize.self) { $0.size } action: { [weak window] in
                window?.setContentSize($0)
            }
            .interfaceLanguage(settings)
            .environment(\.controlActiveState, .active)
        )
        return window
    }
}

@MainActor
private struct LayoutStoreProviderStub: SubscriptionStoreProviding {
    func restorePurchases() async throws {}
    func finish(_ transaction: StoreKit.Transaction) async {}
}
