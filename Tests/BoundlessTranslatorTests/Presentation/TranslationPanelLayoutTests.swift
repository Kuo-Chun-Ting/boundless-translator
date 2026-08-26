import Foundation
import Testing
@testable import BoundlessTranslator

@Test
func test_metrics_when_translation_is_short_then_uses_compact_size() {
    // Arrange
    let layout = TranslationPanelLayout()
    let status = TranslationStatus.translated(
        TranslationOutput(
            translatedText: "火車",
            sourceLanguageIdentifier: "en",
            targetLanguageIdentifier: "zh-Hant"
        )
    )

    // Act
    let metrics = layout.metrics(sourceText: "train", status: status)

    // Assert
    #expect(metrics.size == CGSize(width: 560, height: 180))
}

@Test
func test_metrics_when_translation_is_long_then_grows_vertically() {
    // Arrange
    let layout = TranslationPanelLayout()
    let shortStatus = TranslationStatus.translated(
        TranslationOutput(
            translatedText: "短句。",
            sourceLanguageIdentifier: "en",
            targetLanguageIdentifier: "zh-Hant"
        )
    )
    let longStatus = TranslationStatus.translated(
        TranslationOutput(
            translatedText: String(repeating: "這是一段需要更多垂直空間的翻譯內容。", count: 12),
            sourceLanguageIdentifier: "en",
            targetLanguageIdentifier: "zh-Hant"
        )
    )

    // Act
    let shortMetrics = layout.metrics(sourceText: "Short sentence.", status: shortStatus)
    let longMetrics = layout.metrics(
        sourceText: String(repeating: "A sentence with context. ", count: 5),
        status: longStatus
    )

    // Assert
    #expect(longMetrics.size.width == shortMetrics.size.width)
    #expect(longMetrics.size.height > shortMetrics.size.height)
}

@Test
func test_metrics_when_both_columns_are_long_then_uses_tallest_column_height() {
    // Arrange
    let layout = TranslationPanelLayout(maximumHeight: 1_000)
    let longText = String(repeating: "A sentence with enough text to wrap. ", count: 12)
    let shortStatus = TranslationStatus.translated(
        TranslationOutput(
            translatedText: "Short.",
            sourceLanguageIdentifier: "en",
            targetLanguageIdentifier: "zh-Hant"
        )
    )
    let longStatus = TranslationStatus.translated(
        TranslationOutput(
            translatedText: longText,
            sourceLanguageIdentifier: "en",
            targetLanguageIdentifier: "zh-Hant"
        )
    )

    // Act
    let sourceOnlyMetrics = layout.metrics(
        sourceText: longText,
        status: shortStatus
    )
    let bothColumnsMetrics = layout.metrics(
        sourceText: longText,
        status: longStatus
    )

    // Assert
    #expect(bothColumnsMetrics.size.height == sourceOnlyMetrics.size.height)
}

@Test
func test_metrics_when_translation_exceeds_available_space_then_caps_height() {
    // Arrange
    let layout = TranslationPanelLayout()
    let status = TranslationStatus.translated(
        TranslationOutput(
            translatedText: String(repeating: "很長的翻譯內容。", count: 300),
            sourceLanguageIdentifier: "en",
            targetLanguageIdentifier: "zh-Hant"
        )
    )

    // Act
    let metrics = layout.metrics(
        sourceText: String(repeating: "Very long source text. ", count: 100),
        status: status
    )

    // Assert
    #expect(metrics.size.height == 440)
    #expect(metrics.contentHeight < metrics.idealContentHeight)
}

@Test
func test_sourceDescription_when_languageWasDetected_then_marksDetectedLanguage() {
    // Arrange
    let formatter = TranslationLanguagePairFormatter(
        locale: Locale(identifier: "en_US")
    )

    // Act
    let description = formatter.sourceDescription(
        languageIdentifier: "en",
        wasDetected: true
    )

    // Assert
    #expect(description == "English (Detected)")
}

@Test
func test_sourceDescription_when_languageWasExplicit_then_usesLanguageNameOnly() {
    // Arrange
    let formatter = TranslationLanguagePairFormatter(
        locale: Locale(identifier: "en_US")
    )

    // Act
    let description = formatter.sourceDescription(
        languageIdentifier: "en",
        wasDetected: false
    )

    // Assert
    #expect(description == "English")
}
