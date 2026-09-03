import Foundation
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_init_when_value_is_missing_then_follows_macos() {
    // Arrange
    let fixture_defaults = makeInterfaceLanguageDefaults()
    defer { fixture_defaults.cleanUp() }

    // Act
    let settings = InterfaceLanguageSettings(
        defaults: fixture_defaults.defaults,
        preferredLanguageIdentifiers: { ["zh-TW", "en"] }
    )

    // Assert
    #expect(settings.languageIdentifier == nil)
    #expect(settings.resolvedLanguageIdentifier == "zh-Hant")
}

@Test @MainActor
func test_languageIdentifier_when_explicit_language_is_selected_then_persists_for_next_instance() {
    // Arrange
    let fixture_defaults = makeInterfaceLanguageDefaults()
    defer { fixture_defaults.cleanUp() }
    let settings = InterfaceLanguageSettings(
        defaults: fixture_defaults.defaults,
        preferredLanguageIdentifiers: { ["zh-Hant"] }
    )

    // Act
    settings.languageIdentifier = "ja"
    let restoredSettings = InterfaceLanguageSettings(
        defaults: fixture_defaults.defaults,
        preferredLanguageIdentifiers: { ["zh-Hant"] }
    )

    // Assert
    #expect(restoredSettings.languageIdentifier == "ja")
    #expect(restoredSettings.resolvedLanguageIdentifier == "ja")
}

@Test @MainActor
func test_resolvedLanguageIdentifier_when_macos_has_no_preferred_language_then_uses_english() {
    // Arrange
    let fixture_defaults = makeInterfaceLanguageDefaults()
    defer { fixture_defaults.cleanUp() }
    let settings = InterfaceLanguageSettings(
        defaults: fixture_defaults.defaults,
        preferredLanguageIdentifiers: { [] }
    )

    // Act
    let result = settings.resolvedLanguageIdentifier

    // Assert
    #expect(result == "en")
}

@Test @MainActor
func test_isRightToLeft_when_explicit_language_is_arabic_then_returns_true() {
    // Arrange
    let fixture_defaults = makeInterfaceLanguageDefaults()
    defer { fixture_defaults.cleanUp() }
    let settings = InterfaceLanguageSettings(
        defaults: fixture_defaults.defaults,
        preferredLanguageIdentifiers: { ["en"] }
    )

    // Act
    settings.languageIdentifier = "ar"

    // Assert
    #expect(settings.isRightToLeft)
}

private struct InterfaceLanguageDefaults {
    let suiteName: String
    let defaults: UserDefaults

    func cleanUp() {
        defaults.removePersistentDomain(forName: suiteName)
    }
}

private func makeInterfaceLanguageDefaults() -> InterfaceLanguageDefaults {
    let suiteName = "InterfaceLanguageSettingsTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return InterfaceLanguageDefaults(suiteName: suiteName, defaults: defaults)
}
