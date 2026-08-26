import Foundation

struct LanguageOption: Identifiable {
    let id: String
    let language: Locale.Language

    static func make(
        supportedLanguages: [Locale.Language],
        selectedIdentifier: String
    ) -> [LanguageOption] {
        let selectedLanguage = Locale.Language(identifier: selectedIdentifier)
        var matchedSelectedLanguage = false

        let supportedOptions = supportedLanguages.map { language in
            let representsSelection = !matchedSelectedLanguage
                && language.maximalIdentifier == selectedLanguage.maximalIdentifier
            if representsSelection {
                matchedSelectedLanguage = true
            }

            return LanguageOption(
                id: representsSelection ? selectedIdentifier : language.minimalIdentifier,
                language: language
            )
        }

        guard !matchedSelectedLanguage else {
            return supportedOptions
        }

        return [
            LanguageOption(
                id: selectedIdentifier,
                language: selectedLanguage
            )
        ] + supportedOptions
    }

    static func preferredIdentifier(
        supportedLanguages: [Locale.Language],
        suggestedIdentifier: String?
    ) -> String? {
        guard let suggestedIdentifier else {
            return supportedLanguages.first?.minimalIdentifier
        }

        let suggestedLanguage = Locale.Language(identifier: suggestedIdentifier)
        let isSupported = supportedLanguages.contains {
            $0.maximalIdentifier == suggestedLanguage.maximalIdentifier
        }
        return isSupported
            ? suggestedIdentifier
            : supportedLanguages.first?.minimalIdentifier
    }
}
