import Foundation
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_localizedMessage_when_interfaceLanguageChanges_then_updatesErrorMessage() {
    // Arrange
    let suiteName = "SelectionErrorViewTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let interfaceLanguageSettings = InterfaceLanguageSettings(
        defaults: defaults,
        preferredLanguageIdentifiers: { ["en"] }
    )
    let view = SelectionErrorView(
        message: .screenshot(.captureFailed),
        interfaceLanguageSettings: interfaceLanguageSettings
    )
    #expect(
        view.localizedMessage
            == "Could not capture the screen region. Try again."
    )

    // Act
    interfaceLanguageSettings.languageIdentifier = "zh-Hant"

    // Assert
    #expect(
        view.localizedMessage
            == "無法擷取螢幕範圍。請再試一次。"
    )
}
