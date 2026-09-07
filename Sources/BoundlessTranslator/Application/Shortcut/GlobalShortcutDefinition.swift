import AppKit
import Carbon.HIToolbox

struct GlobalShortcutDefinition: Equatable {
    static let optionShiftR = GlobalShortcutDefinition(
        keyCode: 15,
        modifierFlags: [.option, .shift],
        keyEquivalent: "R"
    )

    static let optionShiftE = GlobalShortcutDefinition(
        keyCode: 14,
        modifierFlags: [.option, .shift],
        keyEquivalent: "E"
    )

    let keyCode: UInt16
    let modifierFlags: NSEvent.ModifierFlags
    let keyEquivalent: String

    var displayName: String {
        var parts: [String] = []
        if modifierFlags.contains(.control) {
            parts.append("⌃")
        }
        if modifierFlags.contains(.option) {
            parts.append("⌥")
        }
        if modifierFlags.contains(.shift) {
            parts.append("⇧")
        }
        if modifierFlags.contains(.command) {
            parts.append("⌘")
        }
        parts.append(keyEquivalent.uppercased())
        return parts.joined()
    }

    var isValid: Bool {
        let primaryModifiers: NSEvent.ModifierFlags = [.command, .option, .control]
        return !keyEquivalent.isEmpty
            && !modifierFlags.intersection(primaryModifiers).isEmpty
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
