import Foundation
import Testing
@testable import BoundlessTranslator

@Test
func test_localizedString_when_language_is_traditional_chinese_then_returns_traditional_chinese_value() {
    // Arrange
    let localization = AppLocalization(languageIdentifier: "zh-Hant")

    // Act
    let result = localization.string("interfaceLanguage.followMacOS")

    // Assert
    #expect(result == "系統預設")
}

@Test
func test_localizedString_when_preferencesAreEnglish_then_returnsFlatPreferenceLabels() {
    // Arrange
    let localization = AppLocalization(languageIdentifier: "en")

    // Act
    let result = [
        localization.string("preferences.translateFrom"),
        localization.string("preferences.translateTo"),
    ]

    // Assert
    #expect(result == ["Translate From", "Translate To"])
}

@Test
func test_localizedString_when_usageIsTraditionalChinese_then_returnsLanguageSupportCopy() {
    // Arrange
    let localization = AppLocalization(languageIdentifier: "zh-Hant")

    // Act
    let result = [
        localization.string("usage.languageSupport.title"),
        localization.string("usage.languageSupport.description"),
    ]

    // Assert
    #expect(result == [
        "語言支援",
        "介面語言支援範圍與 macOS 相同。哪些語言可以互相翻譯，則由 macOS 決定。",
    ])
}

@Test
func test_localizedString_when_localized_value_is_empty_then_fallsBackToEnglish() throws {
    // Arrange
    let fixture_bundle = try makeLocalizationBundle(
        englishValue: "Preferences…",
        koreanValue: ""
    )
    defer { fixture_bundle.cleanUp() }
    let localization = AppLocalization(
        languageIdentifier: "ko",
        bundle: fixture_bundle.bundle
    )

    // Act
    let result = localization.string("menu.preferences")

    // Assert
    #expect(result == "Preferences…")
}

@Test
func test_languageIdentifiers_when_catalog_is_loaded_then_contains_all_macos_interface_languages() {
    // Arrange
    let expectedIdentifiers = [
        "ar", "ca", "cs", "da", "de", "el", "en", "en-AU", "en-CA",
        "en-GB", "en-IE", "en-IN", "en-NZ", "en-SG", "en-ZA", "es",
        "es-419", "es-MX", "es-US", "fi", "fr", "fr-CA", "he", "hi",
        "hr", "hu", "id", "it", "ja", "ko", "ms", "nl", "no", "pl",
        "pt-BR", "pt-PT", "ro", "ru", "sk", "sl", "sv", "th", "tr",
        "uk", "vi", "zh-Hans", "zh-Hant", "zh-Hant-HK"
    ]

    // Act
    let result = InterfaceLanguageCatalog.languageIdentifiers

    // Assert
    #expect(result == expectedIdentifiers)
}

@Test
func test_localizations_when_reading_non_english_language_then_translate_most_english_values() throws {
    // Arrange
    let english = try localizationDictionary(languageIdentifier: "en")
    let languageIdentifiers = InterfaceLanguageCatalog.languageIdentifiers
        .filter { !$0.hasPrefix("en") }

    // Act & Assert
    for languageIdentifier in languageIdentifiers {
        let localization = try localizationDictionary(
            languageIdentifier: languageIdentifier
        )
        let translatedValueCount = english.keys.filter {
            localization[$0] != english[$0]
        }.count
        #expect(
            translatedValueCount >= english.count * 3 / 4,
            "\(languageIdentifier) still contains mostly English values"
        )
    }
}

@Test
func test_localizations_when_readingEverySupportedLanguage_then_haveCompleteKeysAndPlaceholders() throws {
    // Arrange
    let english = try localizationDictionary(languageIdentifier: "en")
    let expectedKeys = Set(english.keys)

    // Act & Assert
    for languageIdentifier in InterfaceLanguageCatalog.languageIdentifiers {
        let localization = try localizationDictionary(
            languageIdentifier: languageIdentifier
        )
        #expect(Set(localization.keys) == expectedKeys)
        for key in expectedKeys {
            #expect(localization[key]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            #expect(
                localization[key]?.components(separatedBy: "%@").count
                    == english[key]?.components(separatedBy: "%@").count
            )
        }
    }
}

private func localizationDictionary(
    languageIdentifier: String
) throws -> [String: String] {
    let resourceIdentifier = InterfaceLanguageCatalog.resourceIdentifier(
        for: languageIdentifier
    )
    let path = try #require(
        Bundle.module.path(
            forResource: resourceIdentifier,
            ofType: "lproj"
        )
    )
    let stringsPath = URL(fileURLWithPath: path)
        .appending(path: "Localizable.strings")
        .path
    return try #require(
        NSDictionary(contentsOfFile: stringsPath) as? [String: String]
    )
}

private struct LocalizationBundleFixture {
    let url: URL
    let bundle: Bundle

    func cleanUp() {
        try? FileManager.default.removeItem(at: url)
    }
}

private func makeLocalizationBundle(
    englishValue: String,
    koreanValue: String
) throws -> LocalizationBundleFixture {
    let root = FileManager.default.temporaryDirectory
        .appending(path: "AppLocalizationTests.\(UUID().uuidString).bundle")
    let englishDirectory = root.appending(path: "en.lproj")
    let koreanDirectory = root.appending(path: "ko.lproj")
    try FileManager.default.createDirectory(
        at: englishDirectory,
        withIntermediateDirectories: true
    )
    try FileManager.default.createDirectory(
        at: koreanDirectory,
        withIntermediateDirectories: true
    )
    let info = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0"><dict>
    <key>CFBundleIdentifier</key><string>AppLocalizationTests</string>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleLocalizations</key><array><string>en</string><string>ko</string></array>
    </dict></plist>
    """
    try info.write(
        to: root.appending(path: "Info.plist"),
        atomically: true,
        encoding: .utf8
    )
    try "\"menu.preferences\" = \"\(englishValue)\";\n".write(
        to: englishDirectory.appending(path: "Localizable.strings"),
        atomically: true,
        encoding: .utf8
    )
    try "\"menu.preferences\" = \"\(koreanValue)\";\n".write(
        to: koreanDirectory.appending(path: "Localizable.strings"),
        atomically: true,
        encoding: .utf8
    )
    return LocalizationBundleFixture(
        url: root,
        bundle: try #require(Bundle(url: root))
    )
}
