import ApplicationServices

enum SelectedTextReadError: LocalizedError {
    case accessibilityPermissionRequired
    case noSelection
    case copyFailed

    var errorDescription: String? {
        switch self {
        case .accessibilityPermissionRequired:
            "Allow \(AppBrand.displayName) in System Settings > Privacy & Security > Accessibility."
        case .noSelection:
            "No selected text was found. Select text and press Command-Shift-T again."
        case .copyFailed:
            "The selected text could not be copied from this app."
        }
    }
}

@MainActor
final class AccessibilitySelectedTextReader: SelectedTextReading {
    func readSelectedText() async throws -> SelectedText {
        guard AXIsProcessTrusted() else {
            throw SelectedTextReadError.accessibilityPermissionRequired
        }

        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElementValue: CFTypeRef?
        let focusedElementResult = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElementValue
        )
        guard
            focusedElementResult == .success,
            let focusedElementValue
        else {
            throw SelectedTextReadError.noSelection
        }

        let focusedElement = focusedElementValue as! AXUIElement
        var selectedTextValue: CFTypeRef?
        let selectedTextResult = AXUIElementCopyAttributeValue(
            focusedElement,
            kAXSelectedTextAttribute as CFString,
            &selectedTextValue
        )
        guard
            selectedTextResult == .success,
            let rawText = selectedTextValue as? String
        else {
            throw SelectedTextReadError.noSelection
        }

        do {
            return try SelectedText(rawText)
        } catch SelectedTextError.empty {
            throw SelectedTextReadError.noSelection
        }
    }
}
