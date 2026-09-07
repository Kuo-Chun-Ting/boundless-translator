import AppKit
import Carbon.HIToolbox
import Testing
@testable import BoundlessTranslator

@Test
func test_carbonModifierFlags_when_option_shift_e_is_used_then_contains_option_and_shift() {
    // Arrange
    let shortcut = GlobalShortcutDefinition.optionShiftE

    // Act
    let modifiers = shortcut.carbonModifierFlags

    // Assert
    #expect(modifiers == UInt32(optionKey | shiftKey))
}

@Test
func test_carbonRegistrationOptions_when_shortcut_is_registered_then_requests_exclusive_access() {
    // Arrange
    let shortcut = GlobalShortcutDefinition.optionShiftE

    // Act
    let options = shortcut.carbonRegistrationOptions

    // Assert
    #expect(options == UInt32(kEventHotKeyExclusive))
}

@Test
func test_displayName_when_option_shift_e_is_used_then_uses_keyboard_symbols() {
    // Arrange
    let shortcut = GlobalShortcutDefinition.optionShiftE

    // Act
    let displayName = shortcut.displayName

    // Assert
    #expect(displayName == "⌥⇧E")
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
