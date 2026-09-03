import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_preferencesView_when_rendered_then_containsInterfaceLanguagePicker() throws {
    // Arrange
    let suiteName = "InterfaceLanguagePreferencesTests.\(UUID().uuidString)"
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
    let contentView = try #require(controller.window?.contentView)

    // Act
    contentView.layoutSubtreeIfNeeded()
    let languagePickers = findViews(in: contentView, ofType: NSPopUpButton.self)
        .filter { $0.title == "System Default — English" }

    // Assert
    #expect(languagePickers.count == 1)
}

@Test @MainActor
func test_preferencesView_when_rendered_then_alignsLanguagePickers() throws {
    // Arrange
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
        shortcutController: makeTestShortcutController()
    )
    let contentView = try #require(controller.window?.contentView)

    // Act
    contentView.layoutSubtreeIfNeeded()
    let trailingEdges = findViews(in: contentView, ofType: NSPopUpButton.self)
        .map { picker in
            picker.convert(picker.bounds, to: contentView).maxX
        }
    let minimumEdge = try #require(trailingEdges.min())
    let maximumEdge = try #require(trailingEdges.max())

    // Assert
    #expect(trailingEdges.count == 3)
    #expect(maximumEdge - minimumEdge < 1)
}

@Test @MainActor
func test_preferencesView_when_rendered_then_placesUsageAfterLanguage() throws {
    // Arrange
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
        shortcutController: makeTestShortcutController()
    )
    let contentView = try #require(controller.window?.contentView)

    // Act
    contentView.layoutSubtreeIfNeeded()
    let languagePicker = try #require(
        findViews(in: contentView, ofType: NSPopUpButton.self)
            .first { $0.title == "System Default — English" }
    )
    let usageButton = try #require(
        findViews(
            in: contentView,
            accessibilityIdentifier: "usageHelpButton"
        ).first
    )
    let languageY = languagePicker.convert(
        languagePicker.bounds,
        to: contentView
    ).midY
    let usageY = usageButton.convert(usageButton.bounds, to: contentView).midY

    // Assert
    #expect(contentView.isFlipped ? languageY < usageY : languageY > usageY)
}

@Test @MainActor
func test_preferencesView_when_rendered_then_placesQuitLeftOfUsageHelp() throws {
    // Arrange
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
        shortcutController: makeTestShortcutController()
    )
    let contentView = try #require(controller.window?.contentView)

    // Act
    contentView.layoutSubtreeIfNeeded()
    let quitButton = try #require(
        findViews(
            in: contentView,
            accessibilityIdentifier: "quitButton"
        ).first
    )
    let usageButton = try #require(
        findViews(
            in: contentView,
            accessibilityIdentifier: "usageHelpButton"
        ).first
    )
    let quitFrame = quitButton.convert(quitButton.bounds, to: contentView)
    let usageFrame = usageButton.convert(usageButton.bounds, to: contentView)

    // Assert
    #expect(abs(quitFrame.midY - usageFrame.midY) < 1)
    #expect(quitFrame.maxX < usageFrame.minX)
}

@Test @MainActor
func test_preferencesView_when_rendered_then_all_settings_fit_without_scrolling() throws {
    // Arrange
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
        shortcutController: makeTestShortcutController()
    )
    let contentView = try #require(controller.window?.contentView)

    // Act
    contentView.layoutSubtreeIfNeeded()
    let formScrollView = try #require(
        findViews(in: contentView, ofType: NSScrollView.self)
            .max { lhs, rhs in
                (lhs.documentView?.bounds.height ?? 0)
                    < (rhs.documentView?.bounds.height ?? 0)
            }
    )
    let documentHeight = try #require(formScrollView.documentView?.bounds.height)

    // Assert
    #expect(documentHeight <= formScrollView.contentView.bounds.height + 1)
}

@Test @MainActor
func test_preferencesView_when_shortcutRegistrationFails_then_errorAndFooterDoNotOverlap() throws {
    // Arrange
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
        shortcutController: makeFailingTestShortcutController()
    )
    let contentView = try #require(controller.window?.contentView)

    // Act
    contentView.layoutSubtreeIfNeeded()
    let languagePicker = try #require(
        findViews(in: contentView, ofType: NSPopUpButton.self)
            .first { $0.title == "System Default — English" }
    )
    let quitButton = try #require(
        findViews(
            in: contentView,
            accessibilityIdentifier: "quitButton"
        ).first
    )
    let languageFrame = languagePicker.convert(
        languagePicker.bounds,
        to: contentView
    )
    let quitFrame = quitButton.convert(quitButton.bounds, to: contentView)
    let verticalGap = abs(languageFrame.midY - quitFrame.midY)
        - ((languageFrame.height + quitFrame.height) / 2)

    // Assert
    #expect(verticalGap >= 8)
}

@Test @MainActor
func test_languageIdentifier_when_changed_then_updatesOpenPreferencesContent() async throws {
    // Arrange
    let suiteName = "PreferencesContentLanguageTests.\(UUID().uuidString)"
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
    let contentView = try #require(controller.window?.contentView)
    contentView.layoutSubtreeIfNeeded()

    // Act
    interfaceLanguageSettings.languageIdentifier = "zh-Hant"
    await Task.yield()
    contentView.layoutSubtreeIfNeeded()
    let quitButton = try #require(
        findViews(
            in: contentView,
            accessibilityIdentifier: "quitButton"
        ).compactMap { $0 as? NSButton }.first
    )

    // Assert
    #expect(quitButton.title == "結束 Boundless Translator")
}

@MainActor
private func findViews<View: NSView>(
    in view: NSView,
    ofType type: View.Type
) -> [View] {
    let current = (view as? View).map { [$0] } ?? []
    return current + view.subviews.flatMap {
        findViews(in: $0, ofType: type)
    }
}

@Test @MainActor
func test_preferencesView_when_rendered_then_containsCurrentShortcutRecorder() throws {
    // Arrange
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
        shortcutController: makeTestShortcutController()
    )
    let contentView = try #require(controller.window?.contentView)

    // Act
    contentView.layoutSubtreeIfNeeded()
    let recorders = findViews(
            in: contentView,
            accessibilityIdentifier: "shortcutRecorder"
        ).compactMap { $0 as? NSButton }
    let recorder = try #require(recorders.first)

    // Assert
    #expect(recorders.count == 1)
    #expect(recorder.title == "⇧⌘T")
}

@Test @MainActor
func test_quitButton_when_clicked_then_requests_application_termination() throws {
    // Arrange
    let terminationSpy = TerminationSpy()
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
        shortcutController: makeTestShortcutController(),
        quitApplication: {
            terminationSpy.request()
        }
    )
    let contentView = try #require(controller.window?.contentView)
    contentView.layoutSubtreeIfNeeded()
    let quitButton = try #require(
        findViews(
            in: contentView,
            accessibilityIdentifier: "quitButton"
        ).compactMap { $0 as? NSButton }.first
    )

    // Act
    quitButton.performClick(nil)

    // Assert
    #expect(quitButton.title == "Quit Boundless Translator")
    #expect(terminationSpy.didRequestTermination)
}

@MainActor
private final class TerminationSpy {
    private(set) var didRequestTermination = false

    func request() {
        didRequestTermination = true
    }
}

@MainActor
private func findViews(
    in view: NSView,
    accessibilityIdentifier: String
) -> [NSView] {
    let current = view.accessibilityIdentifier() == accessibilityIdentifier
        ? [view]
        : []
    return current + view.subviews.flatMap {
        findViews(in: $0, accessibilityIdentifier: accessibilityIdentifier)
    }
}
