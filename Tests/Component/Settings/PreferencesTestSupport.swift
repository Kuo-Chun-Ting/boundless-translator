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
private final class NoOpShortcutMonitor: GlobalShortcutMonitoring {
    func start() throws {}
    func stop() {}
}
