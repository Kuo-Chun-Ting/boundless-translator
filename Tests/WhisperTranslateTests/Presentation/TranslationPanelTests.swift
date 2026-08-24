import Testing
@testable import WhisperTranslate

@Test @MainActor
func test_canBecomeKey_when_panel_isPresented_then_returns_true() {
    // Arrange
    let panel = TranslationPanel()

    // Act
    let canBecomeKey = panel.canBecomeKey

    // Assert
    #expect(canBecomeKey)
}
