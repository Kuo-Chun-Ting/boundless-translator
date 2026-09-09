@preconcurrency import ApplicationServices
import AppKit

@MainActor
enum AccessibilityPermission {
    static func requestIfNeeded(
        isGranted: () -> Bool = { AXIsProcessTrusted() },
        explain: () -> Bool = {
            PermissionExplanation.confirm(permission: .accessibility)
        },
        openSettings: (URL) -> Bool = { NSWorkspace.shared.open($0) }
    ) {
        _ = PermissionExplanation.requestPermission(
            isGranted: isGranted,
            explain: explain,
            request: {
                // Open the permission pane; only the user can grant access there.
                let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                _ = openSettings(url)
                return isGranted()
            }
        )
    }
}
