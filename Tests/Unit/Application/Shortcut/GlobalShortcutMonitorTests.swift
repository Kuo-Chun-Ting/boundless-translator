import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_acceptsEvent_when_other_monitor_exists_then_matches_only_own_event() {
    // Arrange
    let translation = GlobalShortcutMonitor(definition: .optionShiftT, handler: {})
    let other = GlobalShortcutMonitor(
        definition: GlobalShortcutDefinition(
            keyCode: 15,
            modifierFlags: [.option, .shift],
            keyEquivalent: "R"
        ),
        handler: {}
    )

    // Act & Assert
    #expect(translation.acceptsEvent(signature: 0x5754_524E, identifier: translation.identifier))
    #expect(other.acceptsEvent(signature: 0x5754_524E, identifier: other.identifier))
    #expect(!translation.acceptsEvent(signature: 0x5754_524E, identifier: other.identifier))
    #expect(!other.acceptsEvent(signature: 0x5754_524E, identifier: translation.identifier))
    #expect(!translation.acceptsEvent(signature: 0, identifier: translation.identifier))
}
