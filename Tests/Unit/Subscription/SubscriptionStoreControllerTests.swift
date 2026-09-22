import Foundation
import StoreKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_purchaseCompleted_when_userCancels_thenRemainsUnsubscribedWithoutError() async {
    // Arrange
    let fixture = SubscriptionStoreFixture()
    fixture.controller.purchaseStarted()

    // Act
    await fixture.controller.purchaseCompleted(.success(.userCancelled))

    // Assert
    #expect(!fixture.access.hasAccess)
    #expect(fixture.controller.messageKey == nil)
    #expect(!fixture.controller.isBusy)
}

@Test @MainActor
func test_purchaseCompleted_when_approvalIsPending_thenExplainsPendingWithoutGrantingAccess() async {
    // Arrange
    let fixture = SubscriptionStoreFixture()
    fixture.controller.purchaseStarted()

    // Act
    await fixture.controller.purchaseCompleted(.success(.pending))

    // Assert
    #expect(!fixture.access.hasAccess)
    #expect(fixture.controller.messageKey == "subscription.pending")
    #expect(!fixture.controller.isBusy)
}

@Test @MainActor
func test_purchaseCompleted_when_storeFails_thenReportsFailureAndAllowsRetry() async {
    // Arrange
    let fixture = SubscriptionStoreFixture()
    fixture.controller.purchaseStarted()

    // Act
    await fixture.controller.purchaseCompleted(.failure(SubscriptionStoreTestError.failed))

    // Assert
    #expect(fixture.controller.messageKey == "subscription.purchaseFailed")
    #expect(!fixture.controller.isBusy)
}

@Test @MainActor
func test_purchaseCompleted_when_pendingPurchaseIsApproved_thenClearsPendingMessage() async {
    // Arrange
    let fixture = SubscriptionStoreFixture()
    await fixture.controller.purchaseCompleted(.success(.pending))
    fixture.stub_entitlements.values = [.init(productID: "annual", expiresAt: .distantFuture)]

    // Act
    await fixture.access.refresh()

    // Assert
    #expect(fixture.access.hasAccess)
    #expect(fixture.controller.messageKey == nil)
}

@Test @MainActor
func test_restore_when_existingPurchaseIsFound_thenRefreshesAccess() async {
    // Arrange
    let fixture = SubscriptionStoreFixture()
    fixture.mock_store.restoreAction = {
        fixture.stub_entitlements.values = [.init(productID: "annual", expiresAt: .distantFuture)]
    }

    // Act
    await fixture.controller.restore()

    // Assert
    #expect(fixture.mock_store.restoreCount == 1)
    #expect(fixture.access.hasAccess)
    #expect(fixture.controller.messageKey == nil)
}

@Test @MainActor
func test_restore_when_noActivePurchaseExists_thenExplainsResult() async {
    // Arrange
    let fixture = SubscriptionStoreFixture()

    // Act
    await fixture.controller.restore()

    // Assert
    #expect(!fixture.access.hasAccess)
    #expect(fixture.controller.messageKey == "subscription.restoreNone")
}

@Test @MainActor
func test_restore_when_syncFails_thenPreservesAccessAndReportsFailure() async {
    // Arrange
    let fixture = SubscriptionStoreFixture()
    fixture.stub_entitlements.values = [.init(productID: "annual", expiresAt: .distantFuture)]
    await fixture.access.refresh()
    fixture.mock_store.restoreAction = { throw SubscriptionStoreTestError.failed }

    // Act
    await fixture.controller.restore()

    // Assert
    #expect(fixture.access.hasAccess)
    #expect(fixture.controller.messageKey == "subscription.restoreFailed")
    #expect(!fixture.controller.isBusy)
}

@Test @MainActor
func test_restore_when_purchaseOrRestoreIsRunning_thenDoesNotSendDuplicateRequests() async {
    // Arrange
    let fixture = SubscriptionStoreFixture()
    fixture.controller.purchaseStarted()

    // Act
    await fixture.controller.restore()
    await fixture.controller.purchaseCompleted(.success(.userCancelled))
    fixture.mock_store.restoreAction = { await fixture.controller.restore() }
    await fixture.controller.restore()

    // Assert
    #expect(fixture.mock_store.restoreCount == 1)
    #expect(!fixture.controller.isBusy)
}

@Test @MainActor
func test_restore_when_entitlementRefreshFails_thenReportsFailureInsteadOfNoPurchases() async {
    // Arrange
    let fixture = SubscriptionStoreFixture()
    fixture.stub_entitlements.error = SubscriptionStoreTestError.failed

    // Act
    await fixture.controller.restore()

    // Assert
    #expect(fixture.controller.messageKey == "subscription.restoreFailed")
    #expect(!fixture.controller.isBusy)
}

@Test @MainActor
func test_restore_when_observerSupersedesRefresh_thenWaitsForLatestAccessDecision() async {
    // Arrange
    let fixture = SubscriptionStoreFixture()
    let (requests, continuation) = AsyncStream<CheckedContinuation<[SubscriptionEntitlement], Error>>.makeStream()
    fixture.stub_entitlements.loadAction = {
        try await withCheckedThrowingContinuation { continuation.yield($0) }
    }
    var iterator = requests.makeAsyncIterator()
    let restore = Task { await fixture.controller.restore() }
    let firstReply = await iterator.next()!
    let observer = Task { await fixture.access.refresh() }
    let latestReply = await iterator.next()!

    // Act
    firstReply.resume(returning: [])
    latestReply.resume(returning: [.init(productID: "annual", expiresAt: .distantFuture)])
    await observer.value
    await restore.value

    // Assert
    #expect(fixture.access.hasAccess)
    #expect(fixture.controller.messageKey == nil)
}

@MainActor
private struct SubscriptionStoreFixture {
    let stub_entitlements = SubscriptionEntitlementsStub()
    let mock_store = SubscriptionStoreProviderMock()
    let access: SubscriptionAccessController
    let controller: SubscriptionStoreController

    init() {
        access = SubscriptionAccessController(productID: "annual", provider: stub_entitlements)
        controller = SubscriptionStoreController(access: access, storeProvider: mock_store)
    }
}

private enum SubscriptionStoreTestError: Error { case failed }

@MainActor
private final class SubscriptionEntitlementsStub: SubscriptionProviding {
    var values: [SubscriptionEntitlement] = []
    var error: Error?
    var loadAction: (() async throws -> [SubscriptionEntitlement])?
    func loadEntitlements() async throws -> [SubscriptionEntitlement] {
        if let loadAction { return try await loadAction() }
        if let error { throw error }
        return values
    }
    func observeChanges(_ onChange: @escaping @MainActor @Sendable () async -> Void) async {}
}

@MainActor
private final class SubscriptionStoreProviderMock: SubscriptionStoreProviding {
    var restoreAction: () async throws -> Void = {}
    var restoreCount = 0

    func restorePurchases() async throws {
        restoreCount += 1
        try await restoreAction()
    }

    func finish(_ transaction: Transaction) async {}
}
