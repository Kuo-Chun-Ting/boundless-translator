import AppKit
import StoreKit
import SwiftUI
@testable import BoundlessTranslator

@MainActor
struct SubscriptionViewFixture {
    let provider = SubscriptionViewEntitlementsStub()
    let actions = SubscriptionViewActionsMock()
    let access: SubscriptionAccessController
    let store: SubscriptionStoreController
    let settings: InterfaceLanguageSettings
    let defaultsSuiteName = "SubscriptionView.\(UUID().uuidString)"
    var offer = SubscriptionOffer(displayPrice: "NT$199", activeOffer: nil)

    init(language: String = "en", subscribed: Bool = false) {
        if subscribed { provider.entitlements = [Self.entitlement] }
        access = SubscriptionAccessController(productID: "annual", provider: provider)
        store = SubscriptionStoreController(access: access, storeProvider: actions)
        settings = InterfaceLanguageSettings(
            defaults: UserDefaults(suiteName: defaultsSuiteName)!, preferredLanguageIdentifiers: { [language] }
        )
    }

    static var entitlement: SubscriptionEntitlement {
        .init(productID: "annual", expiresAt: Date(timeIntervalSince1970: 1893456000),
              renewsAutomatically: true, renewalPrice: Decimal(199), currencyCode: "TWD")
    }

    func makeWindow() -> NSWindow {
        let window = NSWindow(contentRect: CGRect(x: 100, y: 100, width: 480, height: 500),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        let localization = AppLocalization(languageIdentifier: settings.resolvedLanguageIdentifier)
        let view = SubscriptionView(
            access: access, store: store, interfaceLanguageSettings: settings,
            configuration: SubscriptionConfiguration(productID: "annual", privacyPolicyURL: "https://example.com/privacy"),
            onContentSizeChange: { [weak window] in window?.setContentSize($0) }
        ) { _ in
            VStack(spacing: 20) {
                SubscriptionIntroductionView(localization: localization)
                    .padding(.horizontal, 30).padding(.top, 30)
                UnsubscribedView(
                    offer: offer,
                    store: store, localization: localization, locale: settings.locale,
                    subscribe: { actions.purchaseCount += 1 }
                )
                .padding(.horizontal, 30)
            }
        }
        window.contentView = NSHostingView(rootView: view
            .environment(\.controlActiveState, .active)
            .environment(\.openURL, OpenURLAction { url in
                actions.openedURLs.append(url)
                return .handled
            }))
        return window
    }

    func close(_ window: NSWindow) {
        window.close()
        UserDefaults.standard.removePersistentDomain(forName: defaultsSuiteName)
    }
}

@MainActor
final class SubscriptionViewEntitlementsStub: SubscriptionProviding {
    var entitlements: [SubscriptionEntitlement] = []
    func loadEntitlements() async throws -> [SubscriptionEntitlement] { entitlements }
    func observeChanges(_ onChange: @escaping @MainActor @Sendable () async -> Void) async {}
}

@MainActor
final class SubscriptionViewActionsMock: SubscriptionStoreProviding {
    var purchaseCount = 0
    var restoreCount = 0
    var openedURLs: [URL] = []
    func restorePurchases() async throws { restoreCount += 1 }
    func finish(_ transaction: StoreKit.Transaction) async {}
}
