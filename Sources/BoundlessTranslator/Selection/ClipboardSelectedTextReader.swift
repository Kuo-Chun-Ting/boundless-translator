import AppKit

@MainActor
final class ClipboardSelectedTextReader: SelectedTextReading {
    private let pollInterval: Duration
    private let copyTimeout: Duration
    private let pasteboard: NSPasteboard
    private let hasAccessibilityPermission: @MainActor () -> Bool
    private let copier: any SelectedTextCopying

    init(
        pollInterval: Duration = .milliseconds(20),
        copyTimeout: Duration = .milliseconds(750),
        pasteboard: NSPasteboard = .general,
        hasAccessibilityPermission: @escaping @MainActor () -> Bool = { AXIsProcessTrusted() },
        copier: any SelectedTextCopying
    ) {
        self.pollInterval = pollInterval
        self.copyTimeout = copyTimeout
        self.pasteboard = pasteboard
        self.hasAccessibilityPermission = hasAccessibilityPermission
        self.copier = copier
    }

    func readSelectedText() async throws -> SelectedText {
        guard hasAccessibilityPermission() else {
            throw SelectedTextReadError.accessibilityPermissionRequired
        }

        try Task.checkCancellation()
        let clipboardBackup = try PasteboardSnapshot(pasteboard: pasteboard)
        let initialChangeCount = pasteboard.changeCount
        var copiedChangeCount: Int?
        defer {
            restoreClipboard(clipboardBackup, after: copiedChangeCount)
        }
        try copier.copySelection()
        return try await readCopiedText(initialChangeCount: initialChangeCount, copiedChangeCount: &copiedChangeCount)
    }

    private func readCopiedText(
        initialChangeCount: Int,
        copiedChangeCount: inout Int?
    ) async throws -> SelectedText {
        let deadline = ContinuousClock.now.advanced(by: copyTimeout)
        while ContinuousClock.now < deadline {
            try Task.checkCancellation()
            let changeCount = pasteboard.changeCount
            if changeCount != initialChangeCount {
                if let copiedChangeCount, copiedChangeCount != changeCount {
                    throw SelectedTextReadError.noSelection
                }
                copiedChangeCount = changeCount
                if let rawText = pasteboard.string(forType: .string) {
                    return try makeSelectedText(rawText)
                }
            }
            try await Task.sleep(for: pollInterval)
        }
        throw SelectedTextReadError.noSelection
    }

    private func restoreClipboard(_ backup: PasteboardSnapshot, after changeCount: Int?) {
        guard let changeCount else { return }
        backup.restore(to: pasteboard, ifUnchangedSince: changeCount)
    }

    private func makeSelectedText(_ rawText: String) throws -> SelectedText {
        do {
            return try SelectedText(rawText)
        } catch SelectedTextError.empty {
            throw SelectedTextReadError.noSelection
        }
    }
}

@MainActor
struct PasteboardSnapshot {
    private let items: [[NSPasteboard.PasteboardType: Data]]

    init(pasteboard: NSPasteboard) throws {
        items = try (pasteboard.pasteboardItems ?? []).map { item in
            try Dictionary(uniqueKeysWithValues: item.types.map { type in
                guard let data = item.data(forType: type) else {
                    throw SelectedTextReadError.readerUnavailable
                }
                return (type, data)
            })
        }
    }

    func restore(to pasteboard: NSPasteboard, ifUnchangedSince changeCount: Int) {
        let restoredItems = items.map { representations in
            let item = NSPasteboardItem()
            for (type, data) in representations {
                item.setData(data, forType: type)
            }
            return item
        }
        guard pasteboard.changeCount == changeCount else { return }
        pasteboard.clearContents()
        if !restoredItems.isEmpty { pasteboard.writeObjects(restoredItems) }
    }
}
