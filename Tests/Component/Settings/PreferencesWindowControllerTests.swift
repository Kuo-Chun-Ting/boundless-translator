import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_init_when_preferencesWindowIsCreated_then_movesWindowToActiveSpace() throws {
    // Arrange & Act
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
        shortcutController: makeTestShortcutController()
    )
    let window = try #require(controller.window)

    // Assert
    #expect(window.collectionBehavior.contains(.moveToActiveSpace))
    #expect(window.title == "Boundless Translator Settings")
    #expect(window.contentLayoutRect.size == PreferencesWindowStyle.contentSize)
    #expect(window.contentLayoutRect.height == 280)
}

@Test @MainActor
func test_present_when_activeScreenChanges_then_centersWindowOnActiveScreen() async throws {
    // Arrange
    let stub_visibleFrame = CGRect(x: 10_000, y: 4_000, width: 1_200, height: 800)
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
        shortcutController: makeTestShortcutController(),
        activeScreenVisibleFrame: { stub_visibleFrame }
    )
    let window = try #require(controller.window)

    // Act
    controller.present()
    await Task.yield()

    // Assert
    #expect(window.frame.midX == stub_visibleFrame.midX)
    #expect(window.frame.midY == stub_visibleFrame.midY)
    window.orderOut(nil)
}

@Test @MainActor
func test_languageIdentifier_when_changed_then_updatesOpenPreferencesWindowTitle() throws {
    // Arrange
    let suiteName = "PreferencesWindowLanguageTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let interfaceLanguageSettings = InterfaceLanguageSettings(
        defaults: defaults,
        preferredLanguageIdentifiers: { ["en"] }
    )
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        interfaceLanguageSettings: interfaceLanguageSettings,
        shortcutController: makeTestShortcutController()
    )
    let window = try #require(controller.window)
    #expect(window.title == "Boundless Translator Settings")

    // Act
    interfaceLanguageSettings.languageIdentifier = "zh-Hant"

    // Assert
    #expect(window.title == "Boundless Translator 設定")
}
