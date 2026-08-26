import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_isPinned_when_state_is_created_then_is_false() {
    // Arrange / Act
    let state = TranslationPanelState()

    // Assert
    #expect(!state.isPinned)
}

@Test @MainActor
func test_pinRotationDegrees_when_state_is_unpinned_then_returns_diagonal_angle() {
    // Arrange
    let state = TranslationPanelState()

    // Act
    let rotationDegrees = state.pinRotationDegrees

    // Assert
    #expect(rotationDegrees == 45)
}

@Test @MainActor
func test_pinRotationDegrees_when_state_is_pinned_then_returns_vertical_angle() {
    // Arrange
    let state = TranslationPanelState()
    state.togglePin()

    // Act
    let rotationDegrees = state.pinRotationDegrees

    // Assert
    #expect(rotationDegrees == 0)
}

@Test @MainActor
func test_togglePin_when_state_is_unpinned_then_pinsPanel() {
    // Arrange
    let state = TranslationPanelState()

    // Act
    state.togglePin()

    // Assert
    #expect(state.isPinned)
}

@Test @MainActor
func test_reset_when_state_is_pinned_then_unpinsPanel() {
    // Arrange
    let state = TranslationPanelState()
    state.togglePin()

    // Act
    state.reset()

    // Assert
    #expect(!state.isPinned)
}
