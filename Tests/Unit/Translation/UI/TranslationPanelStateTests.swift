import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_isPinned_when_state_is_created_then_is_false() {
    // Arrange / Act
    let state = TranslationWindowState()

    // Assert
    #expect(!state.isPinned)
}

@Test @MainActor
func test_togglePin_when_state_is_unpinned_then_pinsWindow() {
    // Arrange
    let state = TranslationWindowState()

    // Act
    state.togglePin()

    // Assert
    #expect(state.isPinned)
}

@Test @MainActor
func test_reset_when_state_is_pinned_then_unpinsWindow() {
    // Arrange
    let state = TranslationWindowState()
    state.togglePin()

    // Act
    state.reset()

    // Assert
    #expect(!state.isPinned)
}
