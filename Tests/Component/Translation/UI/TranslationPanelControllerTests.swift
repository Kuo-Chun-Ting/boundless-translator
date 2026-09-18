import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_windowDidResignKey_when_translationTemporarilyLosesFocus_then_keepsWindowVisible() throws {
    // Arrange
    let fixture = try makeTranslationWindowFixture()

    // Act
    fixture.window.delegate?.windowDidResignKey?(
        Notification(
            name: NSWindow.didResignKeyNotification,
            object: fixture.window
        )
    )

    // Assert
    #expect(fixture.window.isVisible)
    fixture.window.orderOut(nil)
}

@Test @MainActor
func test_show_whenTranslationIsPresented_then_requestsForegroundWindowPresentation() throws {
    // Arrange & Act
    let fixture = try makeTranslationWindowFixture()

    // Assert
    #expect(fixture.windowPresenter.presentedWindows.last === fixture.window)
    fixture.window.orderOut(nil)
}

@Test @MainActor
func test_show_whenTranslationIsPresented_then_preservesOwnedWindowConfiguration() throws {
    // Arrange & Act
    let fixture = try makeTranslationWindowFixture()

    // Assert
    #expect(fixture.window.level == .floating)
    #expect(fixture.window.collectionBehavior.contains(.canJoinAllSpaces))
    #expect(fixture.window.collectionBehavior.contains(.fullScreenAuxiliary))
    #expect(!fixture.window.hidesOnDeactivate)
    #expect(!fixture.window.isReleasedWhenClosed)
    fixture.window.orderOut(nil)
}

@Test @MainActor
func test_dismissForApplicationActivation_when_externalAppActivatesAndTranslationIsUnpinned_then_closesWindow() throws {
    // Arrange
    let fixture = try makeTranslationWindowFixture()
    let externalProcessIdentifier = ProcessInfo.processInfo.processIdentifier + 1

    // Act
    fixture.controller.dismissForApplicationActivation(
        processIdentifier: externalProcessIdentifier
    )

    // Assert
    #expect(!fixture.window.isVisible)
}

@Test @MainActor
func test_dismissForApplicationActivation_when_externalAppActivatesAndTranslationIsPinned_then_keepsWindowVisible() throws {
    // Arrange
    let fixture = try makeTranslationWindowFixture()
    try pinWindow(fixture.window)
    let externalProcessIdentifier = ProcessInfo.processInfo.processIdentifier + 1

    // Act
    fixture.controller.dismissForApplicationActivation(
        processIdentifier: externalProcessIdentifier
    )

    // Assert
    #expect(fixture.window.isVisible)
    fixture.window.orderOut(nil)
}

@Test @MainActor
func test_dismissForApplicationActivation_when_boundlessTranslatorActivates_then_keepsUnpinnedWindowVisible() throws {
    // Arrange
    let fixture = try makeTranslationWindowFixture()

    // Act
    fixture.controller.dismissForApplicationActivation(
        processIdentifier: ProcessInfo.processInfo.processIdentifier
    )

    // Assert
    #expect(fixture.window.isVisible)
    fixture.window.orderOut(nil)
}

@Test @MainActor
func test_dismissForMouseDown_when_pointIsInsideWindow_then_keepsWindowVisible() throws {
    // Arrange
    let fixture = try makeTranslationWindowFixture()
    let pointInsideWindow = CGPoint(
        x: fixture.window.frame.midX,
        y: fixture.window.frame.midY
    )

    // Act
    fixture.controller.dismissForMouseDown(at: pointInsideWindow)

    // Assert
    #expect(fixture.window.isVisible)
    fixture.window.orderOut(nil)
}

@Test @MainActor
func test_dismissForMouseDown_when_pointIsOutsideWindow_then_closesUnpinnedWindow() throws {
    // Arrange
    let fixture = try makeTranslationWindowFixture()
    let pointOutsideWindow = CGPoint(
        x: fixture.window.frame.maxX + 100,
        y: fixture.window.frame.maxY + 100
    )

    // Act
    fixture.controller.dismissForMouseDown(at: pointOutsideWindow)

    // Assert
    #expect(!fixture.window.isVisible)
}

