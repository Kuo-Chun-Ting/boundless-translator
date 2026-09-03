import AppKit
import Foundation
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_init_when_shortcut_is_missing_then_uses_command_shift_t() {
    // Arrange
    let fixture_defaults = makeShortcutDefaults()
    defer { fixture_defaults.cleanUp() }

    // Act
    let controller = GlobalShortcutController(
        defaults: fixture_defaults.defaults,
        makeMonitor: MockGlobalShortcutMonitorFactory().make,
        handler: {}
    )

    // Assert
    #expect(controller.definition == .commandShiftT)
}

@Test @MainActor
func test_updateShortcut_when_registration_succeeds_then_activates_and_persists_candidate() {
    // Arrange
    let fixture_defaults = makeShortcutDefaults()
    defer { fixture_defaults.cleanUp() }
    let mock_factory = MockGlobalShortcutMonitorFactory()
    let controller = GlobalShortcutController(
        defaults: fixture_defaults.defaults,
        makeMonitor: mock_factory.make,
        handler: {}
    )
    let candidate = GlobalShortcutDefinition(
        keyCode: 40,
        modifierFlags: [.command, .option],
        keyEquivalent: "K"
    )
    try? controller.start()

    // Act
    controller.updateShortcut(candidate)
    let restoredController = GlobalShortcutController(
        defaults: fixture_defaults.defaults,
        makeMonitor: MockGlobalShortcutMonitorFactory().make,
        handler: {}
    )

    // Assert
    #expect(controller.definition == candidate)
    #expect(controller.failureMessage(localization: englishLocalization) == nil)
    #expect(restoredController.definition == candidate)
    #expect(mock_factory.definitions == [.commandShiftT, candidate])
}

@Test @MainActor
func test_updateShortcut_when_registration_fails_then_restores_previous_shortcut() {
    // Arrange
    let fixture_defaults = makeShortcutDefaults()
    defer { fixture_defaults.cleanUp() }
    let mock_factory = MockGlobalShortcutMonitorFactory(
        startResults: [.success(()), .failure(MockShortcutError.conflict), .success(())]
    )
    let controller = GlobalShortcutController(
        defaults: fixture_defaults.defaults,
        makeMonitor: mock_factory.make,
        handler: {}
    )
    let candidate = GlobalShortcutDefinition(
        keyCode: 40,
        modifierFlags: [.command, .option],
        keyEquivalent: "K"
    )
    try? controller.start()

    // Act
    controller.updateShortcut(candidate)

    // Assert
    #expect(controller.definition == .commandShiftT)
    #expect(
        controller.failureMessage(localization: englishLocalization)
            == "The shortcut is already in use."
    )
    #expect(mock_factory.definitions == [.commandShiftT, candidate, .commandShiftT])
}

@Test @MainActor
func test_cancelRecording_when_shortcutWasActive_then_reactivatesCurrentShortcut() {
    // Arrange
    let fixture_defaults = makeShortcutDefaults()
    defer { fixture_defaults.cleanUp() }
    let mock_factory = MockGlobalShortcutMonitorFactory()
    let controller = GlobalShortcutController(
        defaults: fixture_defaults.defaults,
        makeMonitor: mock_factory.make,
        handler: {}
    )
    try? controller.start()

    // Act
    controller.beginRecording()
    controller.cancelRecording()

    // Assert
    #expect(mock_factory.stopCount == 1)
    #expect(mock_factory.definitions == [.commandShiftT, .commandShiftT])
    #expect(controller.failureMessage(localization: englishLocalization) == nil)
}

@Test
func test_message_when_registrationFailsAndLanguageIsTraditionalChinese_then_localizesMessage() {
    // Arrange
    let error = GlobalShortcutError.registrationFailed(-9876)
    let localization = AppLocalization(languageIdentifier: "zh-Hant")

    // Act
    let message = error.message(localization: localization)

    // Assert
    #expect(message == "無法註冊鍵盤快速鍵（-9876）。其他 App 可能正在使用此快速鍵。")
}

@MainActor
private final class MockGlobalShortcutMonitorFactory {
    private var startResults: [Result<Void, Error>]
    private(set) var definitions: [GlobalShortcutDefinition] = []
    private(set) var stopCount = 0

    init(startResults: [Result<Void, Error>] = []) {
        self.startResults = startResults
    }

    func make(
        definition: GlobalShortcutDefinition,
        handler: @escaping @MainActor () -> Void
    ) -> any GlobalShortcutMonitoring {
        definitions.append(definition)
        let result = startResults.isEmpty ? .success(()) : startResults.removeFirst()
        return MockGlobalShortcutMonitor(
            startResult: result,
            onStop: { [weak self] in self?.stopCount += 1 }
        )
    }
}

@MainActor
private final class MockGlobalShortcutMonitor: GlobalShortcutMonitoring {
    private let startResult: Result<Void, Error>
    private let onStop: () -> Void

    init(
        startResult: Result<Void, Error>,
        onStop: @escaping () -> Void
    ) {
        self.startResult = startResult
        self.onStop = onStop
    }

    func start() throws {
        try startResult.get()
    }

    func stop() {
        onStop()
    }
}

private enum MockShortcutError: LocalizedError {
    case conflict

    var errorDescription: String? {
        "The shortcut is already in use."
    }
}

private let englishLocalization = AppLocalization(languageIdentifier: "en")

private struct ShortcutDefaultsFixture {
    let suiteName: String
    let defaults: UserDefaults

    func cleanUp() {
        defaults.removePersistentDomain(forName: suiteName)
    }
}

private func makeShortcutDefaults() -> ShortcutDefaultsFixture {
    let suiteName = "GlobalShortcutControllerTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return ShortcutDefaultsFixture(suiteName: suiteName, defaults: defaults)
}
