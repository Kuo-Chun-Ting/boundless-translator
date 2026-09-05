import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_appearance_when_switchingLightDarkLight_then_usesOpaqueWindowBackground() async throws {
    // Arrange
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
        shortcutController: makeTestShortcutController()
    )
    let window = try #require(controller.window)
    let contentView = try #require(window.contentView)

    // Act & Assert
    for name in [NSAppearance.Name.aqua, .darkAqua, .aqua] {
        window.appearance = NSAppearance(named: name)
        await Task.yield()
        contentView.layoutSubtreeIfNeeded()
        let bitmap = try #require(contentView.bitmapImageRepForCachingDisplay(in: contentView.bounds))
        contentView.cacheDisplay(in: contentView.bounds, to: bitmap)
        let contentBackground = try #require(bitmap.colorAt(x: 1, y: 1)?.usingColorSpace(.sRGB))
        window.effectiveAppearance.performAsCurrentDrawingAppearance {
            let actual = window.backgroundColor.usingColorSpace(.sRGB)!
            let expected = NSColor.windowBackgroundColor.usingColorSpace(.sRGB)!
            #expect(actual == expected)
            #expect(actual.alphaComponent == 1)
            #expect(abs(contentBackground.redComponent - expected.redComponent) < 0.02)
            #expect(abs(contentBackground.greenComponent - expected.greenComponent) < 0.02)
            #expect(abs(contentBackground.blueComponent - expected.blueComponent) < 0.02)
        }
    }
}

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