@Test @MainActor
func test_dismissForMouseDown_when_translationCloses_then_stopsSpeech() throws {
    // Arrange
    let speechPlayer = WindowControllerSpeechPlayerMock()
    let fixture = try makeTranslationWindowFixture(speechPlayer: speechPlayer)
    let stopCountAfterPresentation = speechPlayer.stopCallCount
    let pointOutsideWindow = CGPoint(
        x: fixture.window.frame.maxX + 100,
        y: fixture.window.frame.maxY + 100
    )

    // Act
    fixture.controller.dismissForMouseDown(at: pointOutsideWindow)

    // Assert
    #expect(speechPlayer.stopCallCount == stopCountAfterPresentation + 1)
}

@Test @MainActor
func test_dismissForMouseDown_when_pointIsOutsideWindowAndTranslationIsPinned_then_keepsWindowVisible() throws {
    // Arrange
    let fixture = try makeTranslationWindowFixture()
    try pinWindow(fixture.window)
    let pointOutsideWindow = CGPoint(
        x: fixture.window.frame.maxX + 100,
        y: fixture.window.frame.maxY + 100
    )

    // Act
    fixture.controller.dismissForMouseDown(at: pointOutsideWindow)

    // Assert
    #expect(fixture.window.isVisible)
    fixture.window.orderOut(nil)
}

@Test @MainActor
func test_cancelOperation_when_translationIsUnpinned_then_closesWindow() throws {
    // Arrange
    let fixture = try makeTranslationWindowFixture()

    // Act
    fixture.window.cancelOperation(nil)

    // Assert
    #expect(!fixture.window.isVisible)
}

@Test @MainActor
func test_cancelOperation_when_translationIsPinned_then_keepsWindowVisible() throws {
    // Arrange
    let fixture = try makeTranslationWindowFixture()
    try pinWindow(fixture.window)

    // Act
    fixture.window.cancelOperation(nil)

    // Assert
    #expect(fixture.window.isVisible)
    fixture.window.orderOut(nil)
}

@Test @MainActor
func test_show_when_fifthLineLookupActionOverlapsSourceText_then_buttonOwnsHitTest() throws {
    // Arrange
    let sourceText = [
        "First line",
        "Second line",
        "Third line",
        "Fourth line",
        "Fifth line",
    ].joined(separator: "\n")
    let fixture = try makeTranslationWindowFixture(sourceText: sourceText)
    let contentView = try #require(fixture.window.contentView)
    contentView.layoutSubtreeIfNeeded()
    let sourceView = try #require(
        firstSubview(of: SourceTextLookupView.self, in: contentView)
    )
    sourceView.updateSelection(NSRange(location: 46, length: 10))
    sourceView.layoutSubtreeIfNeeded()
    let lookupButton = try #require(
        contentView.subviews.compactMap { $0 as? PointingHandButton }.first
    )
    let buttonCenter = NSPoint(
        x: lookupButton.frame.midX,
        y: lookupButton.frame.midY
    )

    // Act
    let hitView = contentView.hitTest(buttonCenter)

    // Assert
    #expect(hitView === lookupButton)
    fixture.window.orderOut(nil)
}

@Test @MainActor
func test_sendEvent_when_hoveringFifthLineLookupAction_then_usesPointingHandCursor() throws {
    // Arrange
    let sourceText = [
        "First line",
        "Second line",
        "Third line",
        "Fourth line",
        "Fifth line",
    ].joined(separator: "\n")
    let fixture = try makeTranslationWindowFixture(sourceText: sourceText)
    let contentView = try #require(fixture.window.contentView)
    contentView.layoutSubtreeIfNeeded()
    let sourceView = try #require(
        firstSubview(of: SourceTextLookupView.self, in: contentView)
    )
    sourceView.updateSelection(NSRange(location: 46, length: 10))
    sourceView.layoutSubtreeIfNeeded()
    let lookupButton = try #require(
        contentView.subviews.compactMap { $0 as? PointingHandButton }.first
    )
    let event = try #require(
        NSEvent.mouseEvent(
            with: .mouseMoved,
            location: NSPoint(
                x: lookupButton.frame.midX,
                y: lookupButton.frame.midY
            ),
            modifierFlags: [],
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: fixture.window.windowNumber,
            context: nil,
            eventNumber: 0,
            clickCount: 0,
            pressure: 0
        )
    )
    NSCursor.arrow.set()

    // Act
    fixture.window.sendEvent(event)

    // Assert
    #expect(NSCursor.current === NSCursor.pointingHand)
    fixture.window.orderOut(nil)
}

