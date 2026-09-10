import Foundation

struct SubscriptionConfiguration {
    let productID: String
    let privacyPolicyURL: URL

    init?(productID: String?, privacyPolicyURL: String?) {
        guard let productID, !productID.isEmpty,
              productID.rangeOfCharacter(from: .whitespacesAndNewlines) == nil,
              let privacyPolicyURL, let url = URL(string: privacyPolicyURL),
              url.scheme == "https", let host = url.host, !host.isEmpty,
              url.user == nil, url.password == nil else { return nil }
        self.productID = productID
        self.privacyPolicyURL = url
    }

    static var current: Self? {
        Self(
            productID: Bundle.main.object(forInfoDictionaryKey: "BoundlessSubscriptionProductID") as? String,
            privacyPolicyURL: Bundle.main.object(forInfoDictionaryKey: "BoundlessPrivacyPolicyURL") as? String
        )
    }

    @MainActor
    static func makeAccessController() -> SubscriptionAccessController {
        let productID = current?.productID ?? ""
#if SUBSCRIPTION_REQUIRED
        let requiresSubscription = true
#else
        let requiresSubscription = false
#endif
        return SubscriptionAccessController(
            productID: productID,
            provider: StoreKitSubscriptionProvider(productID: productID),
            requiresSubscription: requiresSubscription
        )
    }
}
