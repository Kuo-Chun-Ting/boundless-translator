import Foundation
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_screenPermission_when_already_granted_then_skips_prompt() {
    // Arrange
    var mock_calls: [String] = []

    // Act
    let granted = ScreenRecordingPermission.requestIfNeeded(
        isGranted: { true },
        explain: { mock_calls.append("explain"); return true },
        requestAccess: { mock_calls.append("request"); return true }
    )

    // Assert
    #expect(granted)
    #expect(mock_calls.isEmpty)
}

@Test @MainActor
func test_screenPermission_when_explanation_declined_then_does_not_request_system_permission() {
    // Arrange
    var mock_calls: [String] = []

    // Act
    let granted = ScreenRecordingPermission.requestIfNeeded(
        isGranted: { false }, explain: { false },
        requestAccess: { mock_calls.append("request"); return true }
    )

    // Assert
    #expect(!granted)
    #expect(mock_calls.isEmpty)
}

@Test @MainActor
func test_screenPermission_when_system_grants_access_then_returns_granted() {
    // Arrange
    let stub_requestAccess = true

    // Act
    let granted = ScreenRecordingPermission.requestIfNeeded(
        isGranted: { false }, explain: { true }, requestAccess: { stub_requestAccess }
    )

    // Assert
    #expect(granted)
}

@Test @MainActor
func test_screenPermission_when_system_does_not_grant_access_then_leaves_navigation_to_system_prompt() {
    // Arrange
    var mock_calls: [String] = []

    // Act
    let granted = ScreenRecordingPermission.requestIfNeeded(
        isGranted: { false }, explain: { true },
        requestAccess: { mock_calls.append("request"); return false }
    )

    // Assert
    #expect(!granted)
    #expect(mock_calls == ["request"])
}
