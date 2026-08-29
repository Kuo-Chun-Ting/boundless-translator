import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let controller = AppController()

    private let applicationOpenCoordinator = ApplicationOpenCoordinator()
    private var shortcutMonitor: GlobalShortcutMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        controller.prepare()
        AccessibilityPermission.requestIfNeeded()

        let shortcutMonitor = GlobalShortcutMonitor { [weak self] in
            self?.controller.translateCurrentSelection()
        }
        do {
            try shortcutMonitor.start()
            self.shortcutMonitor = shortcutMonitor
        } catch {
            controller.showError(error.localizedDescription)
        }

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
