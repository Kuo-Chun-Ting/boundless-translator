import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_appearance_when_switchingLightDarkLight_then_usesOpaqueWindowBackground() async throws {
    // Arrange
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
        shortcutController: makeTestShortcutController(),
        supportedLanguageCatalog: makeStubLanguageCatalog()
    )
    let window = try #require(controller.window)
    window.colorSpace = .sRGB
    let contentView = try #require(window.contentView)

    // Act & Assert
    for name in [NSAppearance.Name.aqua, .darkAqua, .aqua] {
        window.appearance = NSAppearance(named: name)
        await Task.yield()
        contentView.layoutSubtreeIfNeeded()
        let bitmap = try #require(contentView.bitmapImageRepForCachingDisplay(in: contentView.bounds))
        contentView.cacheDisplay(in: contentView.bounds, to: bitmap)
        #expect(bitmap.colorSpace == .sRGB)
        // colorAt exposes the bitmap's component values as calibrated RGB.
        // They are already sRGB here; converting that wrapper would apply a second transfer curve.
        let contentBackground = try #require(bitmap.colorAt(x: 1, y: 1))
        window.effectiveAppearance.performAsCurrentDrawingAppearance {
            let actual = window.backgroundColor.usingColorSpace(.sRGB)!
            let expected = NSColor.windowBackgroundColor.usingColorSpace(.sRGB)!
            #expect(actual == expected)
            #expect(actual.alphaComponent == 1)
            #expect(contentBackground.alphaComponent == 1)
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
        shortcutController: makeTestShortcutController(),
        supportedLanguageCatalog: makeStubLanguageCatalog()
    )
    let window = try #require(controller.window)

    // Assert
    #expect(window.collectionBehavior.contains(.moveToActiveSpace))
    #expect(!window.styleMask.contains(.nonactivatingPanel))
    #expect(window.canBecomeKey)
    #expect(!window.hidesOnDeactivate)
    #expect(window.title == "Boundless Translator Settings")
    #expect(window.contentLayoutRect.size == PreferencesWindowStyle.contentSize)
}

@Test @MainActor
func test_present_when_pointerScreenChanges_then_centersWindowOnPointerScreen() throws {
    // Arrange
    let screenFrame = try #require(NSScreen.main).visibleFrame
    let stub_visibleFrame = CGRect(
        origin: screenFrame.origin,
        size: CGSize(width: screenFrame.width * 0.8, height: screenFrame.height * 0.85)
    )
    var visibleFrameRequestCount = 0
    let windowPresenter = ForegroundWindowPresenterSpy()
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
        shortcutController: makeTestShortcutController(),
        supportedLanguageCatalog: makeStubLanguageCatalog(),
        pointerScreenVisibleFrame: {
            visibleFrameRequestCount += 1
            return stub_visibleFrame
        },
        windowPresenter: windowPresenter
    )
    let window = try #require(controller.window)
    defer { window.orderOut(nil) }

    // Act
    controller.present()

    // Assert
    #expect(visibleFrameRequestCount == 1)
    #expect(windowPresenter.presentedWindows.last === window)
    #expect(abs(window.frame.midX - stub_visibleFrame.midX) < 1)
    #expect(abs(window.frame.midY - stub_visibleFrame.midY) < 1)
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
        shortcutController: makeTestShortcutController(),
        supportedLanguageCatalog: makeStubLanguageCatalog()
    )
    let window = try #require(controller.window)
    #expect(window.title == "Boundless Translator Settings")

    // Act
    interfaceLanguageSettings.languageIdentifier = "zh-Hant"

    // Assert
    #expect(window.title == "Boundless Translator 設定")
}
