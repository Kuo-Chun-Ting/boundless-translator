import Foundation
import StoreKit

enum SubscriptionStoreError: Error {
    case verificationFailed
}

@MainActor
struct StoreKitSubscriptionProvider: SubscriptionProviding {
    let productID: String

    func loadEntitlements() async throws -> [SubscriptionEntitlement] {
        var entitlements: [SubscriptionEntitlement] = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                throw SubscriptionStoreError.verificationFailed
            }
            guard transaction.productID == productID,
                  transaction.productType == .autoRenewable,
                  let expiration = transaction.expirationDate else { continue }
            let effectiveExpiration = try await expirationIncludingGracePeriod(transaction, expiration: expiration)
            entitlements.append(SubscriptionEntitlement(
                productID: transaction.productID,
                expiresAt: effectiveExpiration,
                isRevoked: transaction.revocationDate != nil,
                isUpgraded: transaction.isUpgraded
            ))
        }
        return entitlements
    }

    func observeChanges(_ onChange: @escaping @MainActor @Sendable () async -> Void) async {
        let productID = productID
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                for await result in Transaction.updates {
                    guard !Task.isCancelled else { return }
                    await onChange()
                    if case .verified(let transaction) = result, transaction.productID == productID {
                        await transaction.finish()
                    }
                }
            }
            group.addTask {
                for await _ in Product.SubscriptionInfo.Status.updates {
                    guard !Task.isCancelled else { return }
                    await onChange()
                }
            }
        }
    }

    private func expirationIncludingGracePeriod(_ transaction: Transaction, expiration: Date) async throws -> Date {
        guard expiration <= Date(), let groupID = transaction.subscriptionGroupID,
              transaction.revocationDate == nil, !transaction.isUpgraded else { return expiration }
        let statuses = try await Product.SubscriptionInfo.status(for: groupID)
        for status in statuses where status.state == .inGracePeriod {
            guard case .verified(let current) = status.transaction,
                  case .verified(let renewal) = status.renewalInfo else {
                throw SubscriptionStoreError.verificationFailed
            }
            if current.id == transaction.id, current.revocationDate == nil,
               let graceExpiration = renewal.gracePeriodExpirationDate {
                return max(expiration, graceExpiration)
            }
        }
        return expiration
    }
}
