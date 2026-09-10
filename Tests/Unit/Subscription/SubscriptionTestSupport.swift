import Foundation
@testable import BoundlessTranslator

@MainActor
func makeUnrestrictedTestAccess() -> SubscriptionAccessController {
    SubscriptionAccessController(
        productID: "",
        provider: UnusedSubscriptionProvider(),
        requiresSubscription: false
    )
}

@MainActor
private struct UnusedSubscriptionProvider: SubscriptionProviding {
    func loadEntitlements() async throws -> [SubscriptionEntitlement] { [] }
    func observeChanges(_ onChange: @escaping @MainActor @Sendable () async -> Void) async {}
}
