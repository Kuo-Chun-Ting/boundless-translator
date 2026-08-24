import AppKit
import Carbon.HIToolbox
import Testing
@testable import WhisperTranslate

@Test
func test_carbonModifierFlags_when_command_shift_t_is_used_then_contains_command_and_shift() {
    // Arrange
    let shortcut = GlobalShortcutDefinition.commandShiftT

    // Act
    let modifiers = shortcut.carbonModifierFlags

    // Assert
    #expect(modifiers == UInt32(cmdKey | shiftKey))
}

@Test
func test_carbonRegistrationOptions_when_shortcut_is_registered_then_requests_exclusive_access() {
    // Arrange
    let shortcut = GlobalShortcutDefinition.commandShiftT

    // Act
    let options = shortcut.carbonRegistrationOptions

    // Assert
    #expect(options == UInt32(kEventHotKeyExclusive))
}
