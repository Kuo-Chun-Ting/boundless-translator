import Foundation
@testable import BoundlessTranslator

let testEnglishLocalization = AppLocalization(languageIdentifier: "en")

@MainActor
func makeTestInterfaceLanguageSettings() -> InterfaceLanguageSettings {
    let suiteName = "InterfaceLanguageComponentTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    let settings = InterfaceLanguageSettings(
        defaults: defaults,
        preferredLanguageIdentifiers: { ["en"] }
    )
    defaults.removePersistentDomain(forName: suiteName)
    return settings
}

@MainActor
extension SourceTextLookupView {
    convenience init() {
        self.init(localization: testEnglishLocalization)
    }

    convenience init(
        dictionaryPresenter: any DictionaryDefinitionPresenting
    ) {
        self.init(
            dictionaryPresenter: dictionaryPresenter,
            localization: testEnglishLocalization
        )
    }
}
