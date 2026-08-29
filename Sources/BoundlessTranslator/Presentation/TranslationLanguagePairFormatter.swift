import Foundation

struct TranslationLanguagePairFormatter {
    private let languageNames: LanguageDisplayNameFormatter

    init(locale: Locale = Locale(identifier: "en_US")) {
        languageNames = LanguageDisplayNameFormatter(locale: locale)
    }

    func sourceDescription(
        languageIdentifier: String,
        wasDetected: Bool
    ) -> String {
        let sourceName = languageName(for: languageIdentifier)
        return wasDetected ? "\(sourceName) (Detected)" : sourceName
    }

    func languageName(for identifier: String) -> String {
        languageNames.name(for: identifier)
    }
}
