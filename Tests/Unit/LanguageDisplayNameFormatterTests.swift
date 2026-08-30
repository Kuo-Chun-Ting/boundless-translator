import Foundation
import Testing
@testable import BoundlessTranslator

@Test
func test_name_when_identifier_uses_traditional_script_then_returns_traditional_chinese() {
    // Arrange
    let formatter = LanguageDisplayNameFormatter(
        locale: Locale(identifier: "en_US")
    )

    // Act
    let name = formatter.name(for: "zh-Hant")

    // Assert
    #expect(name == "Traditional Chinese")
}

@Test
func test_name_when_option_language_is_regional_equivalent_then_uses_option_identifier() {
    // Arrange
    let formatter = LanguageDisplayNameFormatter(
        locale: Locale(identifier: "en_US")
    )
    let option = LanguageOption(
        id: "zh-Hant",
        language: Locale.Language(identifier: "zh-TW")
    )

    // Act
    let name = formatter.name(for: option)

    // Assert
    #expect(name == "Traditional Chinese")
}
