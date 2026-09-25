import AppKit
import Testing
@testable import BoundlessTranslator

@Test(arguments: InterfaceLanguageCatalog.languageIdentifiers, [
    (subscription: false, overrideLanguage: false),
    (subscription: true, overrideLanguage: false),
    (subscription: false, overrideLanguage: true),
    (subscription: true, overrideLanguage: true),
]) @MainActor
func test_preferencesView_when_localized_then_footerActionsFitOnOneRow(
    languageIdentifier: String,
    configuration: (subscription: Bool, overrideLanguage: Bool)
) throws {
    // Arrange
    let suite = "PreferencesLayout.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let language = InterfaceLanguageSettings(
        defaults: defaults, preferredLanguageIdentifiers: { [languageIdentifier] }
    )
    if configuration.overrideLanguage {
        language.languageIdentifier = languageIdentifier
    }
    var subscriptionAction: (@MainActor () -> Void)?
    if configuration.subscription {
        subscriptionAction = {}
    }
    let controller = PreferencesWindowController(
        settings: TranslationSettings(defaults: defaults),
        interfaceLanguageSettings: language,
        translationShortcutController: makeTestTranslationShortcutController(),
        supportedLanguageCatalog: makeStubLanguageCatalog(),
        onShowSubscription: subscriptionAction
    )
    let content = try #require(controller.window?.contentView)

    // Act
    content.layoutSubtreeIfNeeded()
    let quit = try #require(findViews(in: content, accessibilityIdentifier: "quitButton").first as? NSButton)
    let help = try #require(findViews(in: content, accessibilityIdentifier: "usageHelpButton").first as? NSButton)
    let subscriptions = findViews(in: content, accessibilityIdentifier: "subscriptionButton").compactMap { $0 as? NSButton }
    let quitFrame = quit.convert(quit.bounds, to: content)
    let helpFrame = help.convert(help.bounds, to: content)
    let scroll = try #require(findViews(in: content, ofType: NSScrollView.self).max {
        ($0.documentView?.bounds.height ?? 0) < ($1.documentView?.bounds.height ?? 0)
    })
    let documentHeight = try #require(scroll.documentView?.bounds.height)

    // Assert
    #expect(subscriptions.count == (configuration.subscription ? 1 : 0))
    #expect(documentHeight <= scroll.contentView.bounds.height + 1)
    #expect(abs(quitFrame.midY - helpFrame.midY) < 3)
    #expect(abs(language.isRightToLeft ? quitFrame.maxX - content.bounds.maxX : quitFrame.minX - content.bounds.minX) < 25)
    #expect(abs(language.isRightToLeft ? helpFrame.minX - content.bounds.minX : helpFrame.maxX - content.bounds.maxX) < 25)
    for button in [quit, help] + subscriptions {
        let frame = button.convert(button.bounds, to: content)
        #expect(content.bounds.contains(frame))
        #expect(button.bounds.width >= button.fittingSize.width - 1)
    }
    if let subscription = subscriptions.first {
        let frame = subscription.convert(subscription.bounds, to: content)
        #expect(!frame.intersects(helpFrame))
        #expect(!frame.intersects(quitFrame))
        #expect(abs(frame.midY - helpFrame.midY) < 3)
        #expect(language.isRightToLeft ? frame.minX > helpFrame.maxX : frame.maxX < helpFrame.minX)
    }
    for picker in findViews(in: content, ofType: NSPopUpButton.self) {
        let textWidth = (picker.title as NSString).size(withAttributes: [.font: picker.font ?? NSFont.systemFont(ofSize: 13)]).width
        let titleRect = try #require(picker.cell?.titleRect(forBounds: picker.bounds))
        #expect(titleRect.width >= textWidth - 0.5)
    }
}

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
        translationShortcutController: makeTestTranslationShortcutController(),
        supportedLanguageCatalog: makeStubLanguageCatalog()
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
func test_languageIdentifier_when_longLanguageSelected_then_openWindowResizesWithoutClipping() async throws {
    // Arrange
    let language = makeTestInterfaceLanguageSettings()
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        interfaceLanguageSettings: language,
        translationShortcutController: makeTestTranslationShortcutController(),
        supportedLanguageCatalog: makeStubLanguageCatalog()
    )
    let window = try #require(controller.window)
    let content = try #require(window.contentView)
    window.orderFront(nil)
    defer { window.orderOut(nil) }
    content.layoutSubtreeIfNeeded()
    let originalWidth = window.contentLayoutRect.width

    // Act
    language.languageIdentifier = "en-ZA"
    for _ in 0..<50 {
        if findViews(in: content, ofType: NSPopUpButton.self).contains(where: { $0.title.contains("South Africa") }) {
            break
        }
        try await Task.sleep(for: .milliseconds(10))
        content.layoutSubtreeIfNeeded()
    }
    content.layoutSubtreeIfNeeded()
    let picker = try #require(findViews(in: content, ofType: NSPopUpButton.self).first {
        $0.title.contains("South Africa")
    })
    let textWidth = (picker.title as NSString).size(withAttributes: [.font: picker.font ?? NSFont.systemFont(ofSize: 13)]).width

    // Assert
    #expect(window.contentLayoutRect.width > originalWidth)
    let titleRect = try #require(picker.cell?.titleRect(forBounds: picker.bounds))
    #expect(titleRect.width >= textWidth - 0.5)
    #expect(content.bounds.contains(picker.convert(picker.bounds, to: content)))

    // Act
    language.languageIdentifier = "zh-Hant"
    await Task.yield()
    content.layoutSubtreeIfNeeded()

    // Assert
    #expect(window.contentLayoutRect.width == originalWidth)
}

