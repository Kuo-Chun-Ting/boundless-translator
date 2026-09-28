import AppKit

@MainActor
protocol SelectedTextCopying {
    func copySelection() throws -> Void
}

@MainActor
struct SystemSelectedTextCopier: SelectedTextCopying {
    func copySelection() throws -> Void {
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
            throw SelectedTextReadError.noSelection
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
