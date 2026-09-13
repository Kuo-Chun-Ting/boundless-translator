import ApplicationServices

enum SelectedTextReadError: LocalizedError {
    case accessibilityPermissionRequired
    case readerUnavailable
    case noSelection
    case copyFailed

    var errorDescription: String? {
        switch self {
        case .accessibilityPermissionRequired:
            "Allow \(AppBrand.displayName) in System Settings > Privacy & Security > Accessibility."
        case .readerUnavailable:
            "The selected text could not be read from this app."
        case .noSelection:
            "No selected text was found. Select text and use the translation shortcut again."
        case .copyFailed:
            "The selected text could not be copied from this app."
        }
    }
}

@MainActor
final class AccessibilitySelectedTextReader: SelectedTextReading {
    typealias ReadRawSelectedText = @MainActor () throws -> String?

    private let isProcessTrusted: @MainActor () -> Bool
    private let readRawSelectedText: ReadRawSelectedText

    init(
        isProcessTrusted: @escaping @MainActor () -> Bool = {
            AXIsProcessTrusted()
        },
        readRawSelectedText: ReadRawSelectedText? = nil
    ) {
        self.isProcessTrusted = isProcessTrusted
        self.readRawSelectedText = readRawSelectedText ?? Self.readSystemSelectedText
    }

    func readSelectedText() async throws -> SelectedText {
        guard isProcessTrusted() else {
            throw SelectedTextReadError.accessibilityPermissionRequired
        }

        guard let rawText = try readRawSelectedText() else {
            throw SelectedTextReadError.noSelection
        }

        do {
            return try SelectedText(rawText)
        } catch SelectedTextError.empty {
            throw SelectedTextReadError.noSelection
        }
    }

    private static func readSystemSelectedText() throws -> String? {
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
            throw SelectedTextReadError.readerUnavailable
        }

        let focusedElement = focusedElementValue as! AXUIElement
        var selectedTextValue: CFTypeRef?
        let selectedTextResult = AXUIElementCopyAttributeValue(
            focusedElement,
            kAXSelectedTextAttribute as CFString,
            &selectedTextValue
        )
        if selectedTextResult == .noValue {
            return nil
        }
        guard selectedTextResult == .success else {
            throw SelectedTextReadError.readerUnavailable
        }
        guard let selectedTextValue else {
            return nil
        }
        guard let rawText = selectedTextValue as? String else {
            throw SelectedTextReadError.readerUnavailable
        }
        return rawText
    }
}
