import Foundation
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_readSelectedText_when_accessibility_returns_empty_text_then_reports_no_selection() async {
    // Arrange
    let reader = AccessibilitySelectedTextReader(
        hasAccessibilityPermission: { true },
        readRawSelectedText: { "" }
    )

    // Act & Assert
    do {
        _ = try await reader.readSelectedText()
        Issue.record("Expected no selection")
    } catch SelectedTextReadError.noSelection {
        // Expected.
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}

@Test @MainActor
func test_readSelectedText_when_cancelledReadIsStillBlocked_then_newReadCanFinishIndependently() async throws {
    // Arrange
    let gate = BlockingSelectionRead()
    let reader = AccessibilitySelectedTextReader(hasAccessibilityPermission: { true }, readRawSelectedText: { gate.read() })
    let oldTask = Task { try await reader.readSelectedText() }
    defer { gate.release.signal() }
    for await _ in gate.started.stream { break }
    try #require(gate.callCount == 1)

    // Act
    oldTask.cancel()
    let newSelection = try await reader.readSelectedText()
    gate.release.signal()
    let oldResult = await oldTask.result

    // Assert
    #expect(newSelection.value == "New selection")
    #expect(gate.calledOnMainThread == false)
    guard case .failure(let error) = oldResult else {
        Issue.record("Cancelled read must not return the old selection")
        return
    }
    #expect(error is CancellationError)
}

private final class BlockingSelectionRead: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    private var ranOnMain = false
    let release = DispatchSemaphore(value: 0)
    let started = AsyncStream<Void>.makeStream()
    var callCount: Int { lock.withLock { count } }
    var calledOnMainThread: Bool { lock.withLock { ranOnMain } }
    func read() -> String? {
        let first = lock.withLock {
            count += 1
            ranOnMain = ranOnMain || Thread.isMainThread
            return count == 1
        }
        if first {
            started.continuation.yield(())
            _ = release.wait(timeout: .now() + 120)
            return "Old selection"
        }
        return "New selection"
    }
}
