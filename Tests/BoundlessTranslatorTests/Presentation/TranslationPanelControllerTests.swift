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
func test_applicationDidResignActive_when_translationIsUnpinned_then_keepsPanelVisible() throws {
    // Arrange
    let fixture = try makeTranslationPanelFixture()

    // Act
    NotificationCenter.default.post(
        name: NSApplication.didResignActiveNotification,
        object: fixture.application
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

private struct TranslationPanelTestFixture {
    let application: NSApplication
    let controller: TranslationPanelController
    let panel: TranslationPanel
}

@MainActor
private func makeTranslationPanelFixture() throws -> TranslationPanelTestFixture {
    let application = NSApplication.shared
    let existingPanels = Set(
        application.windows.compactMap { window in
            (window as? TranslationPanel).map(ObjectIdentifier.init)
        }
    )
    let coordinator = TranslationCoordinator()
    coordinator.submit(
        try SelectedText("Hello"),
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "zh-Hant"
    )
    let controller = TranslationPanelController()
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
        controller: controller,
        panel: panel
    )
}
