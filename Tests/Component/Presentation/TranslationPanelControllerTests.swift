import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_windowDidResignKey_when_translationTemporarilyLosesFocus_then_keepsPanelVisible() throws {
    // Arrange
    let fixture = try makeTranslationPanelFixture()

    // Act
    fixture.panel.delegate?.windowDidResignKey?(
        Notification(
            name: NSWindow.didResignKeyNotification,
            object: fixture.panel
        )
    )

    // Assert
    #expect(fixture.panel.isVisible)
    fixture.panel.orderOut(nil)
}

@Test @MainActor
func test_dismissForApplicationActivation_when_externalAppActivatesAndTranslationIsUnpinned_then_closesPanel() throws {
    // Arrange
    let fixture = try makeTranslationPanelFixture()
    let externalProcessIdentifier = ProcessInfo.processInfo.processIdentifier + 1

    // Act
    fixture.controller.dismissForApplicationActivation(
        processIdentifier: externalProcessIdentifier
    )

    // Assert
    #expect(!fixture.panel.isVisible)
}

@Test @MainActor
func test_dismissForApplicationActivation_when_externalAppActivatesAndTranslationIsPinned_then_keepsPanelVisible() throws {
    // Arrange
    let fixture = try makeTranslationPanelFixture()
    try pinPanel(fixture.panel)
    let externalProcessIdentifier = ProcessInfo.processInfo.processIdentifier + 1

    // Act
    fixture.controller.dismissForApplicationActivation(
        processIdentifier: externalProcessIdentifier
    )

    // Assert
    #expect(fixture.panel.isVisible)
    fixture.panel.orderOut(nil)
}

@Test @MainActor
func test_dismissForApplicationActivation_when_boundlessTranslatorActivates_then_keepsUnpinnedPanelVisible() throws {
    // Arrange
    let fixture = try makeTranslationPanelFixture()

    // Act
    fixture.controller.dismissForApplicationActivation(
        processIdentifier: ProcessInfo.processInfo.processIdentifier
    )

    // Assert
    #expect(fixture.panel.isVisible)
    fixture.panel.orderOut(nil)
}

@Test @MainActor
func test_dismissForMouseDown_when_pointIsInsidePanel_then_keepsPanelVisible() throws {
    // Arrange
    let fixture = try makeTranslationPanelFixture()
    let pointInsidePanel = CGPoint(
        x: fixture.panel.frame.midX,
        y: fixture.panel.frame.midY
    )

    // Act
    fixture.controller.dismissForMouseDown(at: pointInsidePanel)

    // Assert
    #expect(fixture.panel.isVisible)
    fixture.panel.orderOut(nil)
}

@Test @MainActor
func test_dismissForMouseDown_when_pointIsOutsidePanel_then_closesUnpinnedPanel() throws {
    // Arrange
    let fixture = try makeTranslationPanelFixture()
    let pointOutsidePanel = CGPoint(
        x: fixture.panel.frame.maxX + 100,
        y: fixture.panel.frame.maxY + 100
    )

    // Act
    fixture.controller.dismissForMouseDown(at: pointOutsidePanel)

    // Assert
    #expect(!fixture.panel.isVisible)
}

@Test @MainActor
func test_dismissForMouseDown_when_pointIsOutsidePanelAndTranslationIsPinned_then_keepsPanelVisible() throws {
    // Arrange
    let fixture = try makeTranslationPanelFixture()
    try pinPanel(fixture.panel)
    let pointOutsidePanel = CGPoint(
        x: fixture.panel.frame.maxX + 100,
        y: fixture.panel.frame.maxY + 100
    )

    // Act
    fixture.controller.dismissForMouseDown(at: pointOutsidePanel)

    // Assert
    #expect(fixture.panel.isVisible)
    fixture.panel.orderOut(nil)
}

@Test @MainActor
func test_cancelOperation_when_translationIsUnpinned_then_closesPanel() throws {
    // Arrange
    let fixture = try makeTranslationPanelFixture()

    // Act
    fixture.panel.cancelOperation(nil)

    // Assert
    #expect(!fixture.panel.isVisible)
}

@Test @MainActor
func test_cancelOperation_when_translationIsPinned_then_keepsPanelVisible() throws {
    // Arrange
    let fixture = try makeTranslationPanelFixture()
    try pinPanel(fixture.panel)

    // Act
    fixture.panel.cancelOperation(nil)

    // Assert
    #expect(fixture.panel.isVisible)
    fixture.panel.orderOut(nil)
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
    let fixture = try makeTranslationPanelFixture(sourceText: sourceText)
    let contentView = try #require(fixture.panel.contentView)
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
    fixture.panel.orderOut(nil)
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
    let fixture = try makeTranslationPanelFixture(sourceText: sourceText)
    let contentView = try #require(fixture.panel.contentView)
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
            windowNumber: fixture.panel.windowNumber,
            context: nil,
            eventNumber: 0,
            clickCount: 0,
            pressure: 0
        )
    )
    NSCursor.arrow.set()

    // Act
    fixture.panel.sendEvent(event)

    // Assert
    #expect(NSCursor.current === NSCursor.pointingHand)
    fixture.panel.orderOut(nil)
}

private struct TranslationPanelTestFixture {
    let application: NSApplication
    let applicationNotificationCenter: NotificationCenter
    let controller: TranslationPanelController
    let panel: TranslationPanel
}

@MainActor
private func pinPanel(_ panel: TranslationPanel) throws {
    let pinButton = try #require(
        panel.toolbar?.items.first {
            $0.itemIdentifier == .pinPanel
        }?.view as? NSButton
    )
    pinButton.performClick(nil)
}

@MainActor
private func makeTranslationPanelFixture(
    sourceText: String = "Hello"
) throws -> TranslationPanelTestFixture {
    let application = NSApplication.shared
    let applicationNotificationCenter = NotificationCenter()
    let existingPanels = Set(
        application.windows.compactMap { window in
            (window as? TranslationPanel).map(ObjectIdentifier.init)
        }
    )
    let coordinator = TranslationCoordinator()
    coordinator.submit(
        try SelectedText(sourceText),
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "zh-Hant"
    )
    let controller = TranslationPanelController(
        applicationNotificationCenter: applicationNotificationCenter
    )
    controller.show(
        coordinator: coordinator,
        supportedLanguages: [
            Locale.Language(identifier: "en"),
            Locale.Language(identifier: "zh-Hant"),
        ],
        pointerLocation: .zero
    )
    let panel = try #require(
        application.windows.compactMap { $0 as? TranslationPanel }.first {
            !existingPanels.contains(ObjectIdentifier($0))
        }
    )
    return TranslationPanelTestFixture(
        application: application,
        applicationNotificationCenter: applicationNotificationCenter,
        controller: controller,
        panel: panel
    )
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
