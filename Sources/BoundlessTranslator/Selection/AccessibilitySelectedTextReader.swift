import AppKit
import ApplicationServices

enum SelectedTextReadError: LocalizedError {
    case accessibilityPermissionRequired
    case readerUnavailable
    case noSelection

    var errorDescription: String? {
        switch self {
        case .accessibilityPermissionRequired:
            "Allow \(AppBrand.displayName) in System Settings > Privacy & Security > Accessibility."
        case .readerUnavailable:
            "The selected text could not be read from this app."
        case .noSelection:
            "No selected text was found. Select text and use the translation shortcut again."
        }
    }
}

@MainActor
final class AccessibilitySelectedTextReader: SelectedTextReading {
    typealias ReadRawSelectedText = @Sendable () throws -> String?

    private let hasAccessibilityPermission: @MainActor () -> Bool
    private let readRawSelectedText: ReadRawSelectedText?

    init(
        hasAccessibilityPermission: @escaping @MainActor () -> Bool = {
            AXIsProcessTrusted()
        },
        readRawSelectedText: ReadRawSelectedText? = nil
    ) {
        self.hasAccessibilityPermission = hasAccessibilityPermission
        self.readRawSelectedText = readRawSelectedText
    }

    func readSelectedText() async throws -> SelectedText {
        guard hasAccessibilityPermission() else {
            throw SelectedTextReadError.accessibilityPermissionRequired
        }

        try Task.checkCancellation()
        let processIdentifier = NSWorkspace.shared.frontmostApplication?.processIdentifier
        let read = readRawSelectedText ?? { try Self.readSystemSelectedText(processIdentifier: processIdentifier) }
        let selection: SelectedText = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(with: Result { try Self.readSelection(using: read) })
            }
        }
        try Task.checkCancellation()
        return selection
    }

    private nonisolated static func readSelection(using read: ReadRawSelectedText) throws -> SelectedText {
        guard let rawText = try read() else { throw SelectedTextReadError.noSelection }
        do {
            return try SelectedText(rawText)
        } catch SelectedTextError.empty {
            throw SelectedTextReadError.noSelection
        }
    }

    private nonisolated static func readSystemSelectedText(processIdentifier: pid_t?) throws -> String? {
        guard let processIdentifier else { throw SelectedTextReadError.readerUnavailable }
        let systemWideElement = AXUIElementCreateApplication(processIdentifier)
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
