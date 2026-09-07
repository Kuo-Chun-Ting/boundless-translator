import Foundation

struct SourceLanguageSelection: Equatable, Sendable {
    let selectedLanguageIdentifier: String

    static func make(
        supportedLanguages: [Locale.Language],
        suggestedLanguageIdentifier: String?
    ) -> SourceLanguageSelection? {
        guard let selectedLanguageIdentifier = LanguageOption.preferredIdentifier(
            supportedLanguages: supportedLanguages,
            suggestedIdentifier: suggestedLanguageIdentifier
        ) else {
            return nil
        }

        return SourceLanguageSelection(
            selectedLanguageIdentifier: selectedLanguageIdentifier
        )
    }
}
