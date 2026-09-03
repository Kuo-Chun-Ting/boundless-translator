import Foundation

struct InterfaceLanguageDisplayNameFormatter {
    private let displayLocale: Locale

    init(displayLocale: Locale) {
        self.displayLocale = displayLocale
    }

    func name(for languageIdentifier: String) -> String {
        let nativeName = Self.nativeNames[languageIdentifier]
            ?? localizedName(
                for: languageIdentifier,
                locale: Locale(identifier: languageIdentifier)
            )
        let displayName = localizedName(
            for: languageIdentifier,
            locale: displayLocale
        )
        return "\u{2068}\(nativeName)\u{2069} — \(displayName)"
    }

    func systemDefaultName(
        label: String,
        languageIdentifier: String
    ) -> String {
        let languageName = localizedName(
            for: languageIdentifier,
            locale: displayLocale
        )
        return "\(label) — \(languageName)"
    }

    func localizedName(for languageIdentifier: String) -> String {
        localizedName(for: languageIdentifier, locale: displayLocale)
    }

    private func localizedName(
        for languageIdentifier: String,
        locale: Locale
    ) -> String {
        guard let name = locale.localizedString(
            forIdentifier: languageIdentifier
        ) else {
            return languageIdentifier
        }
        guard let firstCharacter = name.first else {
            return name
        }
        return String(firstCharacter).uppercased(with: locale)
            + String(name.dropFirst())
    }

    private static let nativeNames = [
        "ar": "العربية",
        "ca": "Català",
        "cs": "Čeština",
        "da": "Dansk",
        "de": "Deutsch",
        "el": "Ελληνικά",
        "en": "English",
        "en-AU": "English (Australia)",
        "en-CA": "English (Canada)",
        "en-GB": "English (UK)",
        "en-IE": "English (Ireland)",
        "en-IN": "English (India)",
        "en-NZ": "English (New Zealand)",
        "en-SG": "English (Singapore)",
        "en-ZA": "English (South Africa)",
        "es": "Español",
        "es-419": "Español (Latinoamérica)",
        "es-MX": "Español (México)",
        "es-US": "Español (EE. UU.)",
        "fi": "Suomi",
        "fr": "Français",
        "fr-CA": "Français (Canada)",
        "he": "עברית",
        "hi": "हिन्दी",
        "hr": "Hrvatski",
        "hu": "Magyar",
        "id": "Bahasa Indonesia",
        "it": "Italiano",
        "ja": "日本語",
        "ko": "한국어",
        "ms": "Bahasa Melayu",
        "nl": "Nederlands",
        "no": "Norsk bokmål",
        "pl": "Polski",
        "pt-BR": "Português (Brasil)",
        "pt-PT": "Português (Portugal)",
        "ro": "Română",
        "ru": "Русский",
        "sk": "Slovenčina",
        "sl": "Slovenščina",
        "sv": "Svenska",
        "th": "ภาษาไทย",
        "tr": "Türkçe",
        "uk": "Українська",
        "vi": "Tiếng Việt",
        "zh-Hans": "简体中文",
        "zh-Hant": "繁體中文",
        "zh-Hant-HK": "繁體中文（香港）",
    ]
}
