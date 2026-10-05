import Testing
@testable import BoundlessTranslator

@Test
func test_make_when_sourceIsUnsupported_then_createsLanguageLimitationTip() throws {
    // Arrange
    let localization = AppLocalization(languageIdentifier: "en")
    // Act
    let tip = ScreenshotLanguageTip.make(
        localization: localization, sourceLanguageIdentifier: "hi", recognitionLanguages: ["en-US"])
    // Assert
    #expect(try #require(tip).sourceLanguageIdentifier == "hi")
}

@Test
func test_make_when_sourceIsAutomatic_then_doesNotInferScreenshotLanguage() {
    // Arrange & Act
    let tip = ScreenshotLanguageTip.make(
        localization: AppLocalization(languageIdentifier: "en"),
        sourceLanguageIdentifier: nil, recognitionLanguages: ["en-US"])
    // Assert
    #expect(tip == nil)
}

@Test(arguments: ["en-GB", "zh-Hans", "zh-Hant", "no", "pt-PT"])
func test_make_when_sourceHasSupportedRegionVariant_then_doesNotShowLimitation(source: String) {
    // Arrange
    let supported = ["en-US", "zh-Hans", "zh-Hant", "nb-NO", "pt-BR"]
    // Act
    let tip = ScreenshotLanguageTip.make(
        localization: AppLocalization(languageIdentifier: "en"),
        sourceLanguageIdentifier: source, recognitionLanguages: supported)
    // Assert
    #expect(tip == nil)
}

@Test
func test_make_when_onlyOtherChineseScriptIsSupported_then_preservesScriptLimitation() {
    // Arrange & Act
    let tip = ScreenshotLanguageTip.make(
        localization: AppLocalization(languageIdentifier: "en"),
        sourceLanguageIdentifier: "zh-Hant", recognitionLanguages: ["zh-Hans"])
    // Assert
    #expect(tip != nil)
}

@Test
func test_make_when_capabilityQueryFails_then_doesNotClaimLanguageIsUnsupported() {
    // Arrange & Act
    let tip = ScreenshotLanguageTip.make(
        localization: AppLocalization(languageIdentifier: "en"),
        sourceLanguageIdentifier: "hi", recognitionLanguages: nil)
    // Assert
    #expect(tip == nil)
}
