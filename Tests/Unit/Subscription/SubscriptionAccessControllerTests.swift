import Foundation
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_refresh_when_verified_subscription_is_active_then_allows_access_until_expiry() async {
    // Arrange
    var now = Date(timeIntervalSince1970: 100)
    let stub_store = SubscriptionProviderStub()
    stub_store.result = .success([.init(productID: "annual", expiresAt: Date(timeIntervalSince1970: 200))])
    let controller = SubscriptionAccessController(productID: "annual", provider: stub_store, now: { now })
    #expect(!controller.hasAccess)

    // Act
    await controller.refresh()

    // Assert
    #expect(controller.hasAccess)
    now = Date(timeIntervalSince1970: 200)
    #expect(!controller.hasAccess)
}

@Test @MainActor
func test_refresh_when_subscription_is_wrong_expired_revoked_or_upgraded_then_denies_access() async {
    // Arrange
    let stub_store = SubscriptionProviderStub()
    stub_store.result = .success([
        .init(productID: "other", expiresAt: .distantFuture),
        .init(productID: "annual", expiresAt: .distantPast),
        .init(productID: "annual", expiresAt: .distantFuture, isRevoked: true),
        .init(productID: "annual", expiresAt: .distantFuture, isUpgraded: true)
    ])
    let controller = SubscriptionAccessController(productID: "annual", provider: stub_store)

    // Act
    await controller.refresh()

    // Assert
    #expect(!controller.hasAccess)
}

@Test @MainActor
func test_refresh_when_store_temporarily_fails_then_preserves_verified_unexpired_access() async {
    // Arrange
    let stub_store = SubscriptionProviderStub()
    stub_store.result = .success([.init(productID: "annual", expiresAt: .distantFuture)])
    let controller = SubscriptionAccessController(productID: "annual", provider: stub_store)
    await controller.refresh()
    stub_store.result = .failure(SubscriptionStoreError.verificationFailed)

    // Act
    await controller.refresh()

    // Assert
    #expect(controller.hasAccess)
    #expect(controller.refreshFailed)
}

@Test @MainActor
func test_refresh_when_entitlement_disappears_then_removes_previous_access() async {
    // Arrange
    let stub_store = SubscriptionProviderStub()
    stub_store.result = .success([.init(productID: "annual", expiresAt: .distantFuture)])
    let controller = SubscriptionAccessController(productID: "annual", provider: stub_store)
    await controller.refresh()
    stub_store.result = .success([])

    // Act
    await controller.refresh()

    // Assert
    #expect(!controller.hasAccess)
    #expect(!controller.refreshFailed)
}

@Test @MainActor
func test_refresh_when_verification_fails_without_previous_access_then_remains_locked() async {
    // Arrange
    let stub_store = SubscriptionProviderStub()
    stub_store.result = .failure(SubscriptionStoreError.verificationFailed)
    let controller = SubscriptionAccessController(productID: "annual", provider: stub_store)

    // Act
    await controller.refresh()

    // Assert
    #expect(!controller.hasAccess)
    #expect(controller.refreshFailed)
}

@Test @MainActor
func test_refresh_when_direct_distribution_then_never_contacts_store_or_locks_features() async {
    // Arrange
    let mock_store = SubscriptionProviderStub()
    let controller = SubscriptionAccessController(productID: "", provider: mock_store, requiresSubscription: false)

    // Act
    await controller.refresh()

    // Assert
    #expect(controller.hasAccess)
    #expect(mock_store.loadCount == 0)
}

@MainActor
private final class SubscriptionProviderStub: SubscriptionProviding {
    var result: Result<[SubscriptionEntitlement], Error> = .success([])
    var loadCount = 0

    func loadEntitlements() async throws -> [SubscriptionEntitlement] {
        loadCount += 1
        return try result.get()
    }

    func observeChanges(_ onChange: @escaping @MainActor () async -> Void) async {}
}

@Test @MainActor
func test_refresh_when_old_request_finishes_after_revocation_refresh_then_does_not_restore_old_access() async {
    // Arrange
    let stub_store = SuspendedSubscriptionProvider()
    let controller = SubscriptionAccessController(productID: "annual", provider: stub_store)
    let oldRefresh = Task { await controller.refresh() }
    await stub_store.waitUntilFirstLoad()

    // Act
    await controller.refresh()
    stub_store.finishFirstLoad([.init(productID: "annual", expiresAt: .distantFuture)])
    await oldRefresh.value

    // Assert
    #expect(!controller.hasAccess)
    #expect(!controller.isRefreshing)
}

@MainActor
private final class SuspendedSubscriptionProvider: SubscriptionProviding {
    private var continuation: CheckedContinuation<[SubscriptionEntitlement], Never>?
    private var started: CheckedContinuation<Void, Never>?
    private var loadCount = 0

    func loadEntitlements() async throws -> [SubscriptionEntitlement] {
        loadCount += 1
        guard loadCount == 1 else { return [] }
        return await withCheckedContinuation {
            continuation = $0
            started?.resume()
            started = nil
        }
    }

