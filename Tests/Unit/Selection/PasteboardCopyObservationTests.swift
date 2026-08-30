import Testing
@testable import BoundlessTranslator

@Test
func test_copiedText_when_change_count_and_string_are_available_then_returns_text() {
    // Arrange
    let observation = PasteboardCopyObservation(initialChangeCount: 12)

    // Act
    let copiedText = observation.copiedText(
        currentChangeCount: 13,
        string: "selected text"
    )

    // Assert
    #expect(copiedText == "selected text")
}

@Test
func test_copiedText_when_change_count_is_unchanged_then_returns_nil() {
    // Arrange
    let observation = PasteboardCopyObservation(initialChangeCount: 12)

    // Act
    let copiedText = observation.copiedText(
        currentChangeCount: 12,
        string: "stale text"
    )

    // Assert
    #expect(copiedText == nil)
}
