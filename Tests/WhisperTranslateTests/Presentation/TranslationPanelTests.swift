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

@Test @MainActor
func test_cancelOperation_when_handlerIsConfigured_thenForwardsRequest() {
    // Arrange
    let panel = TranslationPanel()
    var forwardedSender: String?
    panel.cancelOperationHandler = { sender in
        forwardedSender = sender as? String
    }

    // Act
    panel.cancelOperation("escape")

    // Assert
    #expect(forwardedSender == "escape")
}

@Test @MainActor
func test_configureChrome_when_translation_is_presented_then_keeps_resizable_native_title_bar() {
    // Arrange
    let panel = TranslationPanel()

    // Act
    panel.configureChrome(for: .translation)

    // Assert
    #expect(panel.styleMask.contains(.titled))
    #expect(panel.styleMask.contains(.closable))
    #expect(panel.styleMask.contains(.miniaturizable))
    #expect(panel.styleMask.contains(.resizable))
    #expect(panel.isOpaque)
    #expect(panel.backgroundColor == .windowBackgroundColor)
}

@Test @MainActor
func test_configureChrome_when_auxiliary_content_follows_translation_then_restores_title_bar() {
    // Arrange
    let panel = TranslationPanel()
    panel.configureChrome(for: .translation)

    // Act
    panel.configureChrome(for: .error)

    // Assert
    #expect(panel.styleMask.contains(.titled))
    #expect(panel.styleMask.contains(.closable))
    #expect(panel.isOpaque)
    #expect(panel.backgroundColor == .windowBackgroundColor)
}
