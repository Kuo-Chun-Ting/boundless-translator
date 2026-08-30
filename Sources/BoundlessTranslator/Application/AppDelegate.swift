import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let controller = AppController()

    private let applicationOpenCoordinator = ApplicationOpenCoordinator()

    func applicationDidFinishLaunching(_ notification: Notification) {
        controller.prepare()
        AccessibilityPermission.requestIfNeeded()

        applicationOpenCoordinator.handleInitialLaunch {
            controller.showPreferences()
        }
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        applicationOpenCoordinator.handleReopen {
            controller.showPreferences()
        }
    }
}
