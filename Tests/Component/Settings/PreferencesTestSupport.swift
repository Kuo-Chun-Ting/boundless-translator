import Foundation
@testable import BoundlessTranslator

@MainActor
func makeTestShortcutController() -> GlobalShortcutController {
    let suiteName = "PreferencesComponentTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return GlobalShortcutController(
        defaults: defaults,
        makeMonitor: { _, _ in NoOpShortcutMonitor() },
        handler: {}
    )
}

@MainActor
func makeFailingTestShortcutController() -> GlobalShortcutController {
    let suiteName = "PreferencesComponentTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    let controller = GlobalShortcutController(
        defaults: defaults,
        makeMonitor: { _, _ in
            FailingShortcutMonitor(
                error: GlobalShortcutError.registrationFailed(-9878)
            )
        },
        handler: {}
    )
    try? controller.start()
    return controller
}

@MainActor
private final class NoOpShortcutMonitor: GlobalShortcutMonitoring {
    func start() throws {}
    func stop() {}
}

@MainActor
private final class FailingShortcutMonitor: GlobalShortcutMonitoring {
    private let error: Error

    init(error: Error) {
        self.error = error
    }

    func start() throws {
        throw error
    }

    func stop() {}
}
