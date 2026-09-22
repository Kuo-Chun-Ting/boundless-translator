import Combine
import Foundation

struct SubscriptionEntitlement: Equatable, Sendable {
    let productID: String
    let expiresAt: Date
    var isRevoked = false
    var isUpgraded = false
    var renewsAutomatically: Bool? = nil
    var renewalPrice: Decimal? = nil
    var currencyCode: String? = nil
}

@MainActor
protocol SubscriptionProviding {
    func loadEntitlements() async throws -> [SubscriptionEntitlement]
    func observeChanges(_ onChange: @escaping @MainActor @Sendable () async -> Void) async
}

@MainActor
final class SubscriptionAccessController: ObservableObject {
    let requiresSubscription: Bool
    @Published private(set) var entitlements: [SubscriptionEntitlement] = []
    @Published private(set) var isRefreshing = false
    @Published private(set) var refreshFailed = false
    private(set) var hasLoaded = false

    private let productID: String
    private let provider: any SubscriptionProviding
    private let now: () -> Date
    private var revision = 0
    private var updatesTask: Task<Void, Never>?
    private var initialLoadTask: Task<Void, Never>?
    private var loadingWaiters: [CheckedContinuation<Void, Never>] = []

    var hasAccess: Bool {
        !requiresSubscription || activeEntitlement != nil
    }

    var activeEntitlement: SubscriptionEntitlement? {
        entitlements.filter {
            $0.productID == productID && !$0.isRevoked && !$0.isUpgraded && $0.expiresAt > now()
        }.max { $0.expiresAt < $1.expiresAt }
    }

    init(
        productID: String,
        provider: any SubscriptionProviding,
        requiresSubscription: Bool = true,
        now: @escaping () -> Date = Date.init
    ) {
        self.productID = productID
        self.provider = provider
        self.requiresSubscription = requiresSubscription
        self.now = now
    }

    deinit {
        updatesTask?.cancel()
        initialLoadTask?.cancel()
    }

    func start() {
        guard requiresSubscription, updatesTask == nil else { return }
        let provider = provider
        updatesTask = Task { [weak self] in
            await provider.observeChanges { [weak self] in
                await self?.refresh()
            }
        }
        Task { [weak self] in await self?.loadIfNeeded() }
    }

    func loadIfNeeded() async {
        guard requiresSubscription, !hasLoaded else { return }
        await withCheckedContinuation { waiter in
            loadingWaiters.append(waiter)
            if !isRefreshing && initialLoadTask == nil {
                initialLoadTask = Task { [weak self] in
                    guard let self else { return }
                    // Another caller may already have started the first refresh.
                    guard !hasLoaded, !isRefreshing else { return }
                    await refresh()
                }
            }
        }
    }

    func refreshAndWait() async {
        await refresh()
        guard isRefreshing else { return }
        await withCheckedContinuation { loadingWaiters.append($0) }
    }

    func refresh() async {
        guard requiresSubscription else { return }
        revision += 1
        let requestRevision = revision
        isRefreshing = true
        defer {
            if requestRevision == revision {
                isRefreshing = false
                hasLoaded = true
                let waiters = loadingWaiters
                loadingWaiters.removeAll()
                for waiter in waiters { waiter.resume() }
            }
        }

        do {
            let snapshot = try await provider.loadEntitlements()
            guard requestRevision == revision else { return }
            entitlements = snapshot
            refreshFailed = false
        } catch {
            guard requestRevision == revision else { return }
            refreshFailed = true
        }
    }
}
