import Testing
@testable import WhisperTranslate

@Test
func test_shouldDismissForOutsideClick_when_translation_is_unpinned_then_returns_true() {
    // Arrange
    let policy = PanelInteractionPolicy(kind: .translation)

    // Act
    let shouldDismiss = policy.shouldDismissForOutsideClick(isPinned: false)

    // Assert
    #expect(shouldDismiss)
}

@Test
func test_shouldDismissForOutsideClick_when_translation_is_pinned_then_returns_false() {
    // Arrange
    let policy = PanelInteractionPolicy(kind: .translation)

    // Act
    let shouldDismiss = policy.shouldDismissForOutsideClick(isPinned: true)

    // Assert
    #expect(!shouldDismiss)
}

@Test
func test_shouldDismissForOutsideClick_when_error_is_presented_then_returns_true() {
    // Arrange
    let policy = PanelInteractionPolicy(kind: .error)

    // Act
    let shouldDismiss = policy.shouldDismissForOutsideClick(isPinned: false)

    // Assert
    #expect(shouldDismiss)
}

@Test
func test_shouldDismissForOutsideClick_when_sourceLanguageSelection_is_presented_then_returns_false() {
    // Arrange
    let policy = PanelInteractionPolicy(kind: .sourceLanguageSelection)

    // Act
    let shouldDismiss = policy.shouldDismissForOutsideClick(isPinned: false)

    // Assert
    #expect(!shouldDismiss)
}
