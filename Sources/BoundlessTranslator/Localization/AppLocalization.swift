import Foundation

struct AppLocalization {
    let languageIdentifier: String

    private let localizedBundle: Bundle?
    private let englishBundle: Bundle?
    private let usesEnglishLocalization: Bool

    static var defaultBundle: Bundle {
        if Bundle.main.path(
            forResource: "Localizable",
            ofType: "strings",
            inDirectory: nil,
            forLocalization: "en"
        ) != nil {
            return .main
        }
#if SWIFT_PACKAGE
        return .module
#else
        return .main
#endif
    }

    init(
        languageIdentifier: String,
        bundle: Bundle? = nil
    ) {
        self.languageIdentifier = languageIdentifier
        let sourceBundle = bundle ?? Self.defaultBundle
        let localization = Bundle.preferredLocalizations(
            from: sourceBundle.localizations,
            forPreferences: [languageIdentifier]
        ).first ?? "en"
        let resourceLocalization = InterfaceLanguageCatalog.resourceIdentifier(
            for: localization,
            availableIdentifiers: sourceBundle.localizations
        )
        localizedBundle = sourceBundle.path(
            forResource: resourceLocalization,
            ofType: "lproj"
        ).flatMap(Bundle.init(path:))
        englishBundle = sourceBundle.path(
            forResource: "en",
            ofType: "lproj"
        ).flatMap(Bundle.init(path:))
        usesEnglishLocalization = resourceLocalization.lowercased() == "en"
    }

    func string(_ key: String) -> String {
        let value = localizedBundle?.localizedString(
            forKey: key,
            value: key,
            table: nil
        ) ?? key
        let isMissing = value == key
            || value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        guard isMissing, !usesEnglishLocalization else {
            return value
        }
        return englishBundle?.localizedString(
            forKey: key,
            value: key,
            table: nil
        ) ?? key
    }

    func string(_ key: String, arguments: CVarArg...) -> String {
        String(
            format: string(key),
            locale: Locale(identifier: languageIdentifier),
            arguments: arguments
        )
    }
}
