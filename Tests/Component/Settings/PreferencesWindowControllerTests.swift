import AppKit
import SwiftUI
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_presentForLanguageSetup_when_requested_again_then_retriggers_reminder_only_for_setup() throws {
    // Arrange
    let suite = "LanguageSetupReminderTests.\(UUID())"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let presenter = ForegroundWindowPresenterSpy()
    let controller = PreferencesWindowController(
        settings: TranslationSettings(defaults: defaults),
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
        translationShortcutController: makeTestTranslationShortcutController(),
        supportedLanguageCatalog: makeStubLanguageCatalog(),
        windowPresenter: presenter
    )
    defer { controller.close() }
    let window = try #require(controller.window)
    let host = try #require(window.contentView as? NSHostingView<PreferencesView>)

    // Act & Assert
    controller.present()
    #expect(host.rootView.languageSetupReminderCount == 0)
    controller.presentForLanguageSetup()
    #expect(presenter.presentedWindows.last === window)
    #expect(host.rootView.languageSetupReminderCount == 1)
    controller.present()
    #expect(host.rootView.languageSetupReminderCount == 1)
    controller.presentForLanguageSetup()
    #expect(host.rootView.languageSetupReminderCount == 2)
}

@Test @MainActor
func test_appearance_when_switchingLightDarkLight_then_usesOpaqueWindowBackground() async throws {
    // Arrange
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
        translationShortcutController: makeTestTranslationShortcutController(),
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
        translationShortcutController: makeTestTranslationShortcutController(),
        supportedLanguageCatalog: makeStubLanguageCatalog()
    )
    let window = try #require(controller.window)

    // Assert
    #expect(window.collectionBehavior.contains(.moveToActiveSpace))
    #expect(!window.styleMask.contains(.nonactivatingPanel))
    #expect(window.canBecomeKey)
    #expect(!window.hidesOnDeactivate)
    #expect(window.title == "Boundless Translator")
    #expect(window.titleVisibility == .hidden)
    #expect(window.titlebarAccessoryViewControllers.count == 1)
    #expect(window.contentLayoutRect.size == PreferencesWindowStyle.contentSize)
}

@Test @MainActor
func test_present_when_pointerScreenFrameIsProvided_then_centersWindowInThatFrame() throws {
    // Arrange
    let visibleFrame = CGRect(x: 100, y: 100, width: 1_200, height: 800)
    var visibleFrameRequestCount = 0
    let windowPresenter = ForegroundWindowPresenterSpy()
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
        translationShortcutController: makeTestTranslationShortcutController(),
        supportedLanguageCatalog: makeStubLanguageCatalog(),
        pointerScreenVisibleFrame: {
            visibleFrameRequestCount += 1
            return visibleFrame
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
    let frameBeforePresentation = try #require(
        windowPresenter.framesBeforePresentation.last
    )
    #expect(abs(frameBeforePresentation.midX - visibleFrame.midX) < 1)
    #expect(abs(frameBeforePresentation.midY - visibleFrame.midY) < 1)
}

@Test @MainActor
func test_languageIdentifier_when_changed_then_preservesPreferencesBrandTitle() throws {
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
        translationShortcutController: makeTestTranslationShortcutController(),
        supportedLanguageCatalog: makeStubLanguageCatalog()
    )
    let window = try #require(controller.window)
    #expect(window.title == "Boundless Translator")

    // Act
    interfaceLanguageSettings.languageIdentifier = "zh-Hant"

    // Assert
    #expect(window.title == "Boundless Translator")
}

@Test @MainActor
func test_present_when_languages_are_incomplete_then_hint_stays_until_both_are_selected() async throws {
    // Arrange
    let suite = "RequiredLanguageHintTests.\(UUID())"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let settings = TranslationSettings(defaults: defaults)
    let controller = PreferencesWindowController(
        settings: settings,
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
        translationShortcutController: makeTestTranslationShortcutController(),
        supportedLanguageCatalog: makeStubLanguageCatalog(),
        windowPresenter: ForegroundWindowPresenterSpy()
    )
    let window = try #require(controller.window)
    defer { controller.close() }

    // Act
    controller.present()
    try await waitForLanguageSetupHint(in: window, visible: true)
    settings.sourceLanguageIdentifier = nil // Auto-detect is a valid explicit choice.
    try await waitForLanguageSetupHint(in: window, visible: true)
    settings.targetLanguageIdentifier = "ja"

    // Assert
    try await waitForLanguageSetupHint(in: window, visible: false)
    settings.targetLanguageIdentifier = ""
    try await waitForLanguageSetupHint(in: window, visible: true)
    controller.close()
    #expect(window.childWindows?.contains { $0.identifier?.rawValue == "languageSetupHint" } != true)
}

@MainActor
private func waitForLanguageSetupHint(in window: NSWindow, visible: Bool) async throws {
    let deadline = ContinuousClock.now.advanced(by: .seconds(2))
    while (window.childWindows?.contains {
        $0.identifier?.rawValue == "languageSetupHint" && $0.isVisible
    } == true) != visible {
        guard ContinuousClock.now < deadline else {
            Issue.record("Language setup hint expected visible=\(visible), parent visible=\(window.isVisible), children=\(window.childWindows?.map { ($0.identifier?.rawValue ?? "", $0.isVisible) } ?? [])")
            return
        }
        try await Task.sleep(for: .milliseconds(10))
    }
}

@Test @MainActor
func test_languageSetupHint_when_parent_is_at_screen_edge_then_stays_on_right() throws {
    // Arrange
    let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 400, height: 300),
                          styleMask: [.borderless], backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    defer { window.close() }
    let anchor = NSView(frame: CGRect(x: 20, y: 200, width: 300, height: 40))
    window.contentView!.addSubview(anchor)
    let controller = LanguageSetupHintController()
    defer { controller.close() }
    let screen = try #require(NSScreen.main)
    window.setFrameOrigin(CGPoint(x: screen.visibleFrame.maxX - 100, y: screen.visibleFrame.minY))

    // Act
    controller.setAnchor(anchor)
    controller.present(in: window, localization: AppLocalization(languageIdentifier: "en"))

    // Assert
    let panel = try #require(window.childWindows?.first)
    #expect(abs(panel.frame.minX - window.frame.maxX - 8) < 1)
    let anchorFrame = window.convertToScreen(anchor.convert(anchor.bounds, to: nil))
    #expect(abs(panel.frame.minY - (anchorFrame.maxY - 28)) < 1)
}
