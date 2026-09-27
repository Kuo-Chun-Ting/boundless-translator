import Foundation
import Testing
@testable import BoundlessTranslator

@Test
func test_split_when_paragraphsFitTarget_then_packsWholeParagraphsWithoutLosingWhitespace() throws {
    // Arrange
    let splitter = TranslationTextSplitter(targetCharacters: 14)
    let text = "One.\n\nTwo.\n\nThree."
    // Act
    let chunks = try splitter.split(text, languageIdentifier: "en")
    // Assert
    #expect(chunks == ["One.\n\nTwo.\n\n", "Three."])
    #expect(chunks.joined() == text)
}

@Test
func test_split_when_paragraphExceedsTarget_then_usesSentenceBoundaries() throws {
    // Arrange
    let splitter = TranslationTextSplitter(targetCharacters: 15)
    let text = "Hello world. Another sentence. Last one."
    // Act
    let chunks = try splitter.split(text, languageIdentifier: "en")
    // Assert
    #expect(chunks == ["Hello world. ", "Another sentence. ", "Last one."])
    #expect(chunks.joined() == text)
}

@Test
func test_split_when_singleSentenceExceedsTarget_then_preservesEntireSentence() throws {
    // Arrange
    let text = "This sentence has more characters than the target."
    let splitter = TranslationTextSplitter(targetCharacters: 10)
    // Act
    let chunks = try splitter.split(text, languageIdentifier: "en")
    // Assert
    #expect(chunks == [text])
}

@Test
func test_split_when_chineseAndUnicodeWhitespace_then_preservesEveryCharacter() throws {
    // Arrange
    let text = "  這是第一句。這是第二句！\r\n\r\n最後一句👨‍👩‍👧‍👦。\n"
    let splitter = TranslationTextSplitter(targetCharacters: 10)
    // Act
    let chunks = try splitter.split(text, languageIdentifier: "zh-Hant")
    // Assert
    #expect(chunks.count > 1)
    #expect(chunks.joined() == text)
    #expect(chunks.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
}

@Test
func test_split_when_emptyText_then_returnsNoChunks() throws {
    // Arrange
    let splitter = TranslationTextSplitter()
    // Act
    let chunks = try splitter.split("", languageIdentifier: "en")
    // Assert
    #expect(chunks.isEmpty)
}

@Test
func test_split_when_fullLargeFixture_then_preservesSourceAndProducesBoundedChunks() throws {
    // Arrange
    let fixture = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Fixtures/Translation/100K_words.txt")
    let text = try String(contentsOf: fixture, encoding: .utf8)
    let splitter = TranslationTextSplitter()
    // Act
    let chunks = try splitter.split(text, languageIdentifier: "en")
    // Assert
    #expect(chunks.count > 1)
    #expect(chunks.joined() == text)
    #expect(chunks.allSatisfy { $0.count <= 10_000 })
}
