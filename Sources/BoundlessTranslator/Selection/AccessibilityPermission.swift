@preconcurrency import ApplicationServices

enum AccessibilityPermission {
    static func requestIfNeeded() {
        guard !AXIsProcessTrusted() else {
            return
        }

        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
