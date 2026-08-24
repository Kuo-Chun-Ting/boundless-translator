import AppKit

@MainActor
final class ClipboardSelectedTextReader: SelectedTextReading {
    private let pollInterval: Duration
    private let copyTimeout: Duration

    init(
        pollInterval: Duration = .milliseconds(20),
        copyTimeout: Duration = .milliseconds(750)
    ) {
        self.pollInterval = pollInterval
        self.copyTimeout = copyTimeout
    }

    func readSelectedText() async throws -> SelectedText {
        guard AXIsProcessTrusted() else {
            throw SelectedTextReadError.accessibilityPermissionRequired
        }

        let pasteboard = NSPasteboard.general
        let initialChangeCount = pasteboard.changeCount
        try postCopyShortcut()
        let observation = PasteboardCopyObservation(
            initialChangeCount: initialChangeCount
        )
        let deadline = ContinuousClock.now.advanced(by: copyTimeout)
        while ContinuousClock.now < deadline {
            let changeCount = pasteboard.changeCount
            if let rawText = observation.copiedText(
                currentChangeCount: changeCount,
                string: pasteboard.string(forType: .string)
            ) {
                return try makeSelectedText(rawText)
            }
            try await Task.sleep(for: pollInterval)
        }

        throw SelectedTextReadError.copyFailed
    }

    private func postCopyShortcut() throws {
        guard
            let source = CGEventSource(stateID: .combinedSessionState),
            let keyDown = CGEvent(
                keyboardEventSource: source,
                virtualKey: 8,
                keyDown: true
            ),
            let keyUp = CGEvent(
                keyboardEventSource: source,
                virtualKey: 8,
                keyDown: false
            )
        else {
            throw SelectedTextReadError.copyFailed
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    private func makeSelectedText(_ rawText: String) throws -> SelectedText {
        do {
            return try SelectedText(rawText)
        } catch SelectedTextError.empty {
            throw SelectedTextReadError.noSelection
        }
    }
}

struct PasteboardCopyObservation {
    let initialChangeCount: Int

    func copiedText(
        currentChangeCount: Int,
        string: String?
    ) -> String? {
        guard currentChangeCount != initialChangeCount else {
            return nil
        }
        return string
    }
}
