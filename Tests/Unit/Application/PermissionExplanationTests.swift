import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_requestPermission_when_already_granted_then_does_not_interrupt_user() {
    // Arrange
    var explained = false
    var requested = false

    // Act
    let granted = PermissionExplanation.requestPermission(
        isGranted: { true },
        explain: { explained = true; return true },
        request: { requested = true; return true }
    )

    // Assert
    #expect(granted)
    #expect(!explained)
    #expect(!requested)
}

@Test @MainActor
func test_requestPermission_when_user_declines_explanation_then_does_not_request_system_permission() {
    // Arrange
    var requested = false

    // Act
    let granted = PermissionExplanation.requestPermission(
        isGranted: { false }, explain: { false },
        request: { requested = true; return true }
    )

    // Assert
    #expect(!granted)
    #expect(!requested)
}

@Test @MainActor
func test_requestPermission_when_user_continues_then_explains_before_request_and_returns_system_result() {
    // Arrange
    var calls: [String] = []

    // Act
    let granted = PermissionExplanation.requestPermission(
        isGranted: { false },
        explain: { calls.append("explain"); return true },
        request: { calls.append("request"); return false }
    )

    // Assert
    #expect(calls == ["explain", "request"])
    #expect(!granted)
}
