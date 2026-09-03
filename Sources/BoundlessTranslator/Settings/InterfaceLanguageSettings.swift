import Combine
import Foundation

@MainActor
final class InterfaceLanguageSettings: ObservableObject {
    @Published var languageIdentifier: String? {
        didSet {
            defaults.set(languageIdentifier, forKey: languageIdentifierKey)
        }
    }

    var resolvedLanguageIdentifier: String {
        resolvedLanguageIdentifier(for: languageIdentifier)
    }

    func resolvedLanguageIdentifier(for languageIdentifier: String?) -> String {
        let preferences = languageIdentifier.map { [$0] }
            ?? preferredLanguageIdentifiers()
        return InterfaceLanguageCatalog.preferredLanguageIdentifier(
            for: preferences
        )
    }

    var locale: Locale {
        Locale(identifier: resolvedLanguageIdentifier)
    }

    var isRightToLeft: Bool {
        Locale.Language(
            identifier: resolvedLanguageIdentifier
        ).characterDirection == .rightToLeft
    }

    private let defaults: UserDefaults
    private let preferredLanguageIdentifiers: () -> [String]
    private let languageIdentifierKey = "interfaceLanguageIdentifier"

    init(
        defaults: UserDefaults = .standard,
        preferredLanguageIdentifiers: @escaping () -> [String] = {
            Locale.preferredLanguages
        }
    ) {
        self.defaults = defaults
        self.preferredLanguageIdentifiers = preferredLanguageIdentifiers
        languageIdentifier = defaults.string(forKey: languageIdentifierKey)
    }
}
