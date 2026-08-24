import Testing
@testable import WhisperTranslate

@Test @MainActor
func test_present_when_preferences_areRequested_then_activatesApplicationBeforeShowingWindow() {
    // Arrange
    let coordinator = PreferencesPresentationCoordinator()
    var calls: [String] = []

    // Act
    coordinator.present(
        activateApplication: { calls.append("activate") },
        showWindow: { calls.append("show") }
    )

    // Assert
    #expect(calls == ["activate", "show"])
}
