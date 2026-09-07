import Foundation

struct TranslationLanguagePairFormatter {
    private let languageNames: LanguageDisplayNameFormatter
    private let localization: AppLocalization

    init(
        locale: Locale = Locale(identifier: "en_US"),
        localization: AppLocalization
    ) {
        languageNames = LanguageDisplayNameFormatter(locale: locale)
        self.localization = localization
    }

    func sourceDescription(
        languageIdentifier: String,
        wasDetected: Bool
    ) -> String {
        let sourceName = languageName(for: languageIdentifier)
        return wasDetected
            ? localization.string(
                "panel.language.detectedName",
                arguments: sourceName
            )
            : sourceName
    }

    func languageName(for identifier: String) -> String {
        languageNames.name(for: identifier)
    }
}
