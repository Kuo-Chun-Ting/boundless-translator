import Foundation
import Testing
@testable import WhisperTranslate

@Test @MainActor
func test_init_when_value_is_missing_then_defaults_to_traditional_chinese() {
    // Arrange
    let fixture_defaults = makeIsolatedDefaults()
    defer { fixture_defaults.cleanUp() }

    // Act
    let settings = TranslationSettings(defaults: fixture_defaults.defaults)

    // Assert
    #expect(settings.targetLanguageIdentifier == "zh-Hant")
}

@Test @MainActor
func test_init_when_source_language_is_missing_then_defaults_to_detection() {
    // Arrange
    let fixture_defaults = makeIsolatedDefaults()
    defer { fixture_defaults.cleanUp() }

    // Act
    let settings = TranslationSettings(defaults: fixture_defaults.defaults)

    // Assert
    #expect(settings.sourceLanguageIdentifier == nil)
}

@Test @MainActor
func test_targetLanguageIdentifier_when_changed_then_persists_for_next_instance() {
    // Arrange
    let fixture_defaults = makeIsolatedDefaults()
    defer { fixture_defaults.cleanUp() }
    let settings = TranslationSettings(defaults: fixture_defaults.defaults)

    // Act
    settings.targetLanguageIdentifier = "ja"
    let restoredSettings = TranslationSettings(defaults: fixture_defaults.defaults)

    // Assert
    #expect(restoredSettings.targetLanguageIdentifier == "ja")
}

@Test @MainActor
func test_sourceLanguageIdentifier_when_changed_then_persists_for_next_instance() {
    // Arrange
    let fixture_defaults = makeIsolatedDefaults()
    defer { fixture_defaults.cleanUp() }
    let settings = TranslationSettings(defaults: fixture_defaults.defaults)

    // Act
    settings.sourceLanguageIdentifier = "en"
    let restoredSettings = TranslationSettings(defaults: fixture_defaults.defaults)

    // Assert
    #expect(restoredSettings.sourceLanguageIdentifier == "en")
}

@Test @MainActor
func test_validateTargetLanguage_when_stored_language_is_unsupported_then_resets_and_persists_default() {
    // Arrange
    let fixture_defaults = makeIsolatedDefaults()
    defer { fixture_defaults.cleanUp() }
    fixture_defaults.defaults.set("xx-Invalid", forKey: "targetLanguageIdentifier")
    let settings = TranslationSettings(defaults: fixture_defaults.defaults)
    let supportedLanguages = [
        Locale.Language(identifier: "en"),
        Locale.Language(identifier: "zh-TW")
    ]

    // Act
    settings.validateTargetLanguage(supportedLanguages: supportedLanguages)
    let restoredSettings = TranslationSettings(defaults: fixture_defaults.defaults)

    // Assert
    #expect(settings.targetLanguageIdentifier == "zh-Hant")
    #expect(restoredSettings.targetLanguageIdentifier == "zh-Hant")
}

@Test @MainActor
func test_validateTargetLanguage_when_default_is_unsupported_then_uses_first_supported_language() {
    // Arrange
    let fixture_defaults = makeIsolatedDefaults()
    defer { fixture_defaults.cleanUp() }
    fixture_defaults.defaults.set("xx-Invalid", forKey: "targetLanguageIdentifier")
    let settings = TranslationSettings(defaults: fixture_defaults.defaults)
    let supportedLanguages = [Locale.Language(identifier: "ja")]

    // Act
    settings.validateTargetLanguage(supportedLanguages: supportedLanguages)

    // Assert
    #expect(settings.targetLanguageIdentifier == "ja")
}

@Test @MainActor
func test_validateSourceLanguage_when_stored_language_is_unsupported_then_resets_to_detection() {
    // Arrange
    let fixture_defaults = makeIsolatedDefaults()
    defer { fixture_defaults.cleanUp() }
    fixture_defaults.defaults.set("xx-Invalid", forKey: "sourceLanguageIdentifier")
    let settings = TranslationSettings(defaults: fixture_defaults.defaults)
    let supportedLanguages = [
        Locale.Language(identifier: "en"),
        Locale.Language(identifier: "zh-TW")
    ]

    // Act
    settings.validateSourceLanguage(supportedLanguages: supportedLanguages)
    let restoredSettings = TranslationSettings(defaults: fixture_defaults.defaults)

    // Assert
    #expect(settings.sourceLanguageIdentifier == nil)
    #expect(restoredSettings.sourceLanguageIdentifier == nil)
}

private struct IsolatedDefaults {
    let suiteName: String
    let defaults: UserDefaults

    func cleanUp() {
        defaults.removePersistentDomain(forName: suiteName)
    }
}

private func makeIsolatedDefaults() -> IsolatedDefaults {
    let suiteName = "TranslationSettingsTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return IsolatedDefaults(suiteName: suiteName, defaults: defaults)
}
