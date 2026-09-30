import Testing
@testable import BoundlessTranslator

@Test
func test_instruction_whenShortcutIsCustomized_then_displaysProvidedShortcut() {
    // Arrange
    let tip = ScreenshotTip(localization: AppLocalization(languageIdentifier: "en"), shortcut: "⌥T")
    // Act
    let instruction = tip.instruction
    // Assert
    #expect(instruction == "Select text and press ⌥T to translate.")
}

@Test
func test_instruction_whenLanguageIsTraditionalChinese_then_usesLocalizedSentence() {
    // Arrange
    let tip = ScreenshotTip(localization: AppLocalization(languageIdentifier: "zh-Hant"), shortcut: "⇧⌘1")
    // Act
    let instruction = tip.instruction
    // Assert
    #expect(instruction == "選字後按 ⇧⌘1 翻譯。")
}
