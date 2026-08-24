import Testing
@testable import WhisperTranslate

@Test @MainActor
func test_present_when_preferencesAreRequested_then_defersAndForcesWindowToFront() {
    // Arrange
    let coordinator = PreferencesPresentationCoordinator()
    var calls: [String] = []
    var deferredPresentation: (@MainActor () -> Void)?

    // Act
    coordinator.present(
        deferPresentation: { deferredPresentation = $0 },
        activateApplication: { calls.append("activate") },
        showWindow: { calls.append("show") },
        forceWindowToFront: { calls.append("front") }
    )

    // Assert
    #expect(calls.isEmpty)

    deferredPresentation?()
    #expect(calls == ["activate", "show", "front"])
}
