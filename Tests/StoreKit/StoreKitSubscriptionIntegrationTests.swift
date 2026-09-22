import AppKit
import StoreKit
import StoreKitTest
import XCTest

final class StoreKitSubscriptionIntegrationTests: XCTestCase {
    private static let productID = "com.boundless-translator.test.annual"
    private var session: SKTestSession!

    override func setUpWithError() throws {
        continueAfterFailure = false
        session = try SKTestSession(configurationFileNamed: "BoundlessTranslator")
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
    }

    override func tearDownWithError() throws {
        session.clearTransactions()
        session.resetToDefaultState()
        session = nil
    }

    @MainActor
    @available(macOS 15.2, *)
    func test_storeKitPurchase_whenVerified_thenGrantsAccess() async throws {
        let controller = await Self.makeController()

        try await purchaseAndAwaitAccess(controller)

        XCTAssertTrue(controller.hasAccess)
        XCTAssertEqual(controller.entitlements.map(\.productID), [Self.productID])
        XCTAssertEqual(controller.activeEntitlement?.renewsAutomatically, true)
        XCTAssertEqual(controller.activeEntitlement?.renewalPrice, Decimal(199))
        XCTAssertEqual(controller.activeEntitlement?.currencyCode, "TWD")
    }

    @MainActor
    func test_purchaseCompleted_when_verifiedNativeResultArrives_thenGrantsAccessAndFinishesTransaction() async throws {
        // Arrange
        _ = try await session.buyProduct(identifier: Self.productID)
        let latest = await Transaction.latest(for: Self.productID)
        let verification = try XCTUnwrap(latest)
        let provider = StoreKitSubscriptionProvider(productID: Self.productID)
        let access = SubscriptionAccessController(productID: Self.productID, provider: provider)
        let store = SubscriptionStoreController(access: access, storeProvider: provider)
        store.purchaseStarted()

        // Act
        await store.purchaseCompleted(.success(.success(verification)))

        // Assert
        XCTAssertTrue(access.hasAccess)
        XCTAssertFalse(store.isBusy)
        XCTAssertNil(store.messageKey)
        for await unfinished in Transaction.unfinished {
            if case .verified(let transaction) = unfinished {
                XCTAssertNotEqual(transaction.productID, Self.productID)
            }
        }
    }

    @MainActor
    @available(macOS 15.2, *)
    func test_storeKitRestore_whenRenewalIsCancelled_thenRestoresAccessUntilExpiration() async throws {
        let controller = await Self.makeController()
        try await purchaseAndAwaitAccess(controller)
        let transaction = try XCTUnwrap(session.allTransactions().last)
        try session.disableAutoRenewForTransaction(identifier: transaction.identifier)
        let provider = StoreKitSubscriptionProvider(productID: Self.productID)
        let restored = SubscriptionAccessController(productID: Self.productID, provider: provider)
        let store = SubscriptionStoreController(access: restored, storeProvider: provider)

        await store.restore()

        XCTAssertTrue(restored.hasAccess)
        XCTAssertNil(store.messageKey)
        try await Self.assertEventually("cancelled renewal retains access until expiration") {
            await restored.refresh()
            return restored.activeEntitlement?.renewsAutomatically == false
        }
    }

    @MainActor
    @available(macOS 15.2, *)
    func test_storeKitExpiration_whenSubscriptionExpires_thenRemovesAccess() async throws {
        let controller = await Self.makeController()
        try await purchaseAndAwaitAccess(controller)

        try session.expireSubscription(productIdentifier: Self.productID)
        try await Self.assertEventually("expiration removes access") {
            await controller.refresh()
            return !controller.hasAccess
        }

        XCTAssertFalse(controller.hasAccess)
    }

    @MainActor
    @available(macOS 15.2, *)
    func test_storeKitRefund_whenTransactionRefunded_thenRemovesAccess() async throws {
        let controller = await Self.makeController()
        try await purchaseAndAwaitAccess(controller)

        let testTransaction = try XCTUnwrap(session.allTransactions().last)
        try session.refundTransaction(identifier: testTransaction.identifier)
        try await Self.assertEventually("refund removes access") {
            await controller.refresh()
            return !controller.hasAccess
        }
        XCTAssertFalse(controller.hasAccess)
    }

    @MainActor
    private static func makeController() async -> SubscriptionAccessController {
        let provider = StoreKitSubscriptionProvider(productID: productID)
        let controller = SubscriptionAccessController(productID: productID, provider: provider)
        controller.start()
        await controller.loadIfNeeded()
        XCTAssertFalse(controller.hasAccess)
        return controller
    }

    @MainActor
    private func purchaseAndAwaitAccess(_ controller: SubscriptionAccessController) async throws {
        _ = try await session.buyProduct(identifier: Self.productID)
        try await Self.assertEventually("transaction update grants access") { controller.hasAccess }
    }

    @MainActor
    private static func assertEventually(
        _ state: String,
        timeout: TimeInterval = 5,
        condition: @escaping @MainActor () async throws -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if try await condition() { return }
            try await Task.sleep(for: .milliseconds(50))
        }
        XCTFail("StoreKit state did not converge: \(state)")
    }

}
