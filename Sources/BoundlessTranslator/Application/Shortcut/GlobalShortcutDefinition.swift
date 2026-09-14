import AppKit
import Carbon.HIToolbox
import KeyboardShortcuts

struct GlobalShortcutDefinition: Equatable {
    static let commandShift1 = GlobalShortcutDefinition(
        keyCode: 18,
        modifierFlags: [.command, .shift]
    )

    static let commandShift2 = GlobalShortcutDefinition(
        keyCode: 19,
        modifierFlags: [.command, .shift]
    )

    let keyCode: UInt16
    let modifierFlags: NSEvent.ModifierFlags

    @MainActor
    var displayName: String {
        KeyboardShortcuts.Shortcut(
            carbonKeyCode: Int(keyCode),
            carbonModifiers: Int(carbonModifierFlags)
        ).description
    }

    var isValid: Bool {
        let primaryModifiers: NSEvent.ModifierFlags = [.command, .option, .control]
        return !modifierFlags.intersection(primaryModifiers).isEmpty
    }

    var carbonRegistrationOptions: UInt32 {
        UInt32(kEventHotKeyExclusive)
    }

    var carbonModifierFlags: UInt32 {
        var flags: UInt32 = 0
        if modifierFlags.contains(.command) {
            flags |= UInt32(cmdKey)
        }
        if modifierFlags.contains(.shift) {
            flags |= UInt32(shiftKey)
        }
        if modifierFlags.contains(.option) {
            flags |= UInt32(optionKey)
        }
        if modifierFlags.contains(.control) {
            flags |= UInt32(controlKey)
        }
        return flags
    }
}
