import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_handleShortcut_when_subscription_missing_then_requests_subscription_without_reading_selection() async {
    // Arrange
    let mock_reader = SubscriptionSelectionReaderMock()
    var presentations = 0
    let controller = AppController(
        selectedTextReader: mock_reader,
        subscriptionAccess: await lockedSubscription(),
        onSubscriptionRequired: { presentations += 1 }
    )

    // Act
    controller.handleShortcut()

    // Assert
    #expect(presentations == 1)
    #expect(mock_reader.readCount == 0)
}

@Test @MainActor
func test_captureScreenshot_when_subscription_missing_then_never_requests_screen_capture() async throws {
    // Arrange
    let mock_capture = SubscriptionScreenshotMock()
    var presentations = 0
    let controller = AppController(
        screenshotCapture: mock_capture,
        subscriptionAccess: await lockedSubscription(),
        onSubscriptionRequired: { presentations += 1 }
    )

    // Act
    try await controller.captureScreenshot()

    // Assert
    #expect(presentations == 1)
    #expect(mock_capture.captureCount == 0)
}

@Test @MainActor
func test_translate_when_subscription_missing_then_requests_subscription_instead_of_translation() async throws {
    // Arrange
    var presentations = 0
    let controller = AppController(
        subscriptionAccess: await lockedSubscription(),
        onSubscriptionRequired: { presentations += 1 }
    )

    // Act
    await controller.translate(try SelectedText("Hello"), sourceLanguageIdentifier: "en")

    // Assert
    #expect(presentations == 1)
}

@MainActor
private func lockedSubscription() async -> SubscriptionAccessController {
    let access = SubscriptionAccessController(productID: "annual", provider: EmptySubscriptionProvider())
    await access.refresh()
    return access
}

@MainActor
private struct EmptySubscriptionProvider: SubscriptionProviding {
    func loadEntitlements() async throws -> [SubscriptionEntitlement] { [] }
    func observeChanges(_ onChange: @escaping @MainActor @Sendable () async -> Void) async {}
}

@MainActor
private final class SubscriptionSelectionReaderMock: SelectedTextReading {
    var readCount = 0
    func readSelectedText() async throws -> SelectedText {
        readCount += 1
        return try SelectedText("Hello")
    }
}

@MainActor
private final class SubscriptionScreenshotMock: ScreenshotCapturing {
    var captureCount = 0
    func captureRegion() async throws -> NSImage? {
        captureCount += 1
        return nil
    }
}

@Test @MainActor
func test_captureScreenshot_when_subscription_is_still_loading_then_waits_and_continues_for_subscriber() async throws {
    // Arrange
    let stub_store = DelayedInitialSubscriptionProvider()
    let access = SubscriptionAccessController(productID: "annual", provider: stub_store)
    let refresh = Task { await access.refresh() }
    await stub_store.waitUntilLoading()
    let mock_capture = SubscriptionScreenshotMock()
    var presentations = 0
    let controller = AppController(
        screenshotCapture: mock_capture,
        subscriptionAccess: access,
        onSubscriptionRequired: { presentations += 1 }
    )

    // Act
    let capture = Task { try await controller.captureScreenshot() }
    await Task.yield()
    #expect(presentations == 0)
    #expect(mock_capture.captureCount == 0)
    stub_store.finish([.init(productID: "annual", expiresAt: .distantFuture)])
    await refresh.value
    try await capture.value

    // Assert
    #expect(presentations == 0)
    #expect(mock_capture.captureCount == 1)
}

@MainActor
private final class DelayedInitialSubscriptionProvider: SubscriptionProviding {
    private var completion: CheckedContinuation<[SubscriptionEntitlement], Never>?
    private var started: CheckedContinuation<Void, Never>?

    func loadEntitlements() async throws -> [SubscriptionEntitlement] {
        await withCheckedContinuation {
            completion = $0
            started?.resume()
            started = nil
        }
    }

    func waitUntilLoading() async {
        if completion != nil { return }
        await withCheckedContinuation { started = $0 }
    }

    func finish(_ entitlements: [SubscriptionEntitlement]) {
        completion?.resume(returning: entitlements)
        completion = nil
    }

    func observeChanges(_ onChange: @escaping @MainActor @Sendable () async -> Void) async {}
}
