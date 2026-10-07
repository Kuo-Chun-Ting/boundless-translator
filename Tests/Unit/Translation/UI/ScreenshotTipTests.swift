import Testing
@testable import BoundlessTranslator

@Test
func test_instruction_whenLanguageIsEnglish_then_describesScreenshotFeatures() {
    // Arrange
    let tip = ScreenshotTip(localization: AppLocalization(languageIdentifier: "en"))
    // Act
    let instruction = tip.instruction
    // Assert
    #expect(instruction == "Hold the pointer over a word or select text to see its translation. You can also listen to the original text or look it up in the dictionary.")
}

@Test
func test_instruction_whenLanguageIsTraditionalChinese_then_usesLocalizedSentence() {
    // Arrange
    let tip = ScreenshotTip(localization: AppLocalization(languageIdentifier: "zh-Hant"))
    // Act
    let instruction = tip.instruction
    // Assert
    #expect(instruction == "滑鼠停在單字上或選取文字即可查看翻譯，也可朗讀原文或查字典。")
}
