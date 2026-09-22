import Combine
import StoreKit

@MainActor
final class SubscriptionStoreController: ObservableObject {
    @Published private(set) var isPurchasing = false
    @Published private(set) var isRestoring = false
    @Published private(set) var messageKey: String?

    private let access: SubscriptionAccessController
    private let storeProvider: any SubscriptionStoreProviding
    private var accessObservation: AnyCancellable?

    var isBusy: Bool { isPurchasing || isRestoring }

    init(
        access: SubscriptionAccessController,
        storeProvider: any SubscriptionStoreProviding
    ) {
        self.access = access
        self.storeProvider = storeProvider
        accessObservation = access.$isRefreshing.dropFirst().filter { !$0 }.sink { [weak self] _ in
            guard let self, access.hasAccess, messageKey == "subscription.pending" else { return }
            messageKey = nil
        }
    }

    func purchaseStarted() {
        isPurchasing = true
        messageKey = nil
    }

    func purchaseCompleted(_ result: Result<Product.PurchaseResult, Error>) async {
        defer { isPurchasing = false }
        switch result {
        case .success(.success(.verified(let transaction))):
            await access.refreshAndWait()
            if access.hasAccess { await storeProvider.finish(transaction) }
        case .success(.pending):
            if !access.hasAccess { messageKey = "subscription.pending" }
        case .success(.userCancelled): break
        default:
            messageKey = "subscription.purchaseFailed"
        }
    }

    func restore() async {
        guard !isBusy else { return }
        isRestoring = true
        messageKey = nil
        defer { isRestoring = false }
        do {
            try await storeProvider.restorePurchases()
            await access.refreshAndWait()
            if access.refreshFailed {
                messageKey = "subscription.restoreFailed"
            } else if !access.hasAccess {
                messageKey = "subscription.restoreNone"
            }
        } catch {
            messageKey = "subscription.restoreFailed"
        }
    }
}
