import AppKit
import Testing
@testable import BoundlessTranslator

@Test(arguments: ["shortcutRecorder", "screenshotShortcutRecorder"]) @MainActor
func test_recording_when_preferences_closes_then_restores_both_shortcuts(identifier: String) throws {
    // Arrange
    let fixture = try ShortcutPairFixture()
    defer { fixture.cleanup() }
    let button = try #require(findRecorder(in: fixture.content, identifier: identifier))

    // Act
    button.beginRecording()

    // Assert
    #expect(fixture.translationMonitor.active == false)
    #expect(fixture.screenshotMonitor.active == false)

    // Act
    fixture.window.close()

    // Assert
    #expect(fixture.translationMonitor.active)
    #expect(fixture.screenshotMonitor.active)
    #expect(!button.isRecording)
}

@Test @MainActor
func test_recording_when_other_shortcut_is_entered_then_rejects_duplicate_and_restores_both() throws {
    // Arrange
    let fixture = try ShortcutPairFixture()
    defer { fixture.cleanup() }
    let button = try #require(findRecorder(in: fixture.content, identifier: "screenshotShortcutRecorder"))
    let event = try #require(NSEvent.keyEvent(
        with: .keyDown, location: .zero, modifierFlags: [.option, .shift],
        timestamp: 0, windowNumber: fixture.window.windowNumber, context: nil,
        characters: "E", charactersIgnoringModifiers: "e", isARepeat: false, keyCode: 14
    ))
    button.beginRecording()

    // Act
    button.keyDown(with: event)

    // Assert
    #expect(fixture.translation.definition == .optionShiftE)
    #expect(fixture.screenshot.definition == .optionShiftR)
    #expect(fixture.screenshot.failure != nil)
    #expect(fixture.translationMonitor.active)
    #expect(fixture.screenshotMonitor.active)
}

@MainActor
private struct ShortcutPairFixture {
    let translationMonitor = RecordingMonitorMock()
    let screenshotMonitor = RecordingMonitorMock()
    let translation: GlobalShortcutController
    let screenshot: GlobalShortcutController
    let controller: PreferencesWindowController
    let window: NSWindow
    let content: NSView
    let defaults: UserDefaults
    let suiteName = "ShortcutPairTests.\(UUID().uuidString)"

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
        let translationMonitor = self.translationMonitor
        let screenshotMonitor = self.screenshotMonitor
        translation = GlobalShortcutController(
            defaults: defaults, makeMonitor: { _, _ in translationMonitor }, handler: {}
        )
        screenshot = GlobalShortcutController(
            kind: .screenshot, defaults: defaults, makeMonitor: { _, _ in screenshotMonitor }, handler: {}
        )
        try translation.start()
        try screenshot.start()
        controller = PreferencesWindowController(
            settings: TranslationSettings(), interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
            shortcutController: translation, screenshotShortcutController: screenshot,
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
private func findRecorder(in view: NSView, identifier: String) -> ShortcutRecorderButton? {
    if view.accessibilityIdentifier() == identifier { return view as? ShortcutRecorderButton }
    return view.subviews.lazy.compactMap { findRecorder(in: $0, identifier: identifier) }.first
}
