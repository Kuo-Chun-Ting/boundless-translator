import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_recording_when_preferences_closes_then_restores_shortcut() throws {
    // Arrange
    let fixture = try ShortcutFixture()
    defer { fixture.cleanup() }
    let button = try #require(findRecorder(in: fixture.content))

    // Act
    button.beginRecording()

    // Assert
    #expect(fixture.monitor.active == false)

    // Act
    fixture.window.close()

    // Assert
    #expect(fixture.monitor.active)
    #expect(!button.isRecording)
}

@MainActor
private struct ShortcutFixture {
    let monitor = RecordingMonitorMock()
    let controller: PreferencesWindowController
    let window: NSWindow
    let content: NSView
    let defaults: UserDefaults
    let suiteName = "ShortcutTests.\(UUID().uuidString)"

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
        let monitor = self.monitor
        let shortcut = GlobalShortcutController(
            defaults: defaults,
            makeMonitor: { _, _ in monitor },
            handler: {}
        )
        try shortcut.start()
        controller = PreferencesWindowController(
            settings: TranslationSettings(),
            interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
            shortcutController: shortcut,
            supportedLanguageCatalog: makeStubLanguageCatalog()
        )
        window = try #require(controller.window)
        content = try #require(window.contentView)
        content.layoutSubtreeIfNeeded()
    }

    func cleanup() {
        window.close()
        defaults.removePersistentDomain(forName: suiteName)
    }
}

@MainActor
private final class RecordingMonitorMock: GlobalShortcutMonitoring {
    var active = false
    func start() throws { active = true }
    func stop() { active = false }
}

@MainActor
private func findRecorder(in view: NSView) -> ShortcutRecorderButton? {
    if view.accessibilityIdentifier() == "shortcutRecorder" {
        return view as? ShortcutRecorderButton
    }
    return view.subviews.lazy.compactMap(findRecorder).first
}
