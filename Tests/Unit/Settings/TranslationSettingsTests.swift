import Foundation
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_init_when_value_is_missing_then_requires_target_selection() {
    // Arrange
    let fixture_defaults = makeIsolatedDefaults()
    defer { fixture_defaults.cleanUp() }

    // Act
    let settings = TranslationSettings(defaults: fixture_defaults.defaults)

    // Assert
    #expect(settings.targetLanguageIdentifier == "")
}

@Test @MainActor
func test_init_when_source_language_is_missing_then_requires_source_selection() {
    // Arrange
    let fixture_defaults = makeIsolatedDefaults()
    defer { fixture_defaults.cleanUp() }

    // Act
    let settings = TranslationSettings(defaults: fixture_defaults.defaults)

    // Assert
    #expect(settings.sourceLanguageIdentifier == "")
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
func test_resetUnsupportedTargetLanguage_when_stored_language_is_unsupported_then_clears_and_persists_selection() {
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
    settings.resetUnsupportedTargetLanguage(supportedLanguages: supportedLanguages)
    let restoredSettings = TranslationSettings(defaults: fixture_defaults.defaults)

    // Assert
    #expect(settings.targetLanguageIdentifier == "")
    #expect(restoredSettings.targetLanguageIdentifier == "")
}

@Test @MainActor
func test_resetUnsupportedTargetLanguage_when_stored_language_is_unsupported_then_requires_selection() {
    // Arrange
    let fixture_defaults = makeIsolatedDefaults()
    defer { fixture_defaults.cleanUp() }
    fixture_defaults.defaults.set("xx-Invalid", forKey: "targetLanguageIdentifier")
    let settings = TranslationSettings(defaults: fixture_defaults.defaults)
    let supportedLanguages = [Locale.Language(identifier: "ja")]

    // Act
    settings.resetUnsupportedTargetLanguage(supportedLanguages: supportedLanguages)

    // Assert
    #expect(settings.targetLanguageIdentifier == "")
}

@Test @MainActor
func test_resetUnsupportedSourceLanguage_when_stored_language_is_unsupported_then_requires_source_selection() {
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
    settings.resetUnsupportedSourceLanguage(supportedLanguages: supportedLanguages)
    let restoredSettings = TranslationSettings(defaults: fixture_defaults.defaults)

    // Assert
    #expect(settings.sourceLanguageIdentifier == "")
    #expect(restoredSettings.sourceLanguageIdentifier == "")
}

@Test @MainActor
func test_sourceLanguageIdentifier_when_automatic_is_selected_then_restores_automatic() {
    // Arrange
    let fixture_defaults = makeIsolatedDefaults()
    defer { fixture_defaults.cleanUp() }
    let settings = TranslationSettings(defaults: fixture_defaults.defaults)
    settings.sourceLanguageIdentifier = "ja"

    // Act
    settings.sourceLanguageIdentifier = nil
    let restoredSettings = TranslationSettings(defaults: fixture_defaults.defaults)

    // Assert
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

@Test(arguments: [("", "", false), ("en", "", false), ("", "ja", false), ("en", "ja", true), (nil, "ja", true), (nil, "", false)]) @MainActor
func test_hasSelectedLanguages_when_pair_changes_then_only_complete_pairs_are_ready(source: String?, target: String, expected: Bool) {
    // Arrange
    let fixture_defaults = makeIsolatedDefaults()
    defer { fixture_defaults.cleanUp() }
    let settings = TranslationSettings(defaults: fixture_defaults.defaults)

    // Act
    settings.sourceLanguageIdentifier = source
    settings.targetLanguageIdentifier = target

    // Assert
    #expect(settings.hasSelectedLanguages == expected)
}
