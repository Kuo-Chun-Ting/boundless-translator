import AppKit
import Carbon.HIToolbox
import Testing
@testable import BoundlessTranslator

@Test
func test_carbonModifierFlags_when_command_shift_1_is_used_then_contains_command_and_shift() {
    // Arrange
    let shortcut = GlobalShortcutDefinition.commandShift1

    // Act
    let modifiers = shortcut.carbonModifierFlags

    // Assert
    #expect(modifiers == UInt32(cmdKey | shiftKey))
}

@Test
func test_carbonRegistrationOptions_when_shortcut_is_registered_then_requests_exclusive_access() {
    // Arrange
    let shortcut = GlobalShortcutDefinition.commandShift1

    // Act
    let options = shortcut.carbonRegistrationOptions

    // Assert
    #expect(options == UInt32(kEventHotKeyExclusive))
}

@Test
func test_displayName_when_command_shift_1_is_used_then_uses_keyboard_symbols() {
    // Arrange
    let shortcut = GlobalShortcutDefinition.commandShift1

    // Act
    let displayName = shortcut.displayName

    // Assert
    #expect(displayName == "⇧⌘1")
}

@Test
func test_commandShift2_when_created_then_uses_command_shift_2() {
    // Arrange
    let shortcut = GlobalShortcutDefinition.commandShift2

    // Act
    let displayName = shortcut.displayName

    // Assert
    #expect(shortcut.keyCode == 19)
    #expect(shortcut.carbonModifierFlags == UInt32(cmdKey | shiftKey))
    #expect(displayName == "⇧⌘2")
}

@Test
func test_isValid_when_shortcut_has_command_modifier_then_returns_true() {
    // Arrange
    let shortcut = GlobalShortcutDefinition(
        keyCode: 0,
        modifierFlags: [.command],
        keyEquivalent: "A"
    )

    // Act
    let isValid = shortcut.isValid

    // Assert
    #expect(isValid)
}

@Test
func test_isValid_when_shortcut_has_only_shift_modifier_then_returns_false() {
    // Arrange
    let shortcut = GlobalShortcutDefinition(
        keyCode: 0,
        modifierFlags: [.shift],
        keyEquivalent: "A"
    )

    // Act
    let isValid = shortcut.isValid

    // Assert
    #expect(!isValid)
}
