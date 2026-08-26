import AppKit
import Carbon.HIToolbox

struct GlobalShortcutDefinition {
    static let commandShiftT = GlobalShortcutDefinition(
        keyCode: 17,
        modifierFlags: [.command, .shift]
    )

    let keyCode: UInt16
    let modifierFlags: NSEvent.ModifierFlags

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
