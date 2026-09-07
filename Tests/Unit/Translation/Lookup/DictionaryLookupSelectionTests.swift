import Foundation
import Testing
@testable import BoundlessTranslator

@Test
func test_make_when_range_contains_text_then_returns_exact_selection() throws {
    // Arrange
    let text = "She tried to hold back her emotions."
    let range = try #require(text.range(of: "hold back"))
    let nsRange = NSRange(range, in: text)

    // Act
    let selection = DictionaryLookupSelection.make(
        text: text,
        selectedRange: nsRange
    )

    // Assert
    #expect(selection?.text == "hold back")
    #expect(selection?.range == nsRange)
}

@Test
func test_make_when_range_has_outer_whitespace_then_trims_text_and_range() throws {
    // Arrange
    let text = "She felt  strong emotions  today."
    let range = try #require(text.range(of: " strong emotions "))

    // Act
    let selection = DictionaryLookupSelection.make(
        text: text,
        selectedRange: NSRange(range, in: text)
    )

    // Assert
    let expectedRange = try #require(text.range(of: "strong emotions"))
    #expect(selection?.text == "strong emotions")
    #expect(selection?.range == NSRange(expectedRange, in: text))
}

@Test
func test_make_when_range_is_empty_then_returns_nil() {
    // Arrange
    let text = "emotion"

    // Act
    let selection = DictionaryLookupSelection.make(
        text: text,
        selectedRange: NSRange(location: 3, length: 0)
    )

    // Assert
    #expect(selection == nil)
}

@Test
func test_make_when_range_contains_only_whitespace_then_returns_nil() {
    // Arrange
    let text = "word   meaning"

    // Act
    let selection = DictionaryLookupSelection.make(
        text: text,
        selectedRange: NSRange(location: 4, length: 3)
    )

    // Assert
    #expect(selection == nil)
}

@Test
func test_make_when_range_is_outOfBounds_then_returns_nil() {
    // Arrange
    let text = "emotion"

    // Act
    let selection = DictionaryLookupSelection.make(
        text: text,
        selectedRange: NSRange(location: 50, length: 4)
    )

    // Assert
    #expect(selection == nil)
}
