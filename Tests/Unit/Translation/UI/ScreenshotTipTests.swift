import Testing
@testable import BoundlessTranslator

@Test
func test_instruction_whenShortcutIsCustomized_then_displaysProvidedShortcut() {
    // Arrange
    let tip = ScreenshotTip(localization: AppLocalization(languageIdentifier: "en"), shortcut: "⌥T")
    // Act
    let instruction = tip.instruction
    // Assert
    #expect(instruction == "Hover over a word or select text to translate. Click the speaker to listen or the book to look up. Select text and press ⌥T to open the translation window.")
}

@Test
func test_instruction_whenLanguageIsTraditionalChinese_then_usesLocalizedSentence() {
    // Arrange
    let tip = ScreenshotTip(localization: AppLocalization(languageIdentifier: "zh-Hant"), shortcut: "⇧⌘1")
    // Act
    let instruction = tip.instruction
    // Assert
    #expect(instruction == "停在單字上或選取文字即可翻譯。點喇叭朗讀、點書本查字典。選字後按 ⇧⌘1 開啟翻譯視窗。")
}
