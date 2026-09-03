import Foundation

enum InterfaceLanguageCatalog {
    static var languageIdentifiers: [String] {
        AppLocalization.defaultBundle.localizations
            .filter { $0 != "Base" }
            .map(canonicalResourceIdentifier)
            .sorted()
    }

    static func preferredLanguageIdentifier(
        for preferences: [String]
    ) -> String {
        Bundle.preferredLocalizations(
            from: languageIdentifiers,
            forPreferences: preferences
        ).first ?? "en"
    }

    static func resourceIdentifier(
        for languageIdentifier: String,
        availableIdentifiers: [String]? = nil
    ) -> String {
        let identifiers = availableIdentifiers
            ?? AppLocalization.defaultBundle.localizations
        return identifiers.first {
            canonicalResourceIdentifier($0)
                == canonicalResourceIdentifier(languageIdentifier)
        } ?? languageIdentifier
    }

    private static func canonicalResourceIdentifier(
        _ identifier: String
    ) -> String {
        identifier
            .replacingOccurrences(of: "_", with: "-")
            .split(separator: "-")
            .enumerated()
            .map { index, component in
                if index == 0 {
                    return component.lowercased()
                }
                if component.count == 4 {
                    return component.prefix(1).uppercased()
                        + component.dropFirst().lowercased()
                }
                if component.count == 2 {
                    return component.uppercased()
                }
                return component.lowercased()
            }
            .joined(separator: "-")
    }
}