    func waitUntilFirstLoad() async {
        if continuation != nil { return }
        await withCheckedContinuation { started = $0 }
    }

    func finishFirstLoad(_ entitlements: [SubscriptionEntitlement]) {
        continuation?.resume(returning: entitlements)
        continuation = nil
    }

    func observeChanges(_ onChange: @escaping @MainActor @Sendable () async -> Void) async {}
}

@Test @MainActor
func test_loadIfNeeded_when_a_newer_refresh_is_pending_then_waits_for_its_access_decision() async {
    // Arrange
    let stub_store = ConcurrentSubscriptionProvider()
    let controller = SubscriptionAccessController(productID: "annual", provider: stub_store)
    var events = stub_store.loads.makeAsyncIterator()
    let first = Task {
        await controller.loadIfNeeded()
        return controller.hasAccess
    }
    _ = await events.next()
    let newer = Task { await controller.refresh() }
    _ = await events.next()

    // Act
    stub_store.finish(1, entitlements: [])
    // Give the superseded caller a chance to return before the current load.
    for _ in 0..<10 { await Task.yield() }
    stub_store.finish(2, entitlements: [.init(productID: "annual", expiresAt: .distantFuture)])
    await newer.value

    // Assert
    #expect(await first.value)
}

@MainActor
private final class ConcurrentSubscriptionProvider: SubscriptionProviding {
    let loads: AsyncStream<Int>
    private let loadEvents: AsyncStream<Int>.Continuation
    private var pending: [Int: CheckedContinuation<[SubscriptionEntitlement], Never>] = [:]
    private var count = 0

    init() {
        (loads, loadEvents) = AsyncStream.makeStream()
    }

    func loadEntitlements() async throws -> [SubscriptionEntitlement] {
        count += 1
        let id = count
        return await withCheckedContinuation {
            pending[id] = $0
            loadEvents.yield(id)
        }
    }

    func finish(_ id: Int, entitlements: [SubscriptionEntitlement]) {
        pending.removeValue(forKey: id)?.resume(returning: entitlements)
    }

    func observeChanges(_ onChange: @escaping @MainActor @Sendable () async -> Void) async {}
}

@Test @MainActor
func test_loadIfNeeded_when_newer_refresh_finishes_first_then_releases_action_without_waiting_for_old_load() async {
    // Arrange
    let stub_store = ConcurrentSubscriptionProvider()
    let controller = SubscriptionAccessController(productID: "annual", provider: stub_store)
    var events = stub_store.loads.makeAsyncIterator()
    var actionReleased = false
    let first = Task {
        await controller.loadIfNeeded()
        actionReleased = true
    }
    _ = await events.next()
    let newer = Task { await controller.refresh() }
    _ = await events.next()

    // Act
    stub_store.finish(2, entitlements: [.init(productID: "annual", expiresAt: .distantFuture)])
    await newer.value
    for _ in 0..<10 { await Task.yield() }

    // Assert
    #expect(actionReleased)
    #expect(controller.hasAccess)
    stub_store.finish(1, entitlements: [])
    await first.value
}

@Test @MainActor
func test_start_when_store_reports_revocation_then_removes_access_without_manual_refresh() async {
    // Arrange
    let mock_store = ObservableSubscriptionProvider()
    let controller = SubscriptionAccessController(productID: "annual", provider: mock_store)
    controller.start()
    await mock_store.waitUntilObserving()
    await controller.loadIfNeeded()
    #expect(controller.hasAccess)

    // Act
    mock_store.entitlements = []
    await mock_store.notifyChange()

    // Assert
    #expect(!controller.hasAccess)
    #expect(!controller.refreshFailed)
}

@Test @MainActor
func test_start_when_free_build_then_never_loads_or_observes_store() async {
    // Arrange
    let mock_store = ObservableSubscriptionProvider()
    let controller = SubscriptionAccessController(productID: "annual", provider: mock_store, requiresSubscription: false)

    // Act
    controller.start()
    await controller.loadIfNeeded()
    for _ in 0..<10 { await Task.yield() }

    // Assert
    #expect(controller.hasAccess)
    #expect(mock_store.loadCount == 0)
    #expect(mock_store.observationCount == 0)
}

@MainActor
private final class ObservableSubscriptionProvider: SubscriptionProviding {
    var entitlements: [SubscriptionEntitlement] = [.init(productID: "annual", expiresAt: .distantFuture)]
    private(set) var loadCount = 0
    private(set) var observationCount = 0
    private var onChange: (@MainActor @Sendable () async -> Void)?
    private var started: CheckedContinuation<Void, Never>?

    func loadEntitlements() async throws -> [SubscriptionEntitlement] {
        loadCount += 1
        return entitlements
    }

    func observeChanges(_ onChange: @escaping @MainActor @Sendable () async -> Void) async {
        observationCount += 1
        self.onChange = onChange
        started?.resume()
        started = nil
    }

    func waitUntilObserving() async {
        if onChange != nil { return }
        await withCheckedContinuation { started = $0 }
    }

    func notifyChange() async { await onChange?() }
}