@Test @MainActor
func test_languageIdentifier_when_changed_then_updatesOpenTranslationWindowToolbar() throws {
    // Arrange
    let suiteName = "TranslationWindowLanguageTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let interfaceLanguageSettings = InterfaceLanguageSettings(
        defaults: defaults,
        preferredLanguageIdentifiers: { ["en"] }
    )
    let fixture = try makeTranslationWindowFixture(
        interfaceLanguageSettings: interfaceLanguageSettings
    )
    let pinButton = try #require(
        fixture.window.toolbar?.items.first {
            $0.itemIdentifier == .pinWindow
        }?.view as? NSButton
    )
    #expect(pinButton.toolTip == "Pin Window")

    // Act
    interfaceLanguageSettings.languageIdentifier = "zh-Hant"

    // Assert
    #expect(pinButton.toolTip == "釘選視窗")
    fixture.window.orderOut(nil)
}

private struct TranslationWindowTestFixture {
    let application: NSApplication
    let applicationNotificationCenter: NotificationCenter
    let controller: TranslationWindowController
    let window: TranslationWindow
    let windowPresenter: ForegroundWindowPresenterSpy
}

@MainActor
private func pinWindow(_ window: TranslationWindow) throws {
    let pinButton = try #require(
        window.toolbar?.items.first {
            $0.itemIdentifier == .pinWindow
        }?.view as? NSButton
    )
    let action = try #require(pinButton.action)
    #expect(NSApplication.shared.sendAction(action, to: pinButton.target, from: pinButton))
}

@MainActor
private func makeTranslationWindowFixture(
    sourceText: String = "Hello",
    speechPlayer: any SpeechPlaying = WindowControllerSpeechPlayerMock(),
    interfaceLanguageSettings: InterfaceLanguageSettings? = nil
) throws -> TranslationWindowTestFixture {
    let application = NSApplication.shared
    let applicationNotificationCenter = NotificationCenter()
    let existingWindows = Set(
        application.windows.compactMap { window in
            (window as? TranslationWindow).map(ObjectIdentifier.init)
        }
    )
    let coordinator = TranslationCoordinator()
    let windowPresenter = ForegroundWindowPresenterSpy()
    coordinator.submit(
        try SelectedText(sourceText),
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "zh-Hant"
    )
    let controller = TranslationWindowController(
        applicationNotificationCenter: applicationNotificationCenter,
        speechPlayer: speechPlayer,
        interfaceLanguageSettings: interfaceLanguageSettings
            ?? makeTestInterfaceLanguageSettings(),
        engine: makeStubTranslationEngine(),
        windowPresenter: windowPresenter
    )
    controller.show(
        coordinator: coordinator,
        supportedLanguages: [
            Locale.Language(identifier: "en"),
            Locale.Language(identifier: "zh-Hant"),
        ],
        pointerLocation: .zero
    )
    let window = try #require(
        application.windows.compactMap { $0 as? TranslationWindow }.first {
            !existingWindows.contains(ObjectIdentifier($0))
        }
    )
    return TranslationWindowTestFixture(
        application: application,
        applicationNotificationCenter: applicationNotificationCenter,
        controller: controller,
        window: window,
        windowPresenter: windowPresenter
    )
}

@MainActor
private final class WindowControllerSpeechPlayerMock: SpeechPlaying {
    private(set) var stopCallCount = 0

    func supports(languageIdentifier: String) -> Bool {
        true
    }

    func play(
        text: String,
        languageIdentifier: String,
        completion: @escaping @MainActor () -> Void
    ) {}

    func stop() {
        stopCallCount += 1
    }
}

@MainActor
private func firstSubview<View: NSView>(
    of type: View.Type,
    in rootView: NSView
) -> View? {
    if let match = rootView as? View {
        return match
    }
    for subview in rootView.subviews {
        if let match = firstSubview(of: type, in: subview) {
            return match
        }
    }
    return nil
}