@Test @MainActor
func test_preferencesView_when_rendered_then_alignsLanguagePickers() throws {
    // Arrange
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
        translationShortcutController: makeTestTranslationShortcutController(),
        supportedLanguageCatalog: makeStubLanguageCatalog()
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
        translationShortcutController: makeTestTranslationShortcutController(),
        supportedLanguageCatalog: makeStubLanguageCatalog()
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
func test_preferencesView_when_rendered_then_placesQuitOppositeUsageHelp() throws {
    // Arrange
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
        translationShortcutController: makeTestTranslationShortcutController(),
        supportedLanguageCatalog: makeStubLanguageCatalog()
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
    #expect(abs(quitFrame.midY - usageFrame.midY) < 3)
    #expect(quitFrame.maxX < usageFrame.minX)
}

@Test @MainActor
func test_preferencesView_when_rendered_then_all_settings_fit_without_scrolling() throws {
    // Arrange
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
        translationShortcutController: makeTestTranslationShortcutController(),
        supportedLanguageCatalog: makeStubLanguageCatalog()
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
        translationShortcutController: makeFailingTestTranslationShortcutController(),
        supportedLanguageCatalog: makeStubLanguageCatalog()
    )
    let contentView = try #require(controller.window?.contentView)

    // Act
    contentView.layoutSubtreeIfNeeded()
    let scrollView = try #require(findViews(in: contentView, ofType: NSScrollView.self).max {
        ($0.documentView?.bounds.height ?? 0) < ($1.documentView?.bounds.height ?? 0)
    })
    let quitButton = try #require(
        findViews(
            in: contentView,
            accessibilityIdentifier: "quitButton"
        ).first
    )
    let visibleFormFrame = scrollView.convert(scrollView.contentView.bounds, to: contentView)
    let quitFrame = quitButton.convert(quitButton.bounds, to: contentView)

    // Assert
    #expect((scrollView.documentView?.bounds.height ?? 0) > scrollView.contentView.bounds.height)
    #expect(!visibleFormFrame.intersects(quitFrame))
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
        translationShortcutController: makeTestTranslationShortcutController(),
        supportedLanguageCatalog: makeStubLanguageCatalog()
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
    #expect(quitButton.title == "結束")
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
        translationShortcutController: makeTestTranslationShortcutController(),
        screenshotShortcutController: makeTestScreenshotShortcutController(),
        supportedLanguageCatalog: makeStubLanguageCatalog()
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
    #expect(recorder.title == "⇧⌘1")
    let screenshotRecorders = findViews(
        in: contentView, accessibilityIdentifier: "screenshotShortcutRecorder"
    ).compactMap { $0 as? NSButton }
    #expect(screenshotRecorders.count == 1)
    #expect(screenshotRecorders.first?.title == "⇧⌘2")
}

@Test @MainActor
func test_preferencesView_when_rendered_then_labelsShortcutFunctions() throws {
    // Arrange
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
        translationShortcutController: makeTestTranslationShortcutController(),
        screenshotShortcutController: makeTestScreenshotShortcutController(),
        supportedLanguageCatalog: makeStubLanguageCatalog()
    )
    let contentView = try #require(controller.window?.contentView)

    // Act
    contentView.layoutSubtreeIfNeeded()
    let translationRecorder = try #require(
        findViews(in: contentView, accessibilityIdentifier: "shortcutRecorder")
            .compactMap { $0 as? NSButton }
            .first
    )
    let screenshotRecorder = try #require(
        findViews(
            in: contentView,
            accessibilityIdentifier: "screenshotShortcutRecorder"
        )
        .compactMap { $0 as? NSButton }
        .first
    )

    // Assert
    #expect(translationRecorder.accessibilityLabel() == "Selected Text Translation")
    #expect(screenshotRecorder.accessibilityLabel() == "Screenshot Translation")
}

@Test @MainActor
func test_quitButton_when_clicked_then_requests_application_termination() throws {
    // Arrange
    let terminationSpy = TerminationSpy()
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
        translationShortcutController: makeTestTranslationShortcutController(),
        supportedLanguageCatalog: makeStubLanguageCatalog(),
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
    let action = try #require(quitButton.action)
    #expect(NSApplication.shared.sendAction(action, to: quitButton.target, from: quitButton))

    // Assert
    #expect(quitButton.title == "Quit")
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
