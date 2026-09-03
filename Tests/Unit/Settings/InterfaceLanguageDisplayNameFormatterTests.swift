import Foundation
import Testing
@testable import BoundlessTranslator

@Test
func test_name_when_languageIsPresentedInEnglish_thenShowsNativeAndEnglishNames() {
    // Arrange
    let formatter = InterfaceLanguageDisplayNameFormatter(
        displayLocale: Locale(identifier: "en")
    )

    // Act
    let name = formatter.name(for: "zh-Hant")

    // Assert
    #expect(name == "\u{2068}繁體中文\u{2069} — Chinese, Traditional")
}

@Test
func test_name_when_nativeNameStartsLowercase_thenUsesDisplayCapitalization() {
    // Arrange
    let formatter = InterfaceLanguageDisplayNameFormatter(
        displayLocale: Locale(identifier: "en")
    )

    // Act
    let name = formatter.name(for: "sk")

    // Assert
    #expect(name == "\u{2068}Slovenčina\u{2069} — Slovak")
}

@Test
func test_systemDefaultName_when_systemLanguageIsEnglish_thenShowsResolvedLanguage() {
    // Arrange
    let formatter = InterfaceLanguageDisplayNameFormatter(
        displayLocale: Locale(identifier: "en")
    )

    // Act
    let name = formatter.systemDefaultName(
        label: "System Default",
        languageIdentifier: "en"
    )

    // Assert
    #expect(name == "System Default — English")
}

@Test
func test_name_when_macosUsesSpecificAutonyms_thenMatchesNativeLabels() {
    // Arrange
    let formatter = InterfaceLanguageDisplayNameFormatter(
        displayLocale: Locale(identifier: "en")
    )

    // Act
    let names = ["en-GB", "es-US", "id", "no", "th"].map {
        formatter.name(for: $0)
    }

    // Assert
    #expect(names == [
        "\u{2068}English (UK)\u{2069} — English (United Kingdom)",
        "\u{2068}Español (EE. UU.)\u{2069} — Spanish (United States)",
        "\u{2068}Bahasa Indonesia\u{2069} — Indonesian",
        "\u{2068}Norsk bokmål\u{2069} — Norwegian",
        "\u{2068}ภาษาไทย\u{2069} — Thai",
    ])
}
