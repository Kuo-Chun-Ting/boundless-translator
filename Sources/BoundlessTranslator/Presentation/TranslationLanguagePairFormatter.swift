import Foundation

struct TranslationLanguagePairFormatter {
    private let locale: Locale

    init(locale: Locale = Locale(identifier: "en_US")) {
        self.locale = locale
    }

    func sourceDescription(
        languageIdentifier: String,
        wasDetected: Bool
    ) -> String {
        let sourceName = languageName(for: languageIdentifier)
        return wasDetected ? "\(sourceName) (Detected)" : sourceName
    }

    func languageName(for identifier: String) -> String {
        guard let localizedName = locale.localizedString(forIdentifier: identifier) else {
            return identifier
        }

        let parts = localizedName.split(
            separator: ",",
            maxSplits: 1,
            omittingEmptySubsequences: true
        )
        guard parts.count == 2 else {
            return localizedName
        }

        return "\(parts[1].trimmingCharacters(in: .whitespaces)) \(parts[0])"
    }
}
