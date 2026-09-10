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

        try await Self.purchaseAndAwaitAccess(controller)

        XCTAssertTrue(controller.hasAccess)
        XCTAssertEqual(controller.entitlements.map(\.productID), [Self.productID])
    }

    @MainActor
    @available(macOS 15.2, *)
    func test_storeKitExpiration_whenSubscriptionExpires_thenRemovesAccess() async throws {
        let controller = await Self.makeController()
        try await Self.purchaseAndAwaitAccess(controller)

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
        try await Self.purchaseAndAwaitAccess(controller)

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
    @available(macOS 15.2, *)
    private static func purchaseAndAwaitAccess(_ controller: SubscriptionAccessController) async throws {
        try await purchaseProduct()
        try await assertEventually("purchase becomes active") {
            await controller.refresh()
            return controller.hasAccess
        }
    }

    @MainActor
    @available(macOS 15.2, *)
    private static func purchaseProduct() async throws {
        let products = try await Product.products(for: [productID])
        let product = try XCTUnwrap(products.first { $0.id == productID })
        let window = NSWindow()
        let result = try await product.purchase(confirmIn: window)
        guard case .success(.verified(let transaction)) = result else {
            XCTFail("Local StoreKit purchase did not return a verified transaction")
            return
        }
        XCTAssertEqual(transaction.productID, productID)
        XCTAssertEqual(transaction.productType, .autoRenewable)
        XCTAssertNotNil(transaction.expirationDate)
        await transaction.finish()
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
