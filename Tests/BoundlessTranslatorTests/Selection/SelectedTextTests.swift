import Testing
@testable import BoundlessTranslator

@Test
func test_init_when_text_has_content_then_preserves_text() throws {
    // Arrange
    let source = "  Hello world  "

    // Act
    let selectedText = try SelectedText(source)

    // Assert
    #expect(selectedText.value == source)
}

@Test
func test_init_when_text_is_whitespace_then_throws_empty() {
    // Arrange
    let source = " \n\t "

    // Act & Assert
    #expect(throws: SelectedTextError.empty) {
        try SelectedText(source)
    }
}
