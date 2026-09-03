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
        message: .translationLanguagesUnavailable,
        interfaceLanguageSettings: interfaceLanguageSettings
    )
    #expect(
        view.localizedMessage
            == "No translation languages are available. Check your macOS language settings and try again."
    )

    // Act
    interfaceLanguageSettings.languageIdentifier = "zh-Hant"

    // Assert
    #expect(
        view.localizedMessage
            == "沒有可用的翻譯語言。請檢查 macOS 語言設定，然後再試一次。"
    )
}
