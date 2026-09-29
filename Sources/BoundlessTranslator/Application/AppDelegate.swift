import AppKit
import TipKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let controller = AppController()

    private let applicationOpenCoordinator = ApplicationOpenCoordinator()

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            try Tips.configure()
        } catch {
            NSLog("Unable to configure tips: %@", error.localizedDescription)
        }
        controller.prepare()
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
