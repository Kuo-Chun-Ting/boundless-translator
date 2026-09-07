import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_acceptsEvent_when_two_shortcuts_exist_then_matches_only_own_event() {
    // Arrange
    let translation = GlobalShortcutMonitor(definition: .optionShiftE, handler: {})
    let screenshot = GlobalShortcutMonitor(definition: .optionShiftR, handler: {})

    // Act & Assert
    #expect(translation.acceptsEvent(signature: 0x5754_524E, identifier: translation.identifier))
    #expect(screenshot.acceptsEvent(signature: 0x5754_524E, identifier: screenshot.identifier))
    #expect(!translation.acceptsEvent(signature: 0x5754_524E, identifier: screenshot.identifier))
    #expect(!screenshot.acceptsEvent(signature: 0x5754_524E, identifier: translation.identifier))
    #expect(!translation.acceptsEvent(signature: 0, identifier: translation.identifier))
}
