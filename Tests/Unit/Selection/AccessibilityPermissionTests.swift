import Foundation
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_requestIfNeeded_when_already_granted_then_does_not_prompt_or_open_settings() {
    // Arrange
    var mock_calls: [String] = []

    // Act
    AccessibilityPermission.requestIfNeeded(
        isGranted: { true },
        explain: { mock_calls.append("explain"); return true },
        openSettings: { _ in mock_calls.append("open"); return true }
    )

    // Assert
    #expect(mock_calls.isEmpty)
}

@Test @MainActor
func test_requestIfNeeded_when_declined_then_does_not_open_settings() {
    // Arrange
    var mock_opened = false

    // Act
    AccessibilityPermission.requestIfNeeded(
        isGranted: { false }, explain: { false },
        openSettings: { _ in mock_opened = true; return true }
    )

    // Assert
    #expect(!mock_opened)
}

@Test @MainActor
func test_requestIfNeeded_when_confirmed_then_opens_accessibility_settings() {
    // Arrange
    var mock_destination: URL?
    var mock_calls: [String] = []

    // Act
    AccessibilityPermission.requestIfNeeded(
        isGranted: { false }, explain: { true },
        openSettings: { mock_calls.append("settings"); mock_destination = $0; return true }
    )

    // Assert
    #expect(mock_destination?.absoluteString ==
        "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    #expect(mock_calls == ["settings"])
}
